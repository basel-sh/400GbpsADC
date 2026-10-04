function [H13, H23, H14, H24] = channel_estimation(Sk, Y1_n1, Y2_n1, Y1_n2, Y2_n2)
%CHANNEL_ESTIMATION  2x2 MIMO channel estimation from two CHEST OFDM
%symbols per cycle, implementing [FEXT] Sec. IV-A, eqs. (7)-(12).
%
% Protocol (per CHEST cycle):
%   n=1: X1_k = Sk, X2_k = -Sk  (opposite-polarity pilots on the two lanes)
%   n=2: X1_k = Sk, X2_k = +Sk  (identical pilots on the two lanes)
% giving, per sub-channel k:
%   Y1_n1 = H13*Sk - H23*Sk        Y2_n1 = H14*Sk - H24*Sk
%   Y1_n2 = H13*Sk + H23*Sk        Y2_n2 = H14*Sk + H24*Sk
% and therefore (eqs. 11-12):
%   H23 = (Y1_n2 - Y1_n1) / (2*Sk)     H13 = (Y1_n2 + Y1_n1) / (2*Sk)
%   H14 = (Y2_n2 + Y2_n1) / (2*Sk)     H24 = (Y2_n2 - Y2_n1) / (2*Sk)
%
% Inputs (all N_used x N_cycles: one column per repeated CHEST cycle, so
% the caller can moving-average the RAW noisy estimates over L cycles per
% [FEXT] p.84-85, Sec. IV-A / Sec. V -- see analysis or experiment code for
% the moving-average step, cfg.chest.L_moving_avg):
%   Sk    - N_used x 1 (or N_used x N_cycles) known pilot QAM values
%   Y1_n1, Y2_n1 - received symbols during phase n=1 (opposite polarity)
%   Y1_n2, Y2_n2 - received symbols during phase n=2 (same polarity)
%
% Outputs:
%   H13, H23, H14, H24 - N_used x N_cycles raw (per-cycle, noisy) channel
%                         estimates; average across the 2nd dimension with
%                         cumulative/moving mean to obtain the stabilized
%                         estimate used by the FDE (see docs/mathematical_model.md)

H23 = (Y1_n2 - Y1_n1) ./ (2*Sk);
H13 = (Y1_n2 + Y1_n1) ./ (2*Sk);
H14 = (Y2_n2 + Y2_n1) ./ (2*Sk);
H24 = (Y2_n2 - Y2_n1) ./ (2*Sk);

end
