function result = experiment_ideal_channel(cfg)
%EXPERIMENT_IDEAL_CHANNEL  TEST 1: Ideal QAM/OFDM link (no physical channel,
%no DAC/ADC impairments) -- a foundational sanity check that
%tx/qam_modulate.m + rx/qam_demodulate.m + tx/ofdm_modulate.m +
%rx/ofdm_demodulate.m are self-consistent, by sweeping symbol-level AWGN
%directly (classic Es/N0 sweep) and comparing the measured SER against the
%closed-form theoretical SER for square M-QAM in AWGN:
%   SER_theory = 1 - (1 - 2*(1-1/sqrt(M))*Q(sqrt(3*Es/N0/(M-1))))^2
%
% This does NOT exercise the physical channel/DAC/ADC models -- see
% experiment_fext.m and experiment_224G.m for those.

M = cfg.mod.order;
sqrtM = sqrt(M);
Nused = cfg.ofdm.N_used;
Nsym = cfg.sim.num_ofdm_symbols;
bps = cfg.mod.bits_per_sym;

nbits = Nused * bps * Nsym;
bits = generate_bits(nbits, cfg.sim.rng_seed + 9001);
tx_syms = qam_modulate(bits, M);

esn0_dB_range = cfg.sim.snr_sweep_dB;
ser_meas = zeros(size(esn0_dB_range));
ber_meas = zeros(size(esn0_dB_range));
ser_theory = zeros(size(esn0_dB_range));

for i = 1:numel(esn0_dB_range)
    esn0 = 10^(esn0_dB_range(i)/10);
    noise_std_per_dim = sqrt(1/(2*esn0)); % unit symbol energy convention
    rng(4200+i, 'twister');
    noise = noise_std_per_dim * (randn(size(tx_syms)) + 1j*randn(size(tx_syms)));
    rx_syms = tx_syms + noise;

    ser_meas(i) = calculate_ser(tx_syms, rx_syms, M);
    rx_bits = qam_demodulate(rx_syms, M);
    ber_meas(i) = calculate_ber(bits, rx_bits);

    Qf = @(x) 0.5*erfc(x/sqrt(2));
    p = 2*(1-1/sqrtM)*Qf(sqrt(3*esn0/(M-1)));
    ser_theory(i) = 1 - (1-p)^2;
end

result = struct('snr_dB', esn0_dB_range, 'ser_meas', ser_meas, ...
    'ber_meas', ber_meas, 'ser_theory', ser_theory);

fig_dir = fullfile(cfg.fig_dir);
% Points with zero observed errors cannot be placed on a log axis: draw them
% at a plot floor and label them, instead of at eps (which looked like a
% result of ~1e-16).
n_sym = numel(tx_syms);
floor_v = 10^floor(log10(1/n_sym)) / 2;      % below one error in the sample
fig = plot_results(esn0_dB_range, {max(ser_meas, floor_v), max(ser_theory, floor_v)}, ...
    {'Measured SER (this implementation)', 'Theoretical SER (AWGN, square M-QAM)'}, ...
    'E_s/N_0 (dB)', 'Symbol Error Rate', ...
    sprintf('TEST 1: Ideal %d-QAM link vs. AWGN theory (%d symbols)', M, n_sym), '');
ax_list = findobj(fig, 'Type', 'axes', '-not', 'Tag', 'legend');
ax_main = ax_list(1);
set(ax_main, 'YLim', [floor_v 1]);
for i = find(ser_meas == 0)
    text(esn0_dB_range(i), 3*floor_v, '0 errors', 'Parent', ax_main, ...
        'HorizontalAlignment', 'center', 'FontSize', 8);
end
save_figure(fig, fullfile(fig_dir, 'test1_ideal_ser_vs_snr.png'));

% Compare only where the sample can resolve the theory value (>= ~20
% expected errors); zeros elsewhere are reported, not compared.
resolvable = ser_theory >= 20 / n_sym;
dev = abs(log10(max(ser_meas(resolvable), eps)) - log10(ser_theory(resolvable)));
fprintf('[TEST 1] Ideal link: max |log10(measured/theory)| over %d resolvable points (SER >= %.1e) = %.3f decades; %d points with 0 observed errors not compared\n', ...
    nnz(resolvable), 20 / n_sym, max(dev), nnz(ser_meas == 0));

end
