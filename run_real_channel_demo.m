% RUN_REAL_CHANNEL_DEMO  224 Gb/s link with a MEASURED IEEE 802.3ck C2C channel.
% Edit chan_dir / prefix, then run this file from the project root.
%   Channel1: prefix 'Asic_Mezz_Retimer_L10'        Channel2: 'Asic_Mezz_Retimer_L23'
%   Channel3: 'Asic_Mezz_Deep_Retimer_L10'           Channel4: 'Asic_Mezz_Deep_Retimer_L23'
clear functions
addpath(genpath(pwd));

chan_dir = 'D:\projects\GP\channels\c2c\Channel1\';   % <-- folder with the .s4p files
prefix   = 'Asic_Mezz_Retimer_L10';                   % <-- file-name prefix

cfg = config_224G();
cfg.channel.type = 'touchstone';
cfg.channel.touchstone = struct( ...
    'thru_file', fullfile(chan_dir, [prefix '_Thru.s4p']), ...
    'fext_file', fullfile(chan_dir, [prefix '_FEXT1.s4p']));

% Sanity check: measured THRU loss. Expected ~22.4 dB at 40 GHz (paper: 23 dB).
[~, mi] = main_channel(cfg);
fprintf('THRU loss @ 40 GHz = %.1f dB, bulk delay removed = %.2f ns\n', ...
    mi.loss_dB_fn(40e9), mi.delay_removed_s*1e9);

% Same fixes as RUN 04 (use these lines only if your config does not have them yet):
% cfg.adc.vga_gain_fixed = 2.0;
% cfg.adc.clip_ratio_dB = 20*log10(3.73);  cfg.dac.clip_ratio_dB = 20*log10(3.41);

o = struct('enable_fext',true,'apply_impairments',true,'use_genie_channel',false, ...
           'fde_mode','cancel','seed_offset',3);
r = run_224G_test(cfg, o);
fprintf('REAL CHANNEL, with FEXT cancel : SER=%.3e BER=%.3e EVM=%.1f%%\n', r.ser, r.ber, r.evm_percent);
o.fde_mode = 'naive';
r = run_224G_test(cfg, o);
fprintf('REAL CHANNEL, naive (no cancel): SER=%.3e BER=%.3e EVM=%.1f%%\n', r.ser, r.ber, r.evm_percent);
