function r = effective_clip_ratio(p)
% Convert the stated clipping reference to a threshold/RMS ratio.
% For near-Gaussian OFDM, E|x|/RMS = sqrt(2/pi).
r=10^(p.clip_ratio_dB/20);
if isfield(p,'clip_reference') && strcmp(p.clip_reference,'mean_abs')
    r=r*sqrt(2/pi);
end
end
