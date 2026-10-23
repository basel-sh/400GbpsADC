function [ser, num_errors] = calculate_ser(tx_syms, rx_syms, M)
%CALCULATE_SER  Symbol error rate between transmitted and detected QAM
%symbol indices. Re-detects tx_syms/rx_syms to nearest constellation point
%so this can be called directly on ideal TX symbols and equalized RX
%symbols without a separate "true index" bookkeeping step.
sqrtM = sqrt(M);
avg_energy = 2*(M-1)/3;

idx_tx = nearest_index(tx_syms, sqrtM, avg_energy);
idx_rx = nearest_index(rx_syms, sqrtM, avg_energy);

if isempty(idx_tx) || numel(idx_tx) ~= numel(idx_rx)
    error('calculate_ser:alignment', 'Symbol vectors must be nonempty and have equal lengths.');
end
n = numel(idx_tx);
num_errors = sum(idx_tx(1:n) ~= idx_rx(1:n));
ser = num_errors / n;
end

function idx = nearest_index(s, sqrtM, avg_energy)
s = s(:) * sqrt(avg_energy);
i_level = round((real(s) + (sqrtM-1))/2)*2 - (sqrtM-1);
q_level = round((imag(s) + (sqrtM-1))/2)*2 - (sqrtM-1);
i_level = min(max(i_level, -(sqrtM-1)), sqrtM-1);
q_level = min(max(q_level, -(sqrtM-1)), sqrtM-1);
idx = (i_level + (sqrtM-1))/2 * sqrtM + (q_level + (sqrtM-1))/2;
end
