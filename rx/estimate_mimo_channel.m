function [H13, H24, H23, H14, chest_diag] = estimate_mimo_channel(cfg, opts)
%ESTIMATE_MIMO_CHANNEL  Full CHEST procedure: repeats the paper's two-symbol
%pilot protocol ([FEXT] Sec. IV-A, eqs. 7-12) for cfg.chest.L_moving_avg
%cycles through the ACTUAL simulated physical link (link_forward_pass.m,
%same DAC/channel/noise/ADC chain used for data), then moving-averages the
%raw per-cycle estimates ([FEXT] p.84-85: "the P_k can be moving-averaged
%... with sufficiently large averaging window L (e.g., L>100)").
%
% Inputs:
%   cfg  - config struct (uses cfg.chest.L_moving_avg)
%   opts - passed through to link_forward_pass.m for each pilot cycle
%          (enable_fext, apply_impairments, enable_channel); seed_offset is
%          set internally per-cycle for reproducible-but-distinct draws
%
% Outputs:
%   H13, H24 - N_used x 1 averaged MAIN channel estimates (lane 1, lane 2)
%   H23, H14 - N_used x 1 averaged FEXT channel estimates
%   chest_diag - struct with the raw (pre-average) per-cycle estimates for
%                convergence plotting (matches [FEXT] Fig. 9 style: |P1_k|,
%                |P2_k| vs. moving-average window size L)

if nargin < 2, opts = struct(); end

Nused = cfg.ofdm.N_used;
L = cfg.chest.L_moving_avg;

% [C] Pilot sequence values are not specified beyond "known QAM values with
% equal real/imaginary magnitude" ([FEXT] p.83, Sec. IV-A). A fixed
% pseudo-random +/-1 sequence (unit magnitude, known to TX and RX) is used
% here -- this avoids the very high PAPR of an all-equal-magnitude,
% all-same-phase pilot tone (which would clip pathologically under the
% paper's stated clipping ratios) while satisfying "equal magnitude".
pilot_bits = generate_bits(Nused, cfg.channel.pilot_seed + 777);
Sk = 2*double(pilot_bits) - 1; % +/-1, unit magnitude

H13_raw = zeros(Nused, L);
H23_raw = zeros(Nused, L);
H14_raw = zeros(Nused, L);
H24_raw = zeros(Nused, L);

for c = 1:L
    o = opts;
    o.seed_offset = 5000 + c;

    % n=1: opposite polarity
    [Y1_n1, Y2_n1] = link_forward_pass(Sk, -Sk, cfg, o);
    o.seed_offset = 6000 + c;
    % n=2: identical
    [Y1_n2, Y2_n2] = link_forward_pass(Sk, Sk, cfg, o);

    [h13, h23, h14, h24] = channel_estimation(Sk, Y1_n1, Y2_n1, Y1_n2, Y2_n2);
    H13_raw(:,c) = h13;
    H23_raw(:,c) = h23;
    H14_raw(:,c) = h14;
    H24_raw(:,c) = h24;
end

H13 = mean(H13_raw, 2);
H23 = mean(H23_raw, 2);
H14 = mean(H14_raw, 2);
H24 = mean(H24_raw, 2);

chest_diag = struct();
chest_diag.H13_raw = H13_raw;
chest_diag.H23_raw = H23_raw;
chest_diag.H14_raw = H14_raw;
chest_diag.H24_raw = H24_raw;
% Cumulative-mean magnitude trace vs. window size L, for the Fig.-9-style
% convergence plot: cummean_L(k) = mean(H(:, 1:L)) evaluated at each L.
cs13 = cumsum(H13_raw, 2);
chest_diag.P_conv_L = 1:L;
chest_diag.H13_mag_vs_L = abs(cs13 ./ (1:L));

end
