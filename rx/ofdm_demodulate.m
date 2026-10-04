function rx_freq = ofdm_demodulate(rx_time_blocks, cfg)
%OFDM_DEMODULATE  Remove CP and apply DFT to a set of received OFDM symbol
%blocks, returning only the used (data-carrying) sub-channel bins.
%
% Inputs:
%   rx_time_blocks - (N_FFT+N_CP) x N_symbols matrix, each column one
%                    received, CP-still-attached OFDM symbol block
%                    (already time-aligned/synchronized -- this project
%                    assumes ideal TX-RX sample synchronization; see
%                    docs/assumptions.md, since neither paper's DSP-level
%                    synchronization circuit is modeled at the bit level)
%   cfg            - config struct
%
% Output:
%   rx_freq - N_used x N_symbols complex frequency-domain symbols
%             (k = 1..N_used, matching tx/ofdm_modulate.m's convention)

NFFT = cfg.ofdm.N_FFT;
NCP = cfg.ofdm.N_CP;
Nused = cfg.ofdm.N_used;

[rows, n_sym] = size(rx_time_blocks);
if rows ~= NFFT + NCP
    error('ofdm_demodulate:sizeMismatch', ...
        'rx_time_blocks must have %d rows (N_FFT+N_CP), got %d', NFFT+NCP, rows);
end

data_part = rx_time_blocks(NCP+1:end, :); % discard CP
Y_full = fft(data_part, NFFT, 1) / sqrt(NFFT); % inverse of the sqrt(NFFT) IDFT scaling

rx_freq = Y_full(2:(Nused+1), :); % k = 1..N_used

end
