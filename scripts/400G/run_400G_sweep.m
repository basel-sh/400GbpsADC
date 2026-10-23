%RUN_400G_SWEEP  Single entry point for the 400 Gb/s scaling investigation
%(Part 7-8 of the project brief). Runs experiments/experiment_400G_sweep.m
%across all requested axes (data rate, sampling rate, ADC/DAC resolution,
%modulation order, FFT size, channel loss, RX noise, jitter, FEXT strength)
%and saves all figures under results/400G/sweeps/figures/.
%
% Usage:
%   >> run(fullfile('scripts','400G','run_400G_sweep.m'))
%
% NOTE: per Part 8 of the project brief, this framework is for BOTTLENECK
% IDENTIFICATION -- it does NOT claim that 400 Gb/s/lane is achieved, and it
% does NOT select a "best" configuration. See docs/validation.md.

close all;
proj_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(genpath(proj_root));

fprintf('=== 400 Gb/s/lane scaling investigation (parameter sweep) ===\n\n');

base_cfg = config_400G();
base_cfg.results_dir = fullfile(proj_root, 'results', '400G', 'sweeps');
base_cfg.fig_dir = fullfile(base_cfg.results_dir, 'figures');
if ~exist(base_cfg.results_dir, 'dir'), mkdir(base_cfg.results_dir); end
if ~exist(base_cfg.fig_dir, 'dir'), mkdir(base_cfg.fig_dir); end

fprintf('Baseline 400G scaling-rule config: Fs=%.2f GS/s, BW=%.2f GHz, achieved rate=%.1f Gb/s\n', ...
    base_cfg.fs/1e9, base_cfg.occupied_bw/1e9, base_cfg.achieved_data_rate_bps/1e9);

sweep_results = experiment_400G_sweep(base_cfg);

fprintf('\nAll sweep figures saved under: %s\n', base_cfg.fig_dir);
fprintf('Sweep data saved to: %s\n', fullfile(base_cfg.results_dir, 'sweep_results_400G.mat'));
fprintf('See docs/validation.md for the bottleneck discussion and docs/open_questions.md.\n');
