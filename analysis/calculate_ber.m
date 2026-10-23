function [ber, num_errors] = calculate_ber(tx_bits, rx_bits)
%CALCULATE_BER  Bit error rate between transmitted and received bit vectors.
tx_bits = tx_bits(:);
rx_bits = rx_bits(:);
if isempty(tx_bits) || numel(tx_bits) ~= numel(rx_bits)
    error('calculate_ber:alignment', 'Bit vectors must be nonempty and have equal lengths.');
end
n = numel(tx_bits);
num_errors = sum(tx_bits(1:n) ~= rx_bits(1:n));
ber = num_errors / n;
end
