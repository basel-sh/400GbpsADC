function cfg = config_224G()
%CONFIG_224G  Centralized configuration for the 224 Gb/s MIMO-OFDM baseline.
%
% Every numeric value below is tagged in a trailing comment:
%   [A] = explicitly stated in the reference paper (Kim, TCAS-II 2023, "FEXT
%         Cancellation With MIMO OFDM for >200 Gb/s ADC-Based Serial Links")
%   [B] = derived mathematically from [A] values
%   [C] = NOT SPECIFIED IN REFERENCE PAPER -> configurable assumption
%
% See specs/224G_paper_specs.md for full source citations (page/section/table)
% and docs/assumptions.md for the rationale behind every [C] value.
%
% This is the ONLY place 224G numeric parameters should live. Every function
% in tx/, channel/, rx/, mimo/, impairments/ receives its parameters through
% this struct (or a field of it) -- never hard-code a parameter elsewhere.

cfg = struct();

%% ---- Identification -----------------------------------------------------
cfg.name        = '224G_baseline';
cfg.data_rate_bps = 224e9;                 % [A] p.84 Sec. V

%% ---- OFDM / FFT ------------------------------------------------------
cfg.ofdm.N_FFT  = 1024;                    % [A] p.84 Sec. V
cfg.ofdm.N_CP   = 8;                       % [A] p.84 Sec. V
cfg.ofdm.N_used = cfg.ofdm.N_FFT/2 - 1;    % [B] k = 1..511, DC & Nyquist unused
cfg.ofdm.k_idx  = (1:cfg.ofdm.N_used).';   % sub-channel indices used for TX/RX

%% ---- Modulation --------------------------------------------------------
cfg.mod.order      = 64;                  % [A] 64-QAM, p.84 Sec. V
cfg.mod.bits_per_sym = log2(cfg.mod.order); % [B]
cfg.mod.bit_loading = false;               % [A] homogeneous QAM (no bit-loading); informational

%% ---- Sampling ------------------------------------------------------------
cfg.fs          = 75.25e9;                 % [A] DAC/ADC sampling rate, p.84 Sec. V
cfg.occupied_bw = 37.625e9;                % [A] p.84 Sec. V

%% ---- Data converters -----------------------------------------------------
cfg.dac.bits          = 7;                 % [A] p.84 Sec. V
cfg.adc.bits           = 7;                % [A] p.84 Sec. V
cfg.dac.vfs_diff_pp    = 1.0;               % [A] 1 Vpp,diff DAC full-scale
cfg.adc.vfs_diff_pp    = 0.5;               % [A] 0.5 Vpp,diff ADC full-scale
cfg.dac.clip_ratio_dB  = 12.6;              % [A] TX clipping threshold-to-AVERAGE-MAGNITUDE ratio (dB)
cfg.adc.clip_ratio_dB  = 13.4;              % [A] RX clipping threshold-to-AVERAGE-MAGNITUDE ratio (dB)
cfg.clip_ratio_is_mean_abs = true;          % [B] the two dB values above are beta/mean|x| (paper wording).
                                            %     true -> beta/A_RMS = 10^(dB/20)*sqrt(2/pi) = 3.40 / 3.73,
                                            %     which equals the DSE paper's R_clip,DAC=3.41, R_clip,ADC=3.73.
                                            %     false -> treat the dB values as beta/A_RMS directly
                                            %     (the old, incorrect interpretation: 4.27 / 4.68).
cfg.vga_normalizes_to_adc_fullscale = true; % [A] VGA scales signal to ADC full-scale

%% ---- Impairments -----------------------------------------------------
cfg.jitter.rms_UI      = 0.01;             % [A] 1% UI RMS TX/RX sampling jitter
cfg.noise.rx_input_rms_V = 1.8e-3;         % [A] 1.8 mV RMS RX input random noise (white Gaussian, [C])
cfg.noise.reference     = 'rx_input';      % [C] WHERE the 1.8 mV acts. 'rx_input' = before the VGA (the
                                           %     FEXT paper's wording, "RX input"); 'adc_input' = after the
                                           %     VGA, at the ADC input (the DSE paper only says "on the
                                           %     AFE"). The paper does not settle this; it changes the
                                           %     result by ~1.5 decades -- see docs/fix_log.md.

%% ---- TX de-emphasis (power loading) --------------------------------------
% [A] -10.5 dB at k=1, 0 dB at k=511, linear in dB vs. k (p.84 Sec. V)
cfg.deemph.k1_dB   = -10.5;
cfg.deemph.k511_dB = 0.0;
% gain(k) [dB] = k1_dB + (k511_dB - k1_dB)*(k-1)/510, evaluated by
% impairments/deemphasis_gain_vector.m directly from these two numbers.

%% ---- Channel (synthetic, parameterized -- see docs/assumptions.md) -------
% [C] Exact measured S-parameters from the paper are NOT reproduced in the
% text (only a plot referencing an external IEEE 802.3ck tool page is shown).
% We calibrate a standard skin-effect + dielectric-loss channel model so the
% two headline numeric anchors given in the paper are matched:
%   * main-channel loss  = 23 dB @ 40 GHz            [A, abstract]
%   * main-to-FEXT ratio = ~28 dB @ ~3.7 GHz (k=50)   [A, p.84-85 Sec. V]
cfg.channel.type          = 'synthetic_skin_dielectric'; % [C]
cfg.channel.main_loss_dB_at_f = 23;         % [A] anchor point value
cfg.channel.main_loss_at_freq = 40e9;       % [A] anchor point frequency
cfg.channel.fext_to_main_ratio_dB = 28;     % [A] anchor point value
cfg.channel.fext_ratio_at_freq    = 3.7e9;  % [A] anchor point frequency (k=50)
cfg.channel.pilot_seed            = 12345;  % [C] seed of the fixed +/-1 CHEST pilot sequence
cfg.channel.skin_dielectric_split = 0.5;    % [C] fraction of main loss (at anchor f) attributed
                                             %     to skin-effect (sqrt(f)) vs. dielectric (f) term
cfg.channel.num_taps               = 64;    % [C] causal FIR length kept after minimum-phase design
cfg.channel.ir_fft_len             = 4096;  % [C] frequency resolution used to build the min-phase FIR
cfg.channel.fext_ratio_slope_dB_per_decade = 20; % [C] assumed roll-off of the main-to-FEXT ratio
                                             %     with frequency (ratio shrinks -> FEXT relatively
                                             %     stronger at high freq, matching qualitative
                                             %     description in [FEXT] p.84-85 Sec. V)
cfg.channel.fext_ratio_floor_dB    = 3;     % [C] minimum allowed ratio (numerical safety floor)

%% ---- MIMO ------------------------------------------------------------
% (2x2 MIMO, one aggressor [A, p.83 Sec. III] -- the 2 lanes are structural, not a parameter)

%% ---- Channel estimation ------------------------------------------------
cfg.chest.L_moving_avg    = 200;           % [A] "L > 100" stabilizes; 200 chosen [C-within-A-bound]

%% ---- Simulation control (NOT specified by the paper -> assumptions) ------
cfg.sim.num_ofdm_symbols = 2000;           % [C] number of data OFDM symbols per run
cfg.sim.rng_seed          = 2024;          % [C] reproducible seed
cfg.sim.snr_sweep_dB       = 10:2:30;       % [C] SNR sweep range for BER/SER-vs-SNR plots

%% ---- Paths -------------------------------------------------------------
cfg.results_dir = fullfile('results', '224G');
cfg.fig_dir     = fullfile(cfg.results_dir, 'figures');

end
