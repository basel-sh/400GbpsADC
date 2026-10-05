function [h, info] = fext_channel(cfg, main_info)
%FEXT_CHANNEL  Synthetic, parameterized FAR-END CROSSTALK (aggressor ->
%victim) impulse response.
%
% NOT SPECIFIED IN REFERENCE PAPER beyond a single qualitative + one
% numeric anchor: "~28 dB main-to-FEXT ratio at sub-channel k=50 (~3.7 GHz)"
% ([FEXT] p.84-85, Sec. V), and the qualitative statement that FEXT is weak
% at low frequency and becomes significant at high frequency (Fig. 8 in
% [FEXT]). This function models the main-to-FEXT ratio (dB) as decreasing
% with frequency at a configurable slope (cfg.channel.fext_ratio_slope_dB_per_decade),
% anchored at the paper's stated point, with a numerical safety floor.
% See docs/assumptions.md for the full justification.
%
% Inputs:
%   cfg       - config struct
%   main_info - info struct returned by main_channel.m (reuses its
%               loss_dB_fn so the FEXT channel is defined RELATIVE to the
%               same main-channel loss profile)
%
% Outputs:
%   h    - cfg.channel.num_taps x 1 real causal FIR impulse response
%   info - struct with the ratio law used (info.ratio_dB_fn)

if isfield(cfg.channel, 'type') && strcmp(cfg.channel.type, 'touchstone')
    [h, info] = touchstone_channel(cfg, 'fext');
    return;
end
fs = cfg.fs;
Nfft_ir = cfg.channel.ir_fft_len;

R_ref = cfg.channel.fext_to_main_ratio_dB; % 28 dB
f_ref = cfg.channel.fext_ratio_at_freq;    % 3.7 GHz
slope = cfg.channel.fext_ratio_slope_dB_per_decade;
floor_dB = cfg.channel.fext_ratio_floor_dB;

ratio_dB_fn = @(f) max(R_ref - slope .* log10(max(f, 1) / f_ref), floor_dB);

f_axis = (0:Nfft_ir/2) * (fs / Nfft_ir);
main_loss_dB = main_info.loss_dB_fn(f_axis); % positive-valued loss (dB)
fext_loss_dB = main_loss_dB + ratio_dB_fn(f_axis); % FEXT is MORE attenuated
                                                     % by the ratio (dB) than
                                                     % the main channel
mag_dB = -fext_loss_dB;

h = minimum_phase_from_mag_db(mag_dB, Nfft_ir, cfg.channel.num_taps);

info = struct();
info.ratio_dB_fn = ratio_dB_fn;

end
