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

M = cfg.mod.order; %64
sqrtM = sqrt(M); %8
Nused = cfg.ofdm.N_used; %511
Nsym = cfg.sim.num_ofdm_symbols; %2000
bps = cfg.mod.bits_per_sym; %6

nbits = Nused * bps * Nsym; %6,132,000 bits
bits = generate_bits(nbits, cfg.sim.rng_seed + 9001);
tx_syms = qam_modulate(bits, M); % 1,022,000 symbols

esn0_dB_range = cfg.sim.snr_sweep_dB; % Size of 11 from 10 to 30
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
plot_results(esn0_dB_range, {ser_meas, ser_theory}, ...
    {'Measured SER (this implementation)', 'Theoretical SER (AWGN, square M-QAM)'}, ...
    'E_s/N_0 (dB)', 'Symbol Error Rate', ...
    sprintf('TEST 1: Ideal %d-QAM link vs. AWGN theory', M), ...
    fullfile(fig_dir, 'test1_ideal_ser_vs_snr.png'));

% A zero observed rate is not eps or a measured probability of zero.
% Compare rates directly rather than reporting an artificial log10(eps) gap.
fprintf('[TEST 1] Ideal link: max absolute |measured-theory| SER = %.3e\n', ...
    max(abs(ser_meas - ser_theory)));
if any(ser_meas == 0)
    n_qam = numel(tx_syms);
    upper95 = -expm1(log(0.05)/n_qam);
    fprintf(['         %d/%d SNR points had 0 errors out of %d symbols each; ', ...
        'nominal one-sided 95%% SER upper bound = %.3e (independent trials).\n'], ...
        sum(ser_meas == 0), numel(ser_meas), n_qam, upper95);
end

end
