function y = add_noise(x, rms_V, seed_offset)
%ADD_NOISE  Add i.i.d. Gaussian random noise with a specified RMS amplitude,
%modeling the paper's "RX input random noise" ([FEXT] p.84 Sec. V: "1.8 mV
%RMS RX input random noise"; [DSE] p.143 Sec. V: "random noise RMS
%amplitude of 1.8 mV on the AFE").
%
% Inputs:
%   x           - real signal (any shape), Volts
%   rms_V       - target RMS noise amplitude, Volts
%   seed_offset - integer for reproducible-but-distinct noise draws
%
% Output:
%   y - x + n, n ~ N(0, rms_V^2), same size as x

if nargin < 3
    seed_offset = 0;
end

rng(mod(seed_offset, 2^31 - 1), 'twister');
n = rms_V * randn(size(x));
y = x + n;

end
