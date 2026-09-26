function [dac_out, meta] = dac_model(tx_time, cfg, apply_jitter)
%DAC_MODEL  Behavioral DAC: RMS normalization to the paper's clipping ratio,
%hard clipping, sampling jitter, and quantization to cfg.dac.bits.
%
% Reuses impairments/clipping_model.m, impairments/quantization_model.m and
% impairments/jitter_model.m so each impairment stays independently testable
% (Part 11: modular functions, no scattered hard-coded parameters).
%
% Inputs:
%   tx_time      - (N_FFT+N_CP) x N_symbols real time-domain OFDM samples
%                  (call AFTER tx_deemphasis has been applied in freq domain)
%   cfg          - config struct
%   apply_jitter - logical, default true (set false for ideal-channel tests)
%
% Outputs:
%   dac_out - physical analog output in Volts (clipped, jittered, quantized)
%   meta    - struct: rms_in, clip_threshold_V, lsb_V, num_clipped, frac_clipped

if nargin < 3
    apply_jitter = true;
end

dacp = cfg.dac;
bits = dacp.bits;
vfs_pp = dacp.vfs_diff_pp;
clip_ratio_lin = 10^(dacp.clip_ratio_dB/20); % [DSE] R_clip = beta/A_RMS

rms_in = sqrt(mean(tx_time(:).^2));
if rms_in == 0, rms_in = eps; end
beta = vfs_pp/2;
target_rms = beta / clip_ratio_lin;
scale = target_rms / rms_in;
x = tx_time * scale;

[x, clip_meta] = clipping_model(x, beta);

if apply_jitter && cfg.jitter.rms_UI > 0
    x = jitter_model(x, cfg.fs, cfg.jitter.rms_UI, 1000);
end

[dac_out, q_meta] = quantization_model(x, bits, beta);

meta = struct();
meta.rms_in = rms_in;
meta.clip_threshold_V = beta;
meta.lsb_V = q_meta.lsb;
meta.num_clipped = clip_meta.num_clipped;
meta.frac_clipped = clip_meta.frac_clipped;

end
