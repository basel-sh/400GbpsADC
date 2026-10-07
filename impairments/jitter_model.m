function x_jittered = jitter_model(x, fs, rms_UI, seed_offset, method)
%JITTER_MODEL  Apply random sampling-instant jitter to a time-domain signal.
%
% [A] The paper specifies "1% UI root-mean-square (RMS) TX/RX sampling
% jitter" ([FEXT] p.84, Sec. V). Since the exact jitter PROCESS (white vs.
% correlated phase noise) is NOT specified beyond an RMS figure, this is
% modeled as i.i.d. Gaussian per-sample timing error with the given RMS,
% expressed in unit intervals (UI = 1/fs) -- flagged as an assumption [C]
% in specs/224G_paper_specs.md Section 10.
%
% Implementation: the continuous-time waveform is reconstructed via cubic
% spline interpolation of the ideal (jitter-free) samples, then re-sampled
% at the jittered time instants t_n = n/fs + dt_n, dt_n ~ N(0, (rms_UI/fs)^2).
%
% Inputs:
%   x           - N x M matrix, each column a signal sampled at fs (Hz)
%   fs          - nominal sampling rate (Hz)
%   rms_UI      - RMS jitter as a fraction of one unit interval (e.g. 0.01)
%   seed_offset - integer added to the current rng state offset for
%                 reproducibility across calls (optional, default 0)
%
% Output:
%   x_jittered - same size as x, resampled at jittered time instants

if nargin < 4
    seed_offset = 0;
end
if nargin < 5, method='spline'; end
if rms_UI <= 0
    x_jittered = x;
    return;
end

[N, M] = size(x);
UI = 1/fs;
sigma_t = rms_UI * UI;

x_jittered = zeros(N, M);
t_nominal = (0:N-1).';

for m = 1:M
    % Reproducible per-column jitter draw (rng() reseed, portable to both
    % MATLAB and Octave, unlike RandStream which Octave does not implement)
    rng(mod(seed_offset + m, 2^31 - 1), 'twister');
    dt = sigma_t * randn(N, 1) / UI; % in samples
    t_jit = t_nominal + dt;
    % Cubic spline interpolation of the (band-limited-ish) OFDM waveform
    % at the jittered sample instants. Edge samples are held (extrap 'nearest'
    % analogue) to avoid edge artifacts on the short block.
    if strcmp(method,'spectral_linear')
        % First-order bandlimited timing perturbation, x(t+dt)=x+dt*x'.
        % Nyquist derivative is set to zero for a real sampled waveform.
        k=[0:floor((N-1)/2), -floor(N/2):-1]';
        if mod(N,2)==0,k(N/2+1)=0;end
        dx=real(ifft(fft(x(:,m)).*(2j*pi*k/N)));
        x_jittered(:,m)=x(:,m)+dt.*dx;
    else
        x_jittered(:, m) = interp1(t_nominal, x(:, m), t_jit, 'spline', 'extrap');
    end
end

end
