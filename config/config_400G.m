function cfg = config_400G(overrides)
%CONFIG_400G  Parameterized configuration for scaling investigation toward
%400 Gb/s/lane. Starts from the 224G configuration (config_224G) and
%overrides only the fields needed to hit a target data rate / explore a
%bottleneck axis (Part 7-8 of the project brief).
%
% NOTHING here is a claim that 400 Gb/s is achieved -- this function only
% builds a *self-consistent* configuration for a requested data rate so that
% experiments/experiment_400G_sweep.m can measure where the architecture
% breaks down. All scaling choices are explicit assumptions [C], never
% silently inherited from the paper's 224G numbers.
%
% overrides: optional struct; any field present overrides the computed
%            default for that field (used by the sweep framework), e.g.
%            overrides.mod.order = 256; overrides.adc.bits = 8;

if nargin < 1
    overrides = struct();
end

% Start from 224G defaults; the paper's numerical headline is not reproduced.
cfg = config_224G();
cfg.name = '400G_investigation';

% Everything below is an ASSUMPTION [C] -- scaling rule, not a paper value.
cfg.data_rate_bps = 400e9;                 % [C] default target for this investigation

% If the caller overrides the target data rate, apply THAT override first so
% the sampling-rate scaling rule below is derived from the requested rate,
% not silently stuck at the 400G default (this order matters -- a prior
% version of this function computed the scaling BEFORE applying overrides,
% which made a data_rate_bps override have no effect on Fs/bandwidth; fixed
% here and confirmed by the fact that sweep axis A now shows Fs/BW/BER
% actually varying with the swept data rate).
if isfield(overrides, 'data_rate_bps')
    cfg.data_rate_bps = overrides.data_rate_bps;
end

% Sampling rate is solved below AFTER modulation/FFT/CP overrides, using
% the exact framing-rate equation. Physical hardware feasibility is separate.
% Now apply ALL overrides (data_rate_bps again is a no-op here since already
% applied; an explicit fs/occupied_bw/ofdm/mod/etc. override still wins over
% the derived scaling above, as intended).
cfg = apply_overrides(cfg, overrides);

% Recompute derived fields that depend on possibly-overridden values
cfg.ofdm.N_used = cfg.ofdm.N_FFT/2 - 1;
cfg.ofdm.k_idx  = (1:cfg.ofdm.N_used).';
cfg.mod.bits_per_sym = log2(cfg.mod.order);
% Solve the actual OFDM rate equation for every modulation/FFT/CP choice.
% An explicit Fs override is a stress experiment, and its actual rate is reported.
if ~isfield(overrides,'fs')
    cfg.fs = cfg.data_rate_bps*(cfg.ofdm.N_FFT+cfg.ofdm.N_CP) / ...
        (cfg.ofdm.N_used*cfg.mod.bits_per_sym);
end
cfg.occupied_bw = cfg.fs/2;

% Achieved data rate given the FINAL (possibly overridden) parameter set:
%   DR = N_used * bits_per_sym * Fs / (NFFT + NCP)
cfg.achieved_data_rate_bps = cfg.ofdm.N_used * cfg.mod.bits_per_sym * cfg.fs / ...
    (cfg.ofdm.N_FFT + cfg.ofdm.N_CP);

cfg.results_dir = fullfile('results', '400G', 'sweeps');
cfg.fig_dir     = fullfile(cfg.results_dir, 'figures');

end

function cfg = apply_overrides(cfg, overrides)
%APPLY_OVERRIDES  Recursively merge an overrides struct into cfg.
flds = fieldnames(overrides);
for i = 1:numel(flds)
    f = flds{i};
    if isstruct(overrides.(f)) && isfield(cfg, f) && isstruct(cfg.(f))
        cfg.(f) = apply_overrides(cfg.(f), overrides.(f));
    else
        cfg.(f) = overrides.(f);
    end
end
end
