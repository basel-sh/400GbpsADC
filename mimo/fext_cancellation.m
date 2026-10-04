function [Xhat1, Xhat2] = fext_cancellation(Y1, Y2, H13, H23, H14, H24)
%FEXT_CANCELLATION  2x2 MIMO per-sub-channel FEXT cancellation via exact
%matrix inversion, implementing [FEXT] eqs. (3)-(6):
%
%   [Xhat1_k; Xhat2_k] = Hk^-1 * [Y1_k; Y2_k],  Hk = [H13_k H23_k; H14_k H24_k]
%
%   det_k = H13_k*H24_k - H23_k*H14_k
%   P1_k =  H24_k/det_k,  P2_k = -H23_k/det_k
%   P3_k = -H14_k/det_k,  P4_k =  H13_k/det_k
%   Xhat1_k = P1_k*Y1_k + P2_k*Y2_k
%   Xhat2_k = P3_k*Y1_k + P4_k*Y2_k
%
% All inputs are per-sub-channel (rows = k = 1..N_used) and may have
% multiple columns (OFDM data symbols); H13/H23/H14/H24 are broadcast
% across columns if given as N_used x 1 (one estimate applied to many data
% symbols, as in normal operation between CHEST cycles).
%
% Inputs:
%   Y1, Y2           - N_used x N_symbols received (un-equalized) symbols
%   H13, H23, H14, H24 - N_used x 1 (or N_used x N_symbols) channel
%                        estimates: H13/H24 = main, H23/H14 = FEXT

det_k = H13.*H24 - H23.*H14;

P1 =  H24 ./ det_k;
P2 = -H23 ./ det_k;
P3 = -H14 ./ det_k;
P4 =  H13 ./ det_k;

Xhat1 = P1 .* Y1 + P2 .* Y2;
Xhat2 = P3 .* Y1 + P4 .* Y2;

end
