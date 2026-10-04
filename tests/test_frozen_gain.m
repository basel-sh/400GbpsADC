function test_frozen_gain()
%TEST_FROZEN_GAIN  The CHEST pilots and the data must see the SAME analog
%gains. (1) Without frozen gains the two pilot phases get different VGA
%gains (this is the original bug); (2) with opts.agc both get exactly the
%calibrated gains.
cfg = config_224G();
Nused = cfg.ofdm.N_used;
Sk = 2*double(generate_bits(Nused, cfg.channel.pilot_seed + 777)) - 1;

bits = generate_bits(Nused * cfg.mod.bits_per_sym * 20, 11);
Xd = reshape(qam_modulate(bits, cfg.mod.order), Nused, 20);
base = struct('enable_fext', true, 'apply_impairments', true, 'seed_offset', 3);

% (1) calibration mode: pilot phases differ
[~, ~, d1] = link_forward_pass(Sk, -Sk, cfg, base);
[~, ~, d2] = link_forward_pass(Sk,  Sk, cfg, base);
rel = abs(d1.agc.adc_gain(1) - d2.agc.adc_gain(1)) / d1.agc.adc_gain(1);
assert(rel > 0.03, ['expected different per-call VGA gains in calibration ' ...
    'mode (relative difference %.3f)'], rel);

% (2) frozen mode
[~, ~, cal] = link_forward_pass(Xd, Xd(:, [2:end 1]), cfg, base);
fz = base;  fz.agc = cal.agc;  fz.noise = cal.noise;
[~, ~, f1] = link_forward_pass(Sk, -Sk, cfg, fz);
[~, ~, f2] = link_forward_pass(Sk,  Sk, cfg, fz);
assert(isequal(f1.agc.adc_gain, cal.agc.adc_gain));
assert(isequal(f2.agc.adc_gain, cal.agc.adc_gain));
assert(isequal(f1.agc.dac_scale, cal.agc.dac_scale));
assert(f1.noise.rms_V == cal.noise.rms_V);
end
