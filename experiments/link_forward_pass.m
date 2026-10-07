function [Y1, Y2, diag] = link_forward_pass(X1, X2, cfg, opts)
%LINK_FORWARD_PASS  Core reusable TX->channel->RX engine shared by every
%experiment and by the channel-estimation pilot phase, so the exact same
%signal chain (deemphasis -> OFDM mod -> DAC -> 2x2 channel -> noise -> ADC
%-> OFDM demod) is used everywhere -- CHEST pilots and data symbols see an
%IDENTICAL physical link, exactly as they would in real hardware.
%
% Inputs:
%   X1, X2 - N_used x N_symbols complex frequency-domain symbols for lane 1
%            and lane 2 (pilots or data)
%   cfg    - config struct
%   opts   - struct, all fields optional:
%       .enable_fext        (default true)  - couple the two lanes via the
%                            FEXT channel
%       .enable_fext_channel_only_not_used  (reserved, unused placeholder)
%       .apply_impairments  (default true)  - DAC/ADC clipping+quant+jitter
%                            and RX input noise; false = ideal analog link
%                            (still passes through the linear channel)
%       .enable_channel     (default true)  - if false, bypass the physical
%                            channel entirely (pure AWGN test over an
%                            identity channel, used for TEST 1)
%       .snr_override_dB    ([]) - if set, RX noise RMS is computed to hit
%                            this SNR (dB) at the channel output instead of
%                            using cfg.noise.rx_input_rms_V (used for
%                            BER/SER-vs-SNR sweeps)
%       .seed_offset        (default 0) - integer seed offset for
%                            reproducible-but-distinct noise/jitter draws
%
% Outputs:
%   Y1, Y2 - N_used x N_symbols received (un-equalized), post-ADC,
%            frequency-domain symbols
%   diag   - struct with diagnostic info (clipping fractions, achieved SNR)

if nargin < 4, opts = struct(); end
opts = set_default(opts, 'enable_fext', true);
opts = set_default(opts, 'apply_impairments', true);
opts = set_default(opts, 'enable_channel', true);
opts = set_default(opts, 'snr_override_dB', []);
opts = set_default(opts, 'seed_offset', 0);

Xd1 = tx_deemphasis(X1, cfg);
Xd2 = tx_deemphasis(X2, cfg);

t1 = ofdm_modulate(Xd1, cfg); % (NFFT+NCP) x Nsym
t2 = ofdm_modulate(Xd2, cfg);

x1_ser = t1(:);
x2_ser = t2(:);

diag = struct();

if opts.apply_impairments
    [d1, dac_meta1] = dac_model(x1_ser, cfg, true,100000+opts.seed_offset*4+1);
    [d2, dac_meta2] = dac_model(x2_ser, cfg, true,100000+opts.seed_offset*4+2);
    diag.dac_frac_clipped = [dac_meta1.frac_clipped, dac_meta2.frac_clipped];
else
    d1 = x1_ser;
    d2 = x2_ser;
end

if opts.enable_channel
    [h_main, main_info] = main_channel(cfg);
    [h_fext, ~] = fext_channel(cfg, main_info);
    if isfield(cfg.channel,'ofdm_diagonal') && cfg.channel.ofdm_diagonal
        % Idealized per-subcarrier channel used to compare directly with
        % the paper's Y(k)=H(k)X(k) model. This assumes CP fully removes
        % inter-block interference; it is not the physical-convolution path.
        [r1,r2] = mimo_ofdm_diagonal(d1,d2,h_main,h_fext,cfg,opts.enable_fext);
    else
        [r1, r2] = mimo_channel(d1, d2, h_main, h_fext, opts.enable_fext);
        r1 = r1(1:numel(d1));
        r2 = r2(1:numel(d2));
    end
else
    r1 = d1;
    r2 = d2;
end

if opts.apply_impairments
    noise_rms = cfg.noise.rx_input_rms_V;
    if ~isempty(opts.snr_override_dB)
        sig_pow = mean(r1.^2) + eps;
        noise_rms = sqrt(sig_pow / 10^(opts.snr_override_dB/10));
    end
    % Where is the 1.8 mV noise injected?  cfg.noise.reference:
    %   'before_vga' (default) - at the RX input, then amplified by the VGA
    %   'adc_input'            - same RMS but added after the VGA (ADC input)
    noise_at_adc = isfield(cfg.noise, 'reference') && ...
                   strcmp(cfg.noise.reference, 'adc_input') && isempty(opts.snr_override_dB);
    cfg1 = cfg; cfg2 = cfg;
    if noise_at_adc
        cfg1.adc.input_noise_rms_V = noise_rms;  cfg1.adc.input_noise_seed = opts.seed_offset*2 + 1;
        cfg2.adc.input_noise_rms_V = noise_rms;  cfg2.adc.input_noise_seed = opts.seed_offset*2 + 2;
    else
        r1 = add_noise(r1, noise_rms, opts.seed_offset*2 + 1);
        r2 = add_noise(r2, noise_rms, opts.seed_offset*2 + 2);
    end
    diag.noise_rms_V = noise_rms;

    [a1, adc_meta1] = adc_model(r1, cfg1, true,200000+opts.seed_offset*4+1);
    [a2, adc_meta2] = adc_model(r2, cfg2, true,200000+opts.seed_offset*4+2);
    diag.adc_frac_clipped = [adc_meta1.frac_clipped, adc_meta2.frac_clipped];
    diag.dac_scale = [dac_meta1.scale,dac_meta2.scale];
    diag.vga_gain = [adc_meta1.vga_gain,adc_meta2.vga_gain];
else
    a1 = r1;
    a2 = r2;
end

blk_len = cfg.ofdm.N_FFT + cfg.ofdm.N_CP;
Nsym = numel(a1) / blk_len;
b1 = reshape(a1, blk_len, Nsym);
b2 = reshape(a2, blk_len, Nsym);

Y1 = ofdm_demodulate(b1, cfg);
Y2 = ofdm_demodulate(b2, cfg);

end

function [r1,r2] = mimo_ofdm_diagonal(x1,x2,hm,hf,cfg,enable_fext)
% Apply the channel on each OFDM tone, without inter-block convolution.
N=cfg.ofdm.N_FFT; C=cfg.ofdm.N_CP; B=N+C;
if mod(numel(x1),B) || mod(numel(x2),B)
    error('link_forward_pass:ofdmBlockSize','Waveform length is not an integer number of OFDM blocks');
end
H=fft(hm,N); F=fft(hf,N);
if ~enable_fext, F(:)=0; end
a=reshape(x1,B,[]); b=reshape(x2,B,[]);
u=fft(a(C+1:end,:),N,1); v=fft(b(C+1:end,:),N,1);
y1=real(ifft(H.*u+F.*v,N,1));
y2=real(ifft(F.*u+H.*v,N,1));
r1=reshape([y1(end-C+1:end,:);y1],[],1);
r2=reshape([y2(end-C+1:end,:);y2],[],1);
end

function s = set_default(s, field, val)
if ~isfield(s, field) || isempty(s.(field))
    if isfield(s, field) && isempty(val)
        return; % explicit [] stays []
    end
    s.(field) = val;
end
end
