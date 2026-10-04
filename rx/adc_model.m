function [adc_out, meta] = adc_model(rx_time, cfg, apply_jitter, fixed_gain, jitter_seed, post_noise_rms, post_noise_seed)
%ADC_MODEL  Behavioral RX front-end + ADC: VGA gain (so the ADC uses its
%full input range, per [FEXT] p.84 Sec. V: "CTLE is not considered and the
%RX VGA amplifies the input signal so that the ADC uses its input
%full-scale"), optional noise referred to the ADC input, clipping at the
%paper's RX clipping ratio, sampling jitter, and quantization.
%
% Inputs:
%   rx_time        - N x 1 real signal at the RX input (after channel and,
%                    for noise reference 'rx_input', after add_noise), Volts
%   cfg            - config struct
%   apply_jitter   - logical, default true
%   fixed_gain     - [] or NaN (default): CALIBRATION mode, the VGA gain makes
%                    THIS block's RMS equal beta/R_clip.
%                    number: FROZEN VGA gain (what a slow AGC loop does; the
%                    gain must be identical for the pilot symbols and the
%                    data symbols, otherwise the CHEST sum/difference
%                    estimator is biased -- see docs/fix_log.md).
%   jitter_seed    - seed offset of the jitter draw (default 2000)
%   post_noise_rms - RMS (V) of white noise added AFTER the VGA (i.e. at the
%                    ADC input); default 0 (none)
%   post_noise_seed- seed of that noise
%
% Outputs:
%   adc_out - quantized RX samples, Volts
%   meta    - struct: rms_in, vga_gain, clip_threshold_V, lsb_V, num_clipped,
%             frac_clipped

if nargin < 3 || isempty(apply_jitter), apply_jitter = true; end
if nargin < 4, fixed_gain = []; end
if nargin < 5 || isempty(jitter_seed), jitter_seed = 2000; end
if nargin < 6 || isempty(post_noise_rms), post_noise_rms = 0; end
if nargin < 7 || isempty(post_noise_seed), post_noise_seed = 0; end

adcp = cfg.adc;
bits = adcp.bits;
vfs_pp = adcp.vfs_diff_pp;
clip_ratio_lin = clip_ratio_to_rms(adcp.clip_ratio_dB, cfg); % beta / A_RMS

rms_in = sqrt(mean(rx_time(:).^2));
if rms_in == 0, rms_in = eps; end

beta = vfs_pp/2;
if ~isempty(fixed_gain) && ~isnan(fixed_gain)
    vga_gain = fixed_gain;                                  % frozen mode
elseif cfg.vga_normalizes_to_adc_fullscale
    vga_gain = (beta / clip_ratio_lin) / rms_in;            % calibration mode
else
    vga_gain = 1;
end
x = rx_time * vga_gain;

if post_noise_rms > 0
    x = add_noise(x, post_noise_rms, post_noise_seed);
end

[x, clip_meta] = clipping_model(x, beta);

if apply_jitter && cfg.jitter.rms_UI > 0
    x = jitter_model(x, cfg.fs, cfg.jitter.rms_UI, jitter_seed);
end

[adc_out, q_meta] = quantization_model(x, bits, beta);

meta = struct();
meta.rms_in = rms_in;
meta.vga_gain = vga_gain;
meta.clip_threshold_V = beta;
meta.lsb_V = q_meta.lsb;
meta.num_clipped = clip_meta.num_clipped;
meta.frac_clipped = clip_meta.frac_clipped;

end
