function results = experiment_fext(cfg)
%EXPERIMENT_FEXT  TESTS 2, 3, 4 (Part 5 of the project brief):
%   TEST 2: OFDM with (main) channel only, single-lane FDE, no FEXT present
%   TEST 3: 2x2 MIMO WITHOUT FEXT cancellation (naive per-lane FDE) with a
%           real FEXT aggressor present
%   TEST 4: 2x2 MIMO WITH FEXT cancellation (full matrix-inverse FDE)
%
% All three use the GENIE (oracle) channel response -- i.e. equalization
% uses the exact synthetic channel, not a pilot-based CHEST estimate -- and
% NO DAC/ADC impairments, so that the comparison isolates the effect of the
% channel/FEXT/equalizer architecture alone. CHEST estimation error and
% converter impairments are added on top in experiment_224G.m (TESTS 5-6).

fig_dir = cfg.fig_dir;

common_opts = struct('apply_impairments', false, 'use_genie_channel', true, 'seed_offset', 1);

% TEST 2: single lane, main channel only, no FEXT
opts2 = common_opts; opts2.enable_fext = false; opts2.fde_mode = 'naive';
r2 = run_224G_test(cfg, opts2);

% TEST 3: MIMO, FEXT present, naive (uncancelled) FDE
opts3 = common_opts; opts3.enable_fext = true; opts3.fde_mode = 'naive';
r3 = run_224G_test(cfg, opts3);

% TEST 4: MIMO, FEXT present, full FEXT cancellation
opts4 = common_opts; opts4.enable_fext = true; opts4.fde_mode = 'cancel';
r4 = run_224G_test(cfg, opts4);

fprintf('[TEST 2] OFDM + main channel only:            SER = %.3e, BER = %.3e\n', r2.ser, r2.ber);
fprintf('[TEST 3] 2x2 MIMO, FEXT present, NO cancel:    SER = %.3e, BER = %.3e\n', r3.ser, r3.ber);
fprintf('[TEST 4] 2x2 MIMO, FEXT present, WITH cancel:  SER = %.3e, BER = %.3e\n', r4.ser, r4.ber);

% Constellations before/after cancellation (Fig. 10(a)-(c) style): pick a
% low-, mid-, and high-frequency sub-channel
Nused = cfg.ofdm.N_used;
sub_idx = round([0.05, 0.4, 0.9] * Nused);
sub_idx = max(sub_idx, 1);
Nsym = cfg.sim.num_ofdm_symbols;
labels = {'low-frequency', 'mid-frequency', 'high-frequency'};
for i = 1:numel(sub_idx)
    k = sub_idx(i);
    idx = k:Nused:numel(r3.rx_syms1); % pick this sub-channel's symbols across all OFDM symbols
    plot_constellation(r3.rx_syms1(idx), r4.rx_syms1(idx), ...
        sprintf('TEST 3/4: sub-channel k=%d (%s), lane 1', k, labels{i}), ...
        fullfile(fig_dir, sprintf('test4_constellation_k%d_%s.png', k, labels{i})));
end

% Per-sub-channel SER, with vs. without cancellation (Fig. 10(d) style)
plot_results(1:Nused, {r3.ser_per_subchannel, r4.ser_per_subchannel}, ...
    {'Without FEXT cancellation', 'With FEXT cancellation'}, ...
    'Sub-channel index k', 'Symbol Error Rate', ...
    'TEST 3 vs 4: per-sub-channel SER with/without FEXT cancellation', ...
    fullfile(fig_dir, 'test3_4_ser_per_subchannel.png'));

% Overall SER bar comparison
fig = figure('Visible','off','Color','w','Position',[100 100 480 400]);
bar([r2.ser, r3.ser, r4.ser]);
set(gca,'YScale','log', 'XTick', 1:3, 'XTickLabel', ...
    {'No FEXT (T2)','MIMO no cancel (T3)','MIMO w/ cancel (T4)'});
grid on; box on;
ylabel('Symbol Error Rate'); title('TEST 2-4: overall SER comparison');
save_figure(fig, fullfile(fig_dir, 'test2_4_ser_comparison.png'));

results = struct('test2', r2, 'test3', r3, 'test4', r4);

end
