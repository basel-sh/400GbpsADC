function [Y1, Y2, diag] = link_forward_pass(X1, X2, cfg, opts)
%LINK_FORWARD_PASS  Core reusable TX->channel->RX engine shared by every
%experiment and by the channel-estimation pilot phase, so the exact same
%signal chain (deemphasis -> OFDM mod -> DAC -> 2x2 channel -> noise -> ADC
%-> OFDM demod) is used everywhere -- CHEST pilots and data symbols see an
%IDENTICAL physical link, exactly as they would in real hardware.
%
% "Identical" includes the analog gains: the DAC output gain and the RX VGA
% gain must be the SAME numbers for the two pilot symbols and for the data
% (a real AGC loop is much slower than a pilot sequence). Pass the frozen
% gains through opts.agc; call once with opts.agc = [] to measure them.
%
% Inputs:
%   X1, X2 - N_used x N_symbols complex frequency-domain symbols for lane 1
%            and lane 2 (pilots or data)
%   cfg    - config struct
%   opts   - struct, all fields optional:
%       .enable_fext        (default true)  - couple the two lanes via the
%                            FEXT channel
%       .apply_impairments  (default true)  - DAC/ADC clipping+quant+jitter
%                            and RX noise; false = ideal analog link
%                            (still passes through the linear channel)
%       .enable_channel     (default true)  - if false, bypass the physical
%                            channel entirely (pure AWGN test over an
%                            identity channel, used for TEST 1)
%       .snr_override_dB    ([]) - if set, RX noise RMS is computed to hit
%                            this SNR (dB) at the channel output instead of
%                            using cfg.noise.rx_input_rms_V (used for
%                            BER/SER-vs-SNR sweeps). Noise is then added at
%                            the RX input.
%       .seed_offset        (default 0) - integer seed offset for
%                            reproducible-but-distinct noise/jitter draws
%       .agc                ([]) - frozen converter gains: struct with
%                            .dac_scale [1x2] and .adc_gain [1x2]. [] = each
%                            block sets its own gain (calibration mode).
%       .noise              ([]) - frozen noise: struct with .rms_V and
%                            .at ('rx' = RX input / before the VGA,
%                            'adc' = ADC input / after the VGA). [] = derive
%                            from cfg.noise / snr_override_dB.
%
% Outputs:
%   Y1, Y2 - N_used x N_symbols received (un-equalized), post-ADC,
%            frequency-domain symbols
%   diag   - struct with diagnostic info (clipping fractions, the gains
%            actually used: diag.agc, the noise actually used: diag.noise)

if nargin < 4, opts = struct(); end
opts = set_default(opts, 'enable_fext', true);
opts = set_default(opts, 'apply_impairments', true);
opts = set_default(opts, 'enable_channel', true);
opts = set_default(opts, 'snr_override_dB', []);
opts = set_default(opts, 'seed_offset', 0);
opts = set_default(opts, 'agc', []);
opts = set_default(opts, 'noise', []);

dac_scale = [NaN NaN];
adc_gain  = [NaN NaN];
if ~isempty(opts.agc)
    dac_scale = opts.agc.dac_scale;
    adc_gain  = opts.agc.adc_gain;
end
% Distinct, non-overlapping jitter seeds per call, per lane and per stage
% (DAC 1e5 + ..., ADC 2e5 + ...). Noise seeds (below) stay < 1e5.
jit = 1009 * opts.seed_offset;

Xd1 = tx_deemphasis(X1, cfg);
Xd2 = tx_deemphasis(X2, cfg);

t1 = ofdm_modulate(Xd1, cfg); % (NFFT+NCP) x Nsym
t2 = ofdm_modulate(Xd2, cfg);

x1_ser = t1(:);
x2_ser = t2(:);

diag = struct();

if opts.apply_impairments
    [d1, dac_meta1] = dac_model(x1_ser, cfg, true, dac_scale(1), 100000 + jit + 1);
    [d2, dac_meta2] = dac_model(x2_ser, cfg, true, dac_scale(2), 100000 + jit + 2);
    diag.dac_frac_clipped = [dac_meta1.frac_clipped, dac_meta2.frac_clipped];
    diag.agc.dac_scale = [dac_meta1.scale, dac_meta2.scale];
else
    d1 = x1_ser;
    d2 = x2_ser;
end

if opts.enable_channel
    [h_main, main_info] = main_channel(cfg);
    [h_fext, ~] = fext_channel(cfg, main_info);
    [r1, r2] = mimo_channel(d1, d2, h_main, h_fext, opts.enable_fext);
    r1 = r1(1:numel(d1));
    r2 = r2(1:numel(d2));
else
    r1 = d1;
    r2 = d2;
end

if opts.apply_impairments
    % --- where does the 1.8 mV noise act, and how large is it? ---
    if ~isempty(opts.noise)
        noise_rms = opts.noise.rms_V;
        noise_at  = opts.noise.at;
    else
        noise_rms = cfg.noise.rx_input_rms_V;
        noise_at  = 'rx';
        if isfield(cfg.noise, 'reference') && strcmp(cfg.noise.reference, 'adc_input')
            noise_at = 'adc';
        end
        if ~isempty(opts.snr_override_dB)
            sig_pow = mean(r1.^2) + eps;
            noise_rms = sqrt(sig_pow / 10^(opts.snr_override_dB/10));
            noise_at  = 'rx';   % an SNR target is defined at the channel output
        end
    end
    diag.noise = struct('rms_V', noise_rms, 'at', noise_at);
    diag.noise_rms_V = noise_rms;

    post1 = 0; post2 = 0;
    if strcmp(noise_at, 'rx')
        r1 = add_noise(r1, noise_rms, opts.seed_offset*2 + 1);
        r2 = add_noise(r2, noise_rms, opts.seed_offset*2 + 2);
    else
        post1 = noise_rms; post2 = noise_rms;
    end

    [a1, adc_meta1] = adc_model(r1, cfg, true, adc_gain(1), 200000 + jit + 1, post1, opts.seed_offset*2 + 1);
    [a2, adc_meta2] = adc_model(r2, cfg, true, adc_gain(2), 200000 + jit + 2, post2, opts.seed_offset*2 + 2);
    diag.adc_frac_clipped = [adc_meta1.frac_clipped, adc_meta2.frac_clipped];
    diag.agc.adc_gain = [adc_meta1.vga_gain, adc_meta2.vga_gain];
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

function s = set_default(s, field, val)
if ~isfield(s, field) || isempty(s.(field))
    if isfield(s, field) && isempty(val)
        return; % explicit [] stays []
    end
    s.(field) = val;
end
end
