function symbols = qam_modulate(bits, M)
%QAM_MODULATE  Custom square M-QAM Gray-coded modulator (no Communications
%Toolbox dependency -- see README.md "Toolbox alternatives").
%
%   symbols = QAM_MODULATE(bits, M) maps a column vector of bits (length
%   must be a multiple of log2(M)) to unit-average-energy complex QAM
%   symbols using Gray coding on each of the I and Q rails independently
%   (standard square-QAM construction, matches the pre-FEC BER-with-gray-
%   coding assumption used in the reference paper, [FEXT] p.85).
%
% Inputs:
%   bits - Nbits x 1 column vector of 0/1 bits
%   M    - QAM order (must be a perfect square, e.g. 4, 16, 64, 256)
%
% Output:
%   symbols - (Nbits/log2(M)) x 1 column vector of complex QAM symbols,
%             normalized to unit average energy E[|s|^2] = 1

bps = log2(M);
if mod(bps,1) ~= 0 || mod(sqrt(M),1) ~= 0
    error('qam_modulate:invalidOrder', 'M must be a perfect square power of 2 (4,16,64,256,...)');
end
if mod(numel(bits), bps) ~= 0
    error('qam_modulate:badLength', 'Number of bits must be a multiple of log2(M)=%d', bps);
end

bits = bits(:);
n_sym = numel(bits) / bps;
bit_groups = reshape(bits, bps, n_sym).'; % each row = bps bits for one symbol

half_bps = bps/2;
i_bits = bit_groups(:, 1:half_bps);
q_bits = bit_groups(:, half_bps+1:end);

sqrtM = sqrt(M);
i_level = gray_bits_to_pam_level(i_bits, sqrtM);
q_level = gray_bits_to_pam_level(q_bits, sqrtM);

symbols_raw = i_level + 1j*q_level;

% Normalize to unit average symbol energy: for a sqrtM-PAM rail with levels
% {-(sqrtM-1),...,-1,1,...,(sqrtM-1)} (step 2), E[level^2] = (M-1)/3.
avg_energy = 2 * (M - 1) / 3; % factor 2 for I+Q rails combined
symbols = symbols_raw / sqrt(avg_energy);

end

function levels = gray_bits_to_pam_level(bit_cols, sqrtM)
% Convert Gray-coded bit groups (rows = symbols, cols = bits per rail) to
% PAM levels in {-(sqrtM-1), ..., -1, 1, ..., (sqrtM-1)} (step 2).
bps_rail = size(bit_cols, 2);
n_sym = size(bit_cols, 1);

% Gray-to-binary conversion (row-wise), MSB first. The input bit_cols ARE
% the Gray-coded level index bits by construction (standard square-QAM
% convention), so no re-encoding is needed -- only the Gray->binary step.
gray_bits = bit_cols;
bin_bits = zeros(n_sym, bps_rail);
bin_bits(:,1) = gray_bits(:,1);
for b = 2:bps_rail
    bin_bits(:,b) = xor(bin_bits(:,b-1), gray_bits(:,b));
end
bin_int = bi2de_msb(bin_bits);

levels = 2*bin_int - (sqrtM - 1);
end

function v = bi2de_msb(bit_cols)
% Bit matrix (rows=symbols, cols=bits, MSB first) -> integer column vector
n = size(bit_cols,2);
weights = 2.^(n-1:-1:0);
v = bit_cols * weights.';
end

function bit_cols = de2bi_msb(v, n)
% Integer column vector -> bit matrix (MSB first)
bit_cols = zeros(numel(v), n);
for b = 1:n
    shift = n - b;
    bit_cols(:,b) = bitand(bitshift(v, -shift), 1);
end
end
