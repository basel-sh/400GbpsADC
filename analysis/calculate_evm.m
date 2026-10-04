function evm_percent = calculate_evm(tx_syms, rx_syms)
%CALCULATE_EVM  Error Vector Magnitude (%), defined as
%   EVM = sqrt( E[|rx - tx|^2] / E[|tx|^2] ) * 100
% tx_syms, rx_syms must be on the same (unit-average-energy) constellation
% scale, aligned sample-for-sample.
tx_syms = tx_syms(:);
rx_syms = rx_syms(:);
n = min(numel(tx_syms), numel(rx_syms));
err = rx_syms(1:n) - tx_syms(1:n);
evm_percent = 100 * sqrt(mean(abs(err).^2) / mean(abs(tx_syms(1:n)).^2));
end
