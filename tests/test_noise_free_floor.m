function test_noise_free_floor()
%TEST_NOISE_FREE_FLOOR  The whole loop "pilots -> channel estimate ->
%equalize" must be accurate when noise, jitter, quantization and clipping
%are all (practically) off while the converters and the frozen gains are
%still in the signal path. Before the fix (per-call gain normalization) the
%EVM floor was about 7.6 % (-22 dB); after it is about 0.8 % (-42 dB; the
%rest is cyclic-prefix leakage of the 64-tap channel).
cfg = config_224G();
cfg.sim.num_ofdm_symbols = 40;
cfg.chest.L_moving_avg = 3;
cfg.noise.rx_input_rms_V = 0;
cfg.jitter.rms_UI = 0;
cfg.dac.bits = 16;  cfg.adc.bits = 16;
cfg.dac.clip_ratio_dB = 40;  cfg.adc.clip_ratio_dB = 40;   % clipping never triggers
r = run_224G_test(cfg, struct('seed_offset', 7));
fprintf('        EVM floor with converters ON, noise OFF: %.2f %%\n', r.evm_percent);
assert(r.evm_percent < 2, 'estimator/equalizer loop inconsistent: EVM = %.2f %%', r.evm_percent);
assert(r.ser < 1e-4, 'SER should be ~0 in the noise-free loop, got %.3e', r.ser);
end
