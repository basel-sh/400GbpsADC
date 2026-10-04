function [dac_out, meta] = dac_model(tx_time, cfg, apply_jitter, fixed_scale, jitter_seed)
%DAC_MODEL  Behavioral DAC: gain to the paper's clipping ratio, hard
%clipping, sampling jitter, and quantization to cfg.dac.bits.
%
% Reuses impairments/clipping_model.m, impairments/quantization_model.m and
% impairments/jitter_model.m so each impairment stays independently testable.
%
% Inputs:
%   tx_time      - (N_FFT+N_CP) x N_symbols (or serialized) real time-domain
%                  OFDM samples (call AFTER tx_deemphasis)
%   cfg          - config struct
%   apply_jitter - logical, default true (set false for ideal-channel tests)
%   fixed_scale  - [] or NaN (default): CALIBRATION mode, the gain is set so
%                  that THIS block has RMS = beta/R_clip.
%                  number: FROZEN mode, this gain is used as-is. A real
%                  transmitter has a fixed output gain; recomputing it for
%                  every block (as earlier versions did) makes the pilot
%                  and the data symbols see different gains and corrupts
%                  the sum/difference channel estimator (see docs/fix_log.md).
%   jitter_seed  - seed offset of the jitter draw (default 1000)
%
% Outputs:
%   dac_out - physical analog output in Volts (clipped, jittered, quantized)
%   meta    - struct: rms_in, scale, clip_threshold_V, lsb_V, num_clipped,
%             frac_clipped

if nargin < 3 || isempty(apply_jitter), apply_jitter = true; end
if nargin < 4, fixed_scale = []; end
if nargin < 5 || isempty(jitter_seed), jitter_seed = 1000; end

dacp = cfg.dac;
bits = dacp.bits;
vfs_pp = dacp.vfs_diff_pp;
clip_ratio_lin = clip_ratio_to_rms(dacp.clip_ratio_dB, cfg); % beta / A_RMS

rms_in = sqrt(mean(tx_time(:).^2));
if rms_in == 0, rms_in = eps; end
beta = vfs_pp/2;
if isempty(fixed_scale) || isnan(fixed_scale)
    scale = (beta / clip_ratio_lin) / rms_in;   % calibration mode
else
    scale = fixed_scale;                        % frozen mode
end
x = tx_time * scale;

[x, clip_meta] = clipping_model(x, beta);

if apply_jitter && cfg.jitter.rms_UI > 0
    x = jitter_model(x, cfg.fs, cfg.jitter.rms_UI, jitter_seed);
end

[dac_out, q_meta] = quantization_model(x, bits, beta);

meta = struct();
meta.rms_in = rms_in;
meta.scale = scale;
meta.clip_threshold_V = beta;
meta.lsb_V = q_meta.lsb;
meta.num_clipped = clip_meta.num_clipped;
meta.frac_clipped = clip_meta.frac_clipped;

end
