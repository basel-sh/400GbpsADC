function [h, info] = main_channel(cfg)
%MAIN_CHANNEL  Synthetic, parameterized THRU (main) channel impulse response.
%
% NOT SPECIFIED IN REFERENCE PAPER: the exact measured S-parameters behind
% [FEXT] Fig. 8 / [DSE] Fig. 9 ("CH3", IEEE 802.3ck channel tool) are not
% printed in either paper's text. This function builds a standard
% skin-effect (~sqrt(f)) + dielectric-loss (~f) attenuation profile,
% calibrated so that:
%   loss_dB(cfg.channel.main_loss_at_freq) == cfg.channel.main_loss_dB_at_f
% i.e. 23 dB @ 40 GHz, matching the paper's headline anchor point ([FEXT]
% Abstract). See specs/224G_paper_specs.md Sec. 6 and docs/assumptions.md.
%
% Phase: a minimum-phase realization is used (see
% channel/minimum_phase_from_mag_db.m) since no phase/group-delay data is
% published either.
%
% Input:
%   cfg - config struct (config_224G / config_400G)
%
% Outputs:
%   h    - cfg.channel.num_taps x 1 real causal FIR impulse response
%   info - struct with the calibrated model coefficients and a function
%          handle info.loss_dB_fn(f) for reuse (e.g. by fext_channel.m and
%          plot_channel_response.m)

if isfield(cfg.channel, 'type') && strcmp(cfg.channel.type, 'touchstone')
    [h, info] = touchstone_channel(cfg, 'main');
    return;
end
fs = cfg.fs;
Nfft_ir = cfg.channel.ir_fft_len;

L_ref = cfg.channel.main_loss_dB_at_f;
f_ref = cfg.channel.main_loss_at_freq;
s = cfg.channel.skin_dielectric_split;

k_skin = s * L_ref / sqrt(f_ref);
k_diel = (1 - s) * L_ref / f_ref;

loss_dB_fn = @(f) k_skin .* sqrt(f) + k_diel .* f;

f_axis = (0:Nfft_ir/2) * (fs / Nfft_ir); % DC..Nyquist
mag_dB = -loss_dB_fn(f_axis); % negative = attenuation

h = minimum_phase_from_mag_db(mag_dB, Nfft_ir, cfg.channel.num_taps);

info = struct();
info.k_skin = k_skin;
info.k_diel = k_diel;
info.loss_dB_fn = loss_dB_fn;

end
