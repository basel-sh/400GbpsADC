function qam_syms_out = tx_deemphasis(qam_syms, cfg)
%TX_DEEMPHASIS  Apply the paper's per-sub-channel TX power-loading /
%de-emphasis profile in the frequency domain, BEFORE the IDFT.
%
% [A] "-10.5 dB of de-emphasis at sub-channel k=1, and fewer de-emphasis
% levels that are linearly proportional to the sub-channel index k in
% dB-scale ... gain is 0 dB at k=511" ([FEXT] p.84, Sec. V).
%
% Inputs:
%   qam_syms - N_used x N_symbols complex QAM symbols (rows = k = 1..N_used)
%   cfg      - config struct with cfg.deemph.gain_dB(k) function handle
%
% Output:
%   qam_syms_out - same size, with per-row (per-sub-channel) linear gain
%                  10^(gain_dB(k)/20) applied

% The paper's de-emphasis law is defined over k=1..511 for N_FFT=1024. For a
% general N_used (e.g. scaled 400G configs), deemphasis_gain_vector.m maps k
% linearly onto the same [1, N_used] range so the SAME relative de-emphasis
% SHAPE is preserved -- documented as a scaling assumption in docs/assumptions.md.
gain_lin = deemphasis_gain_vector(cfg);

qam_syms_out = qam_syms .* gain_lin;

end
