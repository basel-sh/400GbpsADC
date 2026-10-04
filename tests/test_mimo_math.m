function test_mimo_math()
%TEST_MIMO_MATH  With exact H and no noise the 2x2 canceller returns X.
rng(5, 'twister');
N = 511;  S = 7;
H13 = (randn(N,1) + 1j*randn(N,1));  H24 = H13;
H23 = 0.3*(randn(N,1) + 1j*randn(N,1));  H14 = H23;
X1 = randn(N,S) + 1j*randn(N,S);  X2 = randn(N,S) + 1j*randn(N,S);
Y1 = H13.*X1 + H23.*X2;
Y2 = H14.*X1 + H24.*X2;
[X1h, X2h] = mimo_fde(Y1, Y2, H13, H23, H14, H24, 'cancel');
assert(max(abs(X1h(:) - X1(:))) < 1e-9);
assert(max(abs(X2h(:) - X2(:))) < 1e-9);
end
