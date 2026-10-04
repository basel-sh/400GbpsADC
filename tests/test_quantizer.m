function test_quantizer()
%TEST_QUANTIZER  Mid-rise property: 2^bits symmetric levels, no zero level,
%error <= LSB/2 everywhere inside the range.
fsv = 0.25;  bits = 7;
x = linspace(-fsv, fsv, 100001);
[q, meta] = quantization_model(x, bits, fsv);
lv = unique(q(:));
assert(numel(lv) == 2^bits, 'expected %d levels, got %d', 2^bits, numel(lv));
assert(max(abs(lv + flipud(lv))) < 1e-12, 'levels are not symmetric');
assert(~any(abs(lv) < 1e-15), 'mid-rise quantizer must not have a zero level');
assert(max(abs(q - x)) <= meta.lsb/2 + 1e-12, 'error exceeds LSB/2');
end
