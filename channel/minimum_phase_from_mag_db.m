function h = minimum_phase_from_mag_db(mag_dB, N, num_taps)
%MINIMUM_PHASE_FROM_MAG_DB  Build a causal, stable, minimum-phase real FIR
%impulse response from a one-sided magnitude-in-dB frequency response, using
%the standard real-cepstrum (homomorphic) minimum-phase reconstruction.
%
% This is a standard DSP technique (not paper-specific) used here because
% neither reference paper publishes the channel's phase response -- only
% loss magnitudes/plots are given (see specs/224G_paper_specs.md Sec. 6 and
% docs/assumptions.md). A minimum-phase model is the standard, physically
% reasonable choice for a passive, causal, lossy interconnect when only
% magnitude data is available.
%
% Inputs:
%   mag_dB   - 1 x (N/2+1) magnitude response in dB at frequency bins
%              0, fs/N, 2*fs/N, ..., fs/2 (DC to Nyquist inclusive)
%   N        - FFT length used to build the full Hermitian-symmetric
%              spectrum (frequency resolution = fs/N)
%   num_taps - number of causal FIR taps to keep after minimum-phase
%              reconstruction (truncates the (decaying) impulse response)
%
% Output:
%   h - num_taps x 1 real causal FIR impulse response. Truncation can change
%       its DC gain; there is no post-truncation normalization.

mag_dB = mag_dB(:).';
half = numel(mag_dB); % = N/2+1
if half ~= N/2+1
    error('minimum_phase_from_mag_db:sizeMismatch', ...
        'mag_dB must have N/2+1 = %d entries, got %d', N/2+1, half);
end

% Build full Hermitian-symmetric magnitude array over N bins
M = zeros(1, N);
M(1:half) = 10.^(mag_dB/20);
M(N/2+2:N) = fliplr(M(2:half-1)); % mirror (excluding DC and Nyquist)
M(M < 1e-12) = 1e-12; % floor to avoid log(0)

logM = log(M);
c = real(ifft(logM)); % real cepstrum

% Minimum-phase window (Oppenheim & Schafer homomorphic min-phase recipe)
w = zeros(1, N);
w(1) = 1;
w(2:N/2) = 2;
w(N/2+1) = 1;
% remaining entries (N/2+2:N) stay 0

c_min = c .* w;
H_min = exp(fft(c_min));
h_full = real(ifft(H_min));

h = h_full(1:min(num_taps, N)).';
if num_taps > N
    h(end+1:num_taps) = 0; % zero-pad if more taps requested than resolution
end

end
