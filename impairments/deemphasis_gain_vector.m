function gain_lin = deemphasis_gain_vector(cfg)
%DEEMPHASIS_GAIN_VECTOR  Linear TX de-emphasis gain for every used sub-channel.
%
% [A] -10.5 dB at k=1 rising LINEARLY IN dB to 0 dB at k=511 ([FEXT] Sec. V).
% The sub-channel axis of the used bins is mapped onto the paper's 1..511
% axis so other FFT sizes keep the same shape.
%
% The gain is computed directly from cfg.deemph.k1_dB / k511_dB. (The
% anonymous handle cfg.deemph.gain_dB is kept for reference, but it captures
% the values that existed when config_224G() ran, so a later change of
% cfg.deemph.k1_dB -- e.g. in a de-emphasis sweep -- would silently have had
% no effect.)

k = cfg.ofdm.k_idx;
k_ref_max = 511;
k_mapped = 1 + (k - 1) * (k_ref_max - 1) / max(cfg.ofdm.N_used - 1, 1);
gain_dB = cfg.deemph.k1_dB + (cfg.deemph.k511_dB - cfg.deemph.k1_dB) .* (k_mapped - 1) / (k_ref_max - 1);
gain_lin = 10.^(gain_dB/20);

end
