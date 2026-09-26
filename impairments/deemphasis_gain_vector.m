function gain_lin = deemphasis_gain_vector(cfg)
%DEEMPHASIS_GAIN_VECTOR  Per-sub-channel LINEAR TX de-emphasis gain, shared
%by impairments/tx_deemphasis.m (applies it) and any "genie"/oracle channel
%construction (experiments/run_224G_test.m) that needs to know the exact
%combined TX-deemphasis * physical-channel response the equalizer would
%estimate in a real receiver (since CHEST pilots also pass through
%de-emphasis, a real RX's channel estimate inherently includes it -- see
%docs/mathematical_model.md).
%
% [A] "-10.5 dB of de-emphasis at sub-channel k=1 ... gain is 0 dB at
% k=511" ([FEXT] p.84, Sec. V).

k = cfg.ofdm.k_idx;
k_ref_max = 511;
k_mapped = 1 + (k - 1) * (k_ref_max - 1) / max(cfg.ofdm.N_used - 1, 1);
gain_dB = cfg.deemph.gain_dB(k_mapped);
gain_lin = 10.^(gain_dB/20);

end
