function bits = generate_bits(num_bits, seed)
%GENERATE_BITS  Reproducible random bit source.
%   bits = GENERATE_BITS(num_bits, seed) returns a column vector of
%   num_bits uniformly random 0/1 bits using a seeded RNG so that runs are
%   reproducible (Part 11 code-quality requirement: reproducible seeds).
%
% Inputs:
%   num_bits - number of bits to generate
%   seed     - RNG seed (integer)

rng(seed, 'twister');
bits = randi([0 1], num_bits, 1);

end
