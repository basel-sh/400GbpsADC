function test_clip_ratio()
%TEST_CLIP_RATIO  12.6 dB / 13.4 dB (threshold / mean|x|) must map to the
%DSE paper's R_clip = 3.41 / 3.73 (threshold / RMS), and the DAC must
%actually produce that ratio on a Gaussian-like signal.
cfg = config_224G();
assert(abs(clip_ratio_to_rms(cfg.dac.clip_ratio_dB, cfg) - 3.41) < 0.02);
assert(abs(clip_ratio_to_rms(cfg.adc.clip_ratio_dB, cfg) - 3.73) < 0.02);

rng(1, 'twister');
x = randn(2e5, 1);
[y, ~] = dac_model(x, cfg, false);
beta = cfg.dac.vfs_diff_pp / 2;
ratio = beta / sqrt(mean(y.^2));
assert(abs(ratio - clip_ratio_to_rms(cfg.dac.clip_ratio_dB, cfg)) < 0.08, ...
    'DAC output beta/RMS = %.3f', ratio);
end
