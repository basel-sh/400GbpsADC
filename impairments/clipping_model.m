function [x_clipped, meta] = clipping_model(x, beta)
%CLIPPING_MODEL  Hard-clip a real signal to +/- beta (saturation).
%
% Implements the saturation nonlinearity described in [FEXT] p.83 Sec. II-A
% ("Clipping can be applied at this stage to trade off distortion and SNR")
% and [DSE] p.143 Sec. V, where beta is the saturation threshold in
% absolute value (same units as x, e.g. Volts).
%
% Inputs:
%   x    - real signal (any shape)
%   beta - clipping threshold (positive scalar, same units as x)
%
% Outputs:
%   x_clipped - x hard-limited to [-beta, beta]
%   meta      - struct: num_clipped, frac_clipped

num_clipped = sum(abs(x(:)) > beta);
x_clipped = min(max(x, -beta), beta);

meta = struct('num_clipped', num_clipped, 'frac_clipped', num_clipped/numel(x));

end
