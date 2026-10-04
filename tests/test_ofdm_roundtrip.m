function test_ofdm_roundtrip()
%TEST_OFDM_ROUNDTRIP  modulate -> demodulate over an identity channel.
cfg = config_224G();
rng(3, 'twister');
X = (randn(cfg.ofdm.N_used, 5) + 1j*randn(cfg.ofdm.N_used, 5)) / sqrt(2);
t = ofdm_modulate(X, cfg);
assert(isreal(t), 'time signal must be real (Hermitian symmetry)');
assert(size(t, 1) == cfg.ofdm.N_FFT + cfg.ofdm.N_CP);
Y = ofdm_demodulate(t, cfg);
assert(max(abs(Y(:) - X(:))) < 1e-10, 'round trip error too large');
end
