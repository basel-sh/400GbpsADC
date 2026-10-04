function [adc_out, meta] = adc_model(rx_time, cfg, apply_jitter)
%ADC_MODEL  Behavioral RX front-end + ADC: VGA gain (so the ADC uses its
%full input range, per [FEXT] p.84 Sec. V: "CTLE is not considered and the
%RX VGA amplifies the input signal so that the ADC uses its input
%full-scale"), clipping at the paper's RX clipping ratio, sampling jitter,
%and quantization to cfg.adc.bits.
%
% Inputs:
%   rx_time      - N x 1 real time-domain signal at the RX input (after
%                  channel + add_noise), Volts
%   cfg          - config struct
%   apply_jitter - logical, default true
%
% Outputs:
%   adc_out - quantized RX samples, Volts (same scale convention as the ADC
%             full-scale, i.e. directly comparable across configs)
%   meta    - struct: rms_in, clip_threshold_V, lsb_V, num_clipped, frac_clipped, vga_gain

if nargin < 3
    apply_jitter = true;
end

adcp = cfg.adc;
bits = adcp.bits;
vfs_pp = adcp.vfs_diff_pp;
clip_ratio_lin = 10^(adcp.clip_ratio_dB/20);

rms_in = sqrt(mean(rx_time(:).^2));
if rms_in == 0, rms_in = eps; end

beta = vfs_pp/2;
if cfg.vga_normalizes_to_adc_fullscale
    target_rms = beta / clip_ratio_lin;
  %variable gain edited fext cancel 
    if isfield(adcp, 'vga_gain_fixed') && ~isempty(adcp.vga_gain_fixed)
        vga_gain = adcp.vga_gain_fixed;
    else
        vga_gain = target_rms / rms_in;
    end
else
    vga_gain = 1;
end
x = rx_time * vga_gain;

[x, clip_meta] = clipping_model(x, beta);

if apply_jitter && cfg.jitter.rms_UI > 0
    x = jitter_model(x, cfg.fs, cfg.jitter.rms_UI, 2000);
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
