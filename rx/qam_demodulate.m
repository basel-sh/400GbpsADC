function bits_hat = qam_demodulate(symbols, M)
%QAM_DEMODULATE  Inverse of tx/qam_modulate.m: nearest-neighbor slicing on a
%square Gray-coded M-QAM constellation, followed by binary-index-to-Gray labels.
%
% Inputs:
%   symbols - N x 1 complex received (equalized) QAM symbols, expected to be
%             on the same unit-average-energy scale used by qam_modulate.m
%   M       - QAM order (perfect square, e.g. 64)
%
% Output:
%   bits_hat - (N*log2(M)) x 1 column vector of detected bits

bps = log2(M);
sqrtM = sqrt(M);
avg_energy = 2 * (M - 1) / 3;
s = symbols(:) * sqrt(avg_energy); % undo modulate's normalization -> raw PAM levels

i_raw = real(s);
q_raw = imag(s);

i_level = slice_to_pam(i_raw, sqrtM);
q_level = slice_to_pam(q_raw, sqrtM);

i_bits = pam_level_to_gray_bits(i_level, sqrtM);
q_bits = pam_level_to_gray_bits(q_level, sqrtM);

bit_groups = [i_bits, q_bits]; % n_sym x bps
bits_hat = reshape(bit_groups.', [], 1);

end

function level = slice_to_pam(x, sqrtM)
% Nearest-level slicing onto {-(sqrtM-1),...,-1,1,...,(sqrtM-1)}
raw_level = round((x + (sqrtM - 1)) / 2) * 2 - (sqrtM - 1);
level = min(max(raw_level, -(sqrtM-1)), sqrtM-1);
end

function bit_cols = pam_level_to_gray_bits(level, sqrtM)
bin_int = (level + (sqrtM - 1)) / 2; % 0..sqrtM-1
n = log2(sqrtM);
bin_bits = de2bi_msb(bin_int, n);
gray_bits = zeros(size(bin_bits));
gray_bits(:,1) = bin_bits(:,1);
for b = 2:n
    gray_bits(:,b) = xor(bin_bits(:,b-1), bin_bits(:,b));
end
bit_cols = gray_bits;
end

function bit_cols = de2bi_msb(v, n)
bit_cols = zeros(numel(v), n);
for b = 1:n
    shift = n - b;
    bit_cols(:,b) = bitand(bitshift(round(v), -shift), 1);
end
end
