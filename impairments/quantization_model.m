function [x_q, meta] = quantization_model(x, bits, full_scale)
%QUANTIZATION_MODEL  Uniform signed-code quantizer with a zero output level.
%
%   x_q = QUANTIZATION_MODEL(x, bits, full_scale) quantizes x (assumed
%   already clipped to +/- full_scale) into 2^bits uniform levels spanning
%   [-full_scale, full_scale], modeling the DAC/ADC's finite resolution
%   (cfg.dac.bits / cfg.adc.bits, [A] 7-bit for the 224G baseline).
%
% Inputs:
%   x          - real signal, already within [-full_scale, full_scale]
%   bits       - resolution in bits (effective number of bits, ENOB, for
%                sweep studies)
%   full_scale - one-sided full-scale amplitude (same units as x)
%
% Outputs:
%   x_q  - quantized signal
%   meta - struct: lsb (quantization step size)

levels = 2^bits;
lsb = (2*full_scale) / levels;
codes = round(x / lsb);
max_code = levels/2 - 1;
min_code = -levels/2;
codes = min(max(codes, min_code), max_code);
x_q = codes * lsb;

meta = struct('lsb', lsb);

end
