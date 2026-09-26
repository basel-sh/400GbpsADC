function [r1, r2] = mimo_channel(x1, x2, h_main, h_fext, enable_fext)
%MIMO_CHANNEL  Apply the 2x2 MIMO channel (time-domain convolution) to two
%TX lanes, producing the two RX lane signals BEFORE noise/ADC.
%
% Implements the structure of [FEXT] eq. (2):
%   Y1 = H13*X1 + H23*X2   (lane 1: main*X1 + FEXT-from-lane-2)
%   Y2 = H14*X1 + H24*X2   (lane 2: FEXT-from-lane-1 + main*X2)
% with H13 = H24 = h_main and H23 = H14 = h_fext (symmetric coupling
% assumption, documented in docs/assumptions.md -- the paper does not state
% whether the two main responses or the two FEXT responses are identical;
% assuming symmetry is the simplest consistent choice for a 2-lane bus).
%
% Inputs:
%   x1, x2      - N x 1 real time-domain TX (DAC output) signals for lane 1
%                 and lane 2
%   h_main      - main-channel FIR impulse response (from main_channel.m)
%   h_fext      - FEXT-channel FIR impulse response (from fext_channel.m)
%   enable_fext - logical; if false, h_fext is ignored (used for the
%                 "ideal 2x2 MIMO without FEXT" validation test, TEST 3
%                 baseline reference / TEST 1-2 ideal-channel tests)
%
% Outputs:
%   r1, r2 - received time-domain signals for lane 1 and lane 2
%            (length N + length(h)-1, 'full' convolution, caller truncates
%            / handles as needed)

if nargin < 5
    enable_fext = true;
end

main1 = conv(x1, h_main);
main2 = conv(x2, h_main);

if enable_fext
    fext_on_1 = conv(x2, h_fext); % crosstalk FROM lane 2 INTO lane 1
    fext_on_2 = conv(x1, h_fext); % crosstalk FROM lane 1 INTO lane 2
else
    fext_on_1 = 0;
    fext_on_2 = 0;
end

r1 = main1 + fext_on_1;
r2 = main2 + fext_on_2;

end
