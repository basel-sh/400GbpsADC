function results = experiment_224G(cfg)
%EXPERIMENT_224G  TESTS 5 and 6 (Part 5) plus the headline supervisor-
%meeting figures (Part 6):
%   TEST 5: full DAC/ADC impairments + a MINIMAL, single-cycle (L=1,
%           un-averaged, noisy) CHEST -- isolates the effect of CHEST
%           estimation NOISE, matching the paper's own study of P_k vs.
%           moving-average window size L ([FEXT] Fig. 9, p.84-85)
%   TEST 6: FULL 224 Gb/s baseline -- full impairments + a well-converged,
%           moving-averaged CHEST (cfg.chest.L_moving_avg, paper recommends
%           L>100) -- this is "the" reported baseline result

fig_dir = cfg.fig_dir;

% --- TEST 5: minimal (L=1) CHEST, to show estimation noise sensitivity ---
cfg5 = cfg; cfg5.chest.L_moving_avg = 1;
opts5 = struct('enable_fext', true, 'apply_impairments', true, ...
               'use_genie_channel', false, 'fde_mode', 'cancel', 'seed_offset', 2);
r5 = run_224G_test(cfg5, opts5);

% --- TEST 6: full baseline, well-converged CHEST (L per config, default 200) ---
opts6 = struct('enable_fext', true, 'apply_impairments', true, ...
               'use_genie_channel', false, 'fde_mode', 'cancel', 'seed_offset', 3);
r6 = run_224G_test(cfg, opts6);

fprintf('[TEST 5] Impairments + minimal (L=1) CHEST:  SER = %.3e, BER = %.3e, EVM = %.2f%%\n', ...
    r5.ser, r5.ber, r5.evm_percent);
fprintf('[TEST 6] FULL 224G BASELINE (CHEST+impair.):  SER = %.3e, BER = %.3e, EVM = %.2f%%\n', ...
    r6.ser, r6.ber, r6.evm_percent);
fprintf('         (paper-reported reference: SER w/ cancel = 1.4e-5, SER w/o cancel = 4e-1, BER = 2.4e-6)\n');
if ~isempty(r6.agc)
    fprintf('         frozen converter gains: DAC scale = [%.4f %.4f], ADC VGA gain = [%.3f %.3f]; noise %.3g mV at %s\n', ...
        r6.agc.dac_scale, r6.agc.adc_gain, r6.noise_used.rms_V*1e3, r6.noise_used.at);
end
band_edges = [1 50; 51 100; 101 200; 201 300; 301 400; 401 450; 451 511].';
band_edges = band_edges(:, band_edges(1,:) <= cfg.ofdm.N_used);
fprintf('         TEST 6 SER by sub-channel band:');
for b = band_edges
    fprintf('  k%d-%d: %.2e', b(1), min(b(2), cfg.ofdm.N_used), ...
        mean(r6.ser_per_subchannel(b(1):min(b(2), cfg.ofdm.N_used))));
end
fprintf('\n');

% Figure: channel frequency response (main + FEXT)
plot_channel_response(cfg, fullfile(fig_dir, 'fig02_03_channel_response.png'));

% Figures: constellation before/after FEXT cancellation, full baseline, ONE
% sub-channel at a time (mixing all 511 tones with different SNR, as an
% earlier version did, only produces an unreadable filled square).
Nused_c = cfg.ofdm.N_used;
sub_idx_c = max(round([0.05, 0.4, 0.9] * Nused_c), 1);
labels_c = {'low-frequency', 'mid-frequency', 'high-frequency'};
for ci = 1:numel(sub_idx_c)
    kc = sub_idx_c(ci);
    idx_c = kc:Nused_c:numel(r6.rx_syms1);
    plot_constellation(r6.rx_syms1_other(idx_c), r6.rx_syms1(idx_c), ...
        sprintf('TEST 6 (full baseline): sub-channel k=%d (%s), lane 1', kc, labels_c{ci}), ...
        fullfile(fig_dir, sprintf('test6_constellation_k%d_%s.png', kc, labels_c{ci})));
end

% Figure: BER/SER vs SNR sweep, WITH vs WITHOUT FEXT cancellation
snr_range = cfg.sim.snr_sweep_dB;
ber_cancel = zeros(size(snr_range));
ser_cancel = zeros(size(snr_range));
ber_naive = zeros(size(snr_range));
ser_naive = zeros(size(snr_range));
for i = 1:numel(snr_range)
    o = struct('enable_fext', true, 'apply_impairments', true, ...
               'use_genie_channel', false, 'fde_mode', 'cancel', ...
               'snr_override_dB', snr_range(i), 'seed_offset', 10+i);
    rc = run_224G_test(cfg, o);
    ber_cancel(i) = rc.ber; ser_cancel(i) = rc.ser;
    o.fde_mode = 'naive';
    rn = run_224G_test(cfg, o);
    ber_naive(i) = rn.ber; ser_naive(i) = rn.ser;
end

plot_results(snr_range, {ber_cancel, ber_naive}, ...
    {'With FEXT cancellation', 'Without FEXT cancellation'}, ...
    'Total RX-input SNR, all tones (dB)', 'Bit Error Rate', ...
    'BER vs. SNR, 224 Gb/s baseline', ...
    fullfile(fig_dir, 'fig06_ber_vs_snr.png'));

plot_results(snr_range, {ser_cancel, ser_naive}, ...
    {'With FEXT cancellation', 'Without FEXT cancellation'}, ...
    'Total RX-input SNR, all tones (dB)', 'Symbol Error Rate', ...
    'SER vs. SNR, 224 Gb/s baseline', ...
    fullfile(fig_dir, 'fig07_ser_vs_snr.png'));

% Comparison of MIMO with/without FEXT cancellation (bars), this model vs.
% the paper's reported values, on a log axis spanning both.
fig = figure('Visible','off','Color','w','Position',[100 100 520 400]);
ser_cmp = [r6.ser_other_mode, 4e-1; r6.ser, 1.4e-5];   % rows: without / with cancellation
ser_cmp = max(ser_cmp, 1e-7);
bar(ser_cmp);
ax_cmp = gca;
set(ax_cmp,'YScale','log', 'YLim', [1e-6 1], 'XTick', 1:2, 'XTickLabel', {'Without cancellation','With cancellation'});
for gi = 1:2
    for si = 1:2
        text(gi + (si-1.5)*0.28, ser_cmp(gi, si)*1.6, sprintf('%.1e', ser_cmp(gi, si)), ...
            'Parent', ax_cmp, 'HorizontalAlignment', 'center', 'FontSize', 8);
    end
end
grid on; box on;
legend({'This model', 'Paper [FEXT]'}, 'Location', 'northeast');
ylabel('Symbol Error Rate');
title('Full-baseline SER, with vs. without FEXT cancellation');
save_figure(fig, fullfile(fig_dir, 'fig08_mimo_comparison.png'));

% Figure 9: full 224G baseline summary (text/metric panel)
fig = figure('Visible','off','Color','w','Position',[100 100 640 420]);
axis off;
txt = { ...
    sprintf('224 Gb/s MIMO-OFDM baseline -- TEST 6 summary'), ...
    '', ...
    sprintf('Data rate (config):        %.1f Gb/s', cfg.data_rate_bps/1e9), ...
    sprintf('N_{FFT} / N_{CP}:            %d / %d', cfg.ofdm.N_FFT, cfg.ofdm.N_CP), ...
    sprintf('Modulation:                 %d-QAM', cfg.mod.order), ...
    sprintf('Sampling rate:              %.2f GS/s', cfg.fs/1e9), ...
    sprintf('DAC/ADC resolution:         %d / %d bit', cfg.dac.bits, cfg.adc.bits), ...
    sprintf('RX noise:                   %.2f mV RMS at %s', cfg.noise.rx_input_rms_V*1e3, cfg.noise.reference), ...
    '', ...
    sprintf('SER (with FEXT cancel):     %.3e   [paper: 1.4e-5]', r6.ser), ...
    sprintf('SER (without cancel):       %.3e   [paper: 4e-1]', r6.ser_other_mode), ...
    sprintf('BER (with FEXT cancel):     %.3e   [paper: 2.4e-6, gray-coded]', r6.ber), ...
    sprintf('EVM (with FEXT cancel):     %.2f%%', r6.evm_percent), ...
    '', ...
    'See docs/validation.md for what matches, what is approximate,', ...
    'and which values are configurable assumptions (specs/224G_paper_specs.md).'};
% Draw one line at a time (more portable across renderers than a single
% multi-line cell-array text() call, which some graphics backends mis-place).
xlim([0 1]); ylim([0 1]);
line_h = 0.062;
y0 = 0.97;
for li = 1:numel(txt)
    text(0.02, y0 - (li-1)*line_h, txt{li}, 'Units','normalized', ...
        'VerticalAlignment','top', 'FontSize', 10, 'Interpreter','none');
end
save_figure(fig, fullfile(fig_dir, 'fig09_baseline_summary.png'));

results = struct('test5', r5, 'test6', r6, ...
    'snr_sweep', struct('snr_dB', snr_range, 'ber_cancel', ber_cancel, ...
    'ser_cancel', ser_cancel, 'ber_naive', ber_naive, 'ser_naive', ser_naive));

end
