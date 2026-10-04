function R = clip_ratio_to_rms(ratio_dB, cfg)
%CLIP_RATIO_TO_RMS  Linear clipping ratio R_clip = beta / A_RMS.
%
% [FEXT] (Sec. V) quotes the clipping threshold-to-AVERAGE-MAGNITUDE ratios
% 12.6 dB (TX) and 13.4 dB (RX), whereas [DSE] defines R_clip = beta/A_RMS and
% lists R_clip,DAC = 3.41 and R_clip,ADC = 3.73. For a Gaussian-like OFDM
% waveform E|x| = sigma*sqrt(2/pi), hence
%     10^(12.6/20)*sqrt(2/pi) = 3.40   and   10^(13.4/20)*sqrt(2/pi) = 3.73,
% i.e. the two papers agree once the definition is converted. Earlier code
% used 10^(dB/20) directly as beta/A_RMS (4.27 / 4.68), which makes the DAC
% output 2 dB too small and wastes ~2 dB of quantization SNR per converter.
%
% cfg.clip_ratio_is_mean_abs (default true) selects the conversion; set it
% to false to treat the dB value as beta/A_RMS directly.

R = 10^(ratio_dB/20);
if ~isfield(cfg, 'clip_ratio_is_mean_abs') || cfg.clip_ratio_is_mean_abs
    R = R * sqrt(2/pi);
end

end
