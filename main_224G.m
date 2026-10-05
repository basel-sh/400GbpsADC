%MAIN_224G  Single entry point: runs the complete 224 Gb/s MIMO-OFDM
%baseline validation suite (TESTs 1-6), saves all figures under
%results/224G/figures/, and prints a summary comparing measured results to
%the paper's reported values.
%
% Usage (from the project root, i.e. this file's folder):
%   >> main_224G
%
% Requires: base MATLAB only (no toolboxes) -- see README.md.

close all;
proj_root = fileparts(mfilename('fullpath'));
addpath(genpath(proj_root));

fprintf('=== 224 Gb/s MIMO-OFDM baseline: full validation suite ===\n\n');

cfg = config_224G();

chan_dir = 'D:\projects\GP\channels\c2c\Channel1\';
prefix   = 'Asic_Mezz_Retimer_L10';
cfg.channel.type = 'touchstone';
cfg.channel.touchstone = struct( ...
    'thru_file', fullfile(chan_dir, [prefix '_Thru.s4p']), ...
    'fext_file', fullfile(chan_dir, [prefix '_FEXT1.s4p']));

if ~exist(cfg.results_dir, 'dir'), mkdir(cfg.results_dir); end
if ~exist(cfg.fig_dir, 'dir'), mkdir(cfg.fig_dir); end

t_start = tic;

fprintf('--- TEST 1: Ideal QAM/OFDM link ---\n');
res1 = experiment_ideal_channel(cfg);

fprintf('\n--- TESTS 2-4: channel / MIMO-FEXT (genie channel, no impairments) ---\n');
res234 = experiment_fext(cfg);

fprintf('\n--- TESTS 5-6: full 224G baseline (CHEST + impairments) + headline figures ---\n');
res56 = experiment_224G(cfg);

elapsed = toc(t_start);
fprintf('\nTotal simulation time: %.1f s\n', elapsed);

results = struct('test1', res1, 'test234', res234, 'test56', res56, 'cfg', cfg);
save(fullfile(cfg.results_dir, 'results_224G.mat'), 'results');

fprintf('\n=== SUMMARY (see docs/validation.md for full discussion) ===\n');
fprintf('%-45s %-15s %-15s\n', 'Metric', 'This model', 'Paper [FEXT]');
fprintf('%-45s %-15.3e %-15s\n', 'SER with FEXT cancellation', res56.test6.ser, '1.4e-5');
fprintf('%-45s %-15.3e %-15s\n', 'SER without FEXT cancellation', res56.test6.ser_other_mode, '4e-1');
fprintf('%-45s %-15.3e %-15s\n', 'Pre-FEC BER with FEXT cancellation', res56.test6.ber, '2.4e-6 (gray-coded)');
fprintf('\nAll figures saved under: %s\n', cfg.fig_dir);
fprintf('Results struct saved to: %s\n', fullfile(cfg.results_dir, 'results_224G.mat'));
fprintf('\nIMPORTANT: the physical channel used here is a parameterized SYNTHETIC\n');
fprintf('model calibrated to the paper''s two numeric anchor points (23 dB @ 40 GHz\n');
fprintf('main-channel loss, ~28 dB main-to-FEXT ratio @ 3.7 GHz) -- NOT the exact\n');
fprintf('measured channel used in the paper (unavailable in the text). See\n');
fprintf('docs/validation.md and docs/open_questions.md.\n');
