function sweep_results = experiment_400G_sweep(base_cfg)
%EXPERIMENT_400G_SWEEP  Parameterized scaling investigation (Part 7-8 of the
%project brief). Produces BER/SER/EVM and required-bandwidth/sampling-rate
%data across each of the requested sweep axes, using config_400G.m to build
%a self-consistent configuration for every point. This does NOT declare a
%"best" configuration or claim 400 Gb/s is achieved -- it only characterizes
%where the 224G-derived architecture starts to break down.
%
% Input:
%   base_cfg - (optional) a config_400G() struct to use as the starting
%              point for every sweep axis; if omitted, config_400G() with
%              no overrides is used (224G-baseline scaling rule at 400G rate)
%
% Output:
%   sweep_results - struct with one field per swept axis, each containing
%                   the swept values and measured BER/SER/EVM/bandwidth/
%                   sampling-rate/ADC-resolution/SNR arrays

if nargin < 1
    base_cfg = config_400G();
end

fig_dir = base_cfg.fig_dir;
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

sweep_results = struct();

%% A. Data rate sweep: 224, 250, 300, 350, 400 Gb/s (fixed 224G scaling rule)
rates = [224 250 300 350 400] * 1e9;
sA = init_metric_struct(numel(rates));
for i = 1:numel(rates)
    cfg = config_400G(struct('data_rate_bps', rates(i)));
    r = run_scaled_test(cfg);
    sA = fill_metric_struct(sA, i, cfg, r);
end
sweep_results.data_rate = merge_axis(rates/1e9, sA);
plot_results(rates/1e9, {sweep_results.data_rate.ber}, {'BER (cancel)'}, ...
    'Data rate (Gb/s)', 'BER', 'BER vs. Data Rate (224G scaling rule)', ...
    fullfile(fig_dir, 'sweepA_ber_vs_datarate.png'));
plot_results(rates/1e9, {sweep_results.data_rate.ser}, {'SER (cancel)'}, ...
    'Data rate (Gb/s)', 'SER', 'SER vs. Data Rate (224G scaling rule)', ...
    fullfile(fig_dir, 'sweepA_ser_vs_datarate.png'));
plot_results(rates/1e9, {sweep_results.data_rate.req_bw_GHz}, {'Occupied BW'}, ...
    'Data rate (Gb/s)', 'Required bandwidth (GHz)', 'Required Bandwidth vs. Data Rate', ...
    fullfile(fig_dir, 'sweepG_bandwidth_vs_datarate.png'), false);

%% B. ADC/DAC sampling rate sweep (at fixed 400G data rate, vary NFFT to change Fs need is
%     redundant with A; instead sweep Fs directly while holding data rate
%     fixed via compensating modulation order is complex -- here we sweep
%     Fs as an INDEPENDENT stress axis: fix data rate at 400G target but
%     force a specific (possibly insufficient) sampling rate, letting the
%     achieved data rate / BER reveal the bandwidth bottleneck.)
fs_list = linspace(0.5, 1.3, 9) * (75.25e9 * 400/224); % fraction of the "needed" 400G Fs
sB = init_metric_struct(numel(fs_list));
for i = 1:numel(fs_list)
    cfg = config_400G(struct('data_rate_bps', 400e9, 'fs', fs_list(i), ...
        'occupied_bw', fs_list(i)/2));
    r = run_scaled_test(cfg);
    sB = fill_metric_struct(sB, i, cfg, r);
end
sweep_results.sampling_rate = merge_axis(fs_list/1e9, sB);
plot_results(fs_list/1e9, {sweep_results.sampling_rate.ber}, {'BER (cancel)'}, ...
    'DAC/ADC sampling rate (GS/s)', 'BER', 'BER vs. Sampling Rate (400G target)', ...
    fullfile(fig_dir, 'sweepH_ber_vs_samplingrate.png'));

%% C. ADC/DAC resolution sweep
bits_list = 5:9;
sC = init_metric_struct(numel(bits_list));
for i = 1:numel(bits_list)
    cfg = config_400G(struct('dac', struct('bits', bits_list(i)), ...
        'adc', struct('bits', bits_list(i))));
    r = run_scaled_test(cfg);
    sC = fill_metric_struct(sC, i, cfg, r);
end
sweep_results.adc_resolution = merge_axis(bits_list, sC);
plot_results(bits_list, {sweep_results.adc_resolution.ber}, {'BER (cancel)'}, ...
    'DAC/ADC resolution (bits)', 'BER', 'BER vs. ADC/DAC Resolution (400G target)', ...
    fullfile(fig_dir, 'sweepC_ber_vs_resolution.png'));

%% D. Modulation order sweep
mod_orders = [4 16 64 256];
sD = init_metric_struct(numel(mod_orders));
for i = 1:numel(mod_orders)
    cfg = config_400G(struct('mod', struct('order', mod_orders(i), 'bit_loading', false)));
    r = run_scaled_test(cfg);
    sD = fill_metric_struct(sD, i, cfg, r);
end
sweep_results.mod_order = merge_axis(mod_orders, sD);
plot_results(mod_orders, {sweep_results.mod_order.ber}, {'BER (cancel)'}, ...
    'Modulation order (M-QAM)', 'BER', 'BER vs. Modulation Order (400G target)', ...
    fullfile(fig_dir, 'sweepD_ber_vs_modorder.png'));

%% E/F. OFDM bandwidth & FFT size sweep
nfft_list = [256 512 1024 2048];
sF = init_metric_struct(numel(nfft_list));
for i = 1:numel(nfft_list)
    cfg = config_400G(struct('ofdm', struct('N_FFT', nfft_list(i), 'N_CP', 8)));
    r = run_scaled_test(cfg);
    sF = fill_metric_struct(sF, i, cfg, r);
end
sweep_results.fft_size = merge_axis(nfft_list, sF);
plot_results(nfft_list, {sweep_results.fft_size.ber}, {'BER (cancel)'}, ...
    'N_{FFT}', 'BER', 'BER vs. FFT Size (400G target, N_{CP}=8)', ...
    fullfile(fig_dir, 'sweepF_ber_vs_fftsize.png'));

%% G. Channel loss sweep
loss_list = 15:4:39; % dB @ 40 GHz anchor
sG = init_metric_struct(numel(loss_list));
for i = 1:numel(loss_list)
    cfg = config_400G(struct('channel', struct('main_loss_dB_at_f', loss_list(i), ...
        'main_loss_at_freq', 40e9, 'fext_to_main_ratio_dB', 28, ...
        'fext_ratio_at_freq', 3.7e9, 'skin_dielectric_split', 0.5, ...
        'num_taps', 64, 'ir_fft_len', 4096, ...
        'fext_ratio_slope_dB_per_decade', 20, 'fext_ratio_floor_dB', 3, ...
        'pilot_seed', 12345)));
    r = run_scaled_test(cfg);
    sG = fill_metric_struct(sG, i, cfg, r);
end
sweep_results.channel_loss = merge_axis(loss_list, sG);
plot_results(loss_list, {sweep_results.channel_loss.ber}, {'BER (cancel)'}, ...
    'Main channel loss @ 40 GHz (dB)', 'BER', 'BER vs. Channel Loss (400G target)', ...
    fullfile(fig_dir, 'sweepE_ber_vs_channelloss.png'));

%% H. Noise sweep
noise_list_mV = [0.5 1 1.8 3 5 8];
sH = init_metric_struct(numel(noise_list_mV));
for i = 1:numel(noise_list_mV)
    cfg = config_400G(struct('noise', struct('rx_input_rms_V', noise_list_mV(i)*1e-3)));
    r = run_scaled_test(cfg);
    sH = fill_metric_struct(sH, i, cfg, r);
end
sweep_results.rx_noise = merge_axis(noise_list_mV, sH);
plot_results(noise_list_mV, {sweep_results.rx_noise.ber}, {'BER (cancel)'}, ...
    'RX input noise RMS (mV)', 'BER', 'BER vs. RX Noise (400G target)', ...
    fullfile(fig_dir, 'sweepH2_ber_vs_noise.png'));

%% I. Jitter sweep
jitter_list_pct = [0.25 0.5 1 1.5 2 3];
sI = init_metric_struct(numel(jitter_list_pct));
for i = 1:numel(jitter_list_pct)
    cfg = config_400G(struct('jitter', struct('rms_UI', jitter_list_pct(i)/100)));
    r = run_scaled_test(cfg);
    sI = fill_metric_struct(sI, i, cfg, r);
end
sweep_results.jitter = merge_axis(jitter_list_pct, sI);
plot_results(jitter_list_pct, {sweep_results.jitter.ber}, {'BER (cancel)'}, ...
    'RMS sampling jitter (%UI)', 'BER', 'BER vs. Sampling Jitter (400G target)', ...
    fullfile(fig_dir, 'sweepI_ber_vs_jitter.png'));

%% J. FEXT strength sweep
fext_ratio_list = [10 16 22 28 34 40]; % dB, main-to-FEXT ratio anchor
sJ = init_metric_struct(numel(fext_ratio_list));
for i = 1:numel(fext_ratio_list)
    cfg = config_400G(struct('channel', struct('main_loss_dB_at_f', 23, ...
        'main_loss_at_freq', 40e9, 'fext_to_main_ratio_dB', fext_ratio_list(i), ...
        'fext_ratio_at_freq', 3.7e9, 'skin_dielectric_split', 0.5, ...
        'num_taps', 64, 'ir_fft_len', 4096, ...
        'fext_ratio_slope_dB_per_decade', 20, 'fext_ratio_floor_dB', 3, ...
        'pilot_seed', 12345)));
    r = run_scaled_test(cfg);
    sJ = fill_metric_struct(sJ, i, cfg, r);
end
sweep_results.fext_strength = merge_axis(fext_ratio_list, sJ);
plot_results(fext_ratio_list, {sweep_results.fext_strength.ber}, {'BER (cancel)'}, ...
    'Main-to-FEXT ratio anchor (dB)', 'BER', 'BER vs. FEXT Strength (400G target)', ...
    fullfile(fig_dir, 'sweepJ_ber_vs_fextstrength.png'));

mat_file_400 = fullfile(base_cfg.results_dir, 'sweep_results_400G.mat');
if exist('OCTAVE_VERSION', 'builtin')
    save('-v7', mat_file_400, 'sweep_results');   % MATLAB-readable
else
    save(mat_file_400, 'sweep_results', '-v7');
end

fprintf('\n=== 400G parameter sweep complete. Bottleneck summary (see docs/validation.md) ===\n');

end

function r = run_scaled_test(cfg)
%RUN_SCALED_TEST  Runs one sweep point. To keep the FULL sweep (dozens of
%configurations) tractable in minutes rather than hours, the number of data
%OFDM symbols and the CHEST moving-average window are reduced from the
%224G-baseline defaults (config_224G: 2000 symbols, L=200) to smaller,
%still-paper-consistent values (L is kept >100 per [FEXT] Sec. IV-A/V
%whenever the baseline default already exceeds it, otherwise left as-is).
% ASSUMPTION [C]: this is a performance/precision trade-off for the sweep
% only -- re-run any individual point with the full config_400G() defaults
% (or main_224G.m-style settings) for a precise, presentation-grade number.
% See docs/assumptions.md.
cfg.sim.num_ofdm_symbols = min(cfg.sim.num_ofdm_symbols, 100);
cfg.chest.L_moving_avg = min(cfg.chest.L_moving_avg, 120);
opts = struct('enable_fext', true, 'apply_impairments', true, ...
              'use_genie_channel', false, 'fde_mode', 'cancel', 'seed_offset', 42);
r = run_224G_test(cfg, opts);
end

function s = init_metric_struct(n)
s = struct('ber', zeros(1,n), 'ser', zeros(1,n), 'evm', zeros(1,n), ...
    'req_bw_GHz', zeros(1,n), 'req_fs_GSs', zeros(1,n), 'adc_bits', zeros(1,n), ...
    'achieved_rate_Gbps', zeros(1,n));
end

function s = fill_metric_struct(s, i, cfg, r)
s.ber(i) = r.ber;
s.ser(i) = r.ser;
s.evm(i) = r.evm_percent;
s.req_bw_GHz(i) = cfg.occupied_bw/1e9;
s.req_fs_GSs(i) = cfg.fs/1e9;
s.adc_bits(i) = cfg.adc.bits;
s.achieved_rate_Gbps(i) = cfg.achieved_data_rate_bps/1e9;
end

function out = merge_axis(x, s)
out = s;
out.x = x;
end
