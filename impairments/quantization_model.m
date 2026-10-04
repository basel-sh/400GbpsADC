function [x_q, meta] = quantization_model(x, bits, full_scale)
%QUANTIZATION_MODEL  Uniform MID-RISE quantizer.
%
%   x_q = QUANTIZATION_MODEL(x, bits, full_scale) quantizes x (assumed
%   already clipped to +/- full_scale) into 2^bits uniform levels spanning
%   [-full_scale, full_scale], modeling the DAC/ADC's finite resolution
%   (cfg.dac.bits / cfg.adc.bits, [A] 7-bit for the 224G baseline).
%
%   Mid-rise: decision thresholds sit at integer multiples of the LSB and
%   the reconstruction levels at (k + 1/2)*LSB, so the output set is
%   symmetric (+-0.5, +-1.5, ... LSB) and has NO zero level. (Earlier
%   versions used round(x/lsb), which is a mid-TREAD quantizer, in
%   contradiction with this header.)
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
codes = floor(x / lsb);                 % -levels/2 ... levels/2-1
max_code = levels/2 - 1;
min_code = -levels/2;
codes = min(max(codes, min_code), max_code);
x_q = (codes + 0.5) * lsb;

meta = struct('lsb', lsb);

end
