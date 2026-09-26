function [tx_time, tx_freq_full] = ofdm_modulate(qam_syms, cfg)
%OFDM_MODULATE  Map frequency-domain QAM symbols to a real time-domain OFDM
%waveform with cyclic prefix, using Hermitian-symmetric IDFT input so the
%IDFT output is purely real (wireline OFDM, no imaginary/Q time samples --
%matches [DSE] Fig. 3/7 and [FEXT] Sec. II-A).
%
% Inputs:
%   qam_syms - N_used x N_symbols matrix of complex QAM symbols (one column
%              per OFDM symbol), N_used = cfg.ofdm.N_used = N_FFT/2 - 1
%   cfg      - config struct (config_224G / config_400G) with fields
%              cfg.ofdm.N_FFT, cfg.ofdm.N_CP, cfg.ofdm.N_used
%
% Outputs:
%   tx_time      - (N_FFT+N_CP) x N_symbols real time-domain samples
%                  (CP-prepended), ready for serialization/DAC
%   tx_freq_full - N_FFT x N_symbols full (Hermitian-symmetric) frequency
%                  bins actually fed to the IDFT (useful for debugging)

NFFT = cfg.ofdm.N_FFT;
NCP  = cfg.ofdm.N_CP;
Nused = cfg.ofdm.N_used;

[rows, n_sym] = size(qam_syms);
if rows ~= Nused
    error('ofdm_modulate:sizeMismatch', ...
        'qam_syms must have %d rows (N_FFT/2-1 used sub-channels), got %d', Nused, rows);
end

tx_freq_full = zeros(NFFT, n_sym);
% Bins 1..Nused (MATLAB 1-indexed, i.e. k=1..N_used) carry data.
% Bin index 1 in MATLAB corresponds to DC -> left at 0 (unused).
tx_freq_full(2:(Nused+1), :) = qam_syms;
% Hermitian symmetry: bin (NFFT - k + 2) = conj(bin(k)) for k=2..Nused+1
tx_freq_full((NFFT-Nused+1):NFFT, :) = conj(flipud(qam_syms));
% Bin at index NFFT/2+1 (Nyquist) is left at 0, consistent with paper's use
% of only the first half (excluding DC) of the bins for data.

time_full = ifft(tx_freq_full, NFFT, 1) * sqrt(NFFT); % unitary-ish scaling, real up to eps

% Numerical Hermitian symmetry leaves a negligible imaginary residual; the
% physical DAC only sees the real part.
time_full = real(time_full);

% Add cyclic prefix: copy the LAST N_CP time samples to the front.
cp = time_full(end-NCP+1:end, :);
tx_time = [cp; time_full];

end
