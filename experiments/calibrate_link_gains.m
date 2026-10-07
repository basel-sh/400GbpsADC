function cfg = calibrate_link_gains(cfg, opts)
% One ensemble-based calibration; no per-pilot/data automatic renormalization.
% Assumes independent unit-energy QAM, symmetric channels and stationary noise.
g = deemphasis_gain_vector(cfg);
vrms = sqrt(2*sum(abs(g).^2)/cfg.ofdm.N_FFT);
if ~isfield(cfg.dac,'scale_fixed') || isempty(cfg.dac.scale_fixed)
    cfg.dac.scale_fixed = cfg.dac.vfs_diff_pp/2 / ...
        effective_clip_ratio(cfg.dac) / vrms;
end
if opts.enable_channel
    [hm, mi] = main_channel(cfg); [hf, ~] = fext_channel(cfg,mi);
    % Evaluate FIR responses exactly at the OFDM frequencies, without truncating.
    w = exp(-2j*pi*cfg.ofdm.k_idx*(0:numel(hm)-1)/cfg.ofdm.N_FFT);
    Hm = w*hm; Hf = w*hf;
else
    Hm = ones(size(g)); Hf = zeros(size(g));
end
if ~opts.enable_fext, Hf(:)=0; end
p = cfg.dac.scale_fixed^2*2/cfg.ofdm.N_FFT * ...
    sum(abs(g).^2.*(abs(Hm).^2+abs(Hf).^2));
noise = cfg.noise.rx_input_rms_V;
if isfield(opts,'snr_override_dB') && ~isempty(opts.snr_override_dB)
    noise = sqrt(p/10^(opts.snr_override_dB/10));
end
if (~isfield(cfg.adc,'vga_gain_fixed') || isempty(cfg.adc.vga_gain_fixed)) ...
        && cfg.vga_normalizes_to_adc_fullscale
    target=cfg.adc.vfs_diff_pp/2/effective_clip_ratio(cfg.adc);
    if isfield(cfg.noise,'reference') && strcmp(cfg.noise.reference,'adc_input')
        cfg.adc.vga_gain_fixed=sqrt(max(target^2-noise^2,eps)/p);
    else
        cfg.adc.vga_gain_fixed = target / sqrt(p+noise^2);
    end
end
end
