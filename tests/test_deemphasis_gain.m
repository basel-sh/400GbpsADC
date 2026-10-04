function test_deemphasis_gain()
%TEST_DEEMPHASIS_GAIN  -10.5 dB at k=1, 0 dB at k=511, linear in dB, and the
%gain must follow later changes of cfg.deemph.k1_dB (sweeps).
cfg = config_224G();
g = deemphasis_gain_vector(cfg);
gdB = 20*log10(g);
assert(abs(gdB(1) + 10.5) < 1e-9);
assert(abs(gdB(end) - 0) < 1e-9);
k = (1:numel(gdB)).';
assert(max(abs(gdB - (-10.5 + 10.5*(k-1)/510))) < 1e-9, 'not linear in dB');
cfg.deemph.k1_dB = -4;
gdB2 = 20*log10(deemphasis_gain_vector(cfg));
assert(abs(gdB2(1) + 4) < 1e-9, 'gain does not follow cfg.deemph.k1_dB');
end
