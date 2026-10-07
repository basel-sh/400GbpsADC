function [h, info] = touchstone_channel(cfg, which)
%TOUCHSTONE_CHANNEL  THRU or FEXT impulse response from measured 4-port
% Touchstone (.s4p) files, e.g. the IEEE P802.3ck Tools & Channels set.
%
% Replaces the synthetic channel of main_channel.m / fext_channel.m when
%   cfg.channel.type = 'touchstone'
%
% Config fields (cfg.channel.touchstone):
%   .thru_file   path of the THRU .s4p
%   .fext_file   path of ONE aggressor FEXT .s4p (e.g. ..._FEXT1.s4p)
%   .port_left   [p1 p2]  ports of the TX-side differential pair (default [1 3])
%   .port_right  [p1 p2]  ports of the RX-side differential pair (default [2 4])
%   .num_taps    FIR length kept (default 512)
%   .main_cursor_idx  0-based tap index where the main peak is placed (default 2)
%
% Steps: (1) read S-parameters, (2) single-ended -> differential Sdd21,
% (3) interpolate on the FFT grid 0..fs/2, (4) IFFT -> real FIR, (5) remove the
% bulk propagation delay (the same shift is applied to THRU and FEXT so their
% relative timing is kept), (6) keep num_taps taps.
%
% Outputs:
%   h    - num_taps x 1 real FIR (physical gain, not normalised)
%   info - struct: loss_dB_fn(f) (measured THRU loss, for plotting),
%          delay_removed_s, energy_in_taps_pct, f_file, f_max_file

if nargin < 2, which = 'main'; end
ts = cfg.channel.touchstone;

% ---- cache: the Touchstone files are large, read/process them only once ----
persistent cache_keys cache_h cache_info
if isempty(cache_keys), cache_keys = {}; cache_h = {}; cache_info = {}; end
ts_key = sprintf('%s|%s|%s|%.6g|%d|%s|%s|%s|%s', which, ts.thru_file, ...
    getfield_def(ts, 'fext_file', ''), cfg.fs, cfg.channel.ir_fft_len, ...
    mat2str(getfield_def(ts, 'port_left', [1 3])), mat2str(getfield_def(ts, 'port_right', [2 4])), ...
    mat2str(getfield_def(ts, 'num_taps', 512)), mat2str(getfield_def(ts, 'main_cursor_idx', 2)));
hit = find(strcmp(cache_keys, ts_key), 1);
if ~isempty(hit)
    h = cache_h{hit}; info = cache_info{hit};
    return;
end
if ~isfield(ts, 'port_left'),       ts.port_left = [1 3];  end
if ~isfield(ts, 'port_right'),      ts.port_right = [2 4]; end
if ~isfield(ts, 'num_taps'),        ts.num_taps = 512;     end
if ~isfield(ts, 'main_cursor_idx'), ts.main_cursor_idx = 2; end

fs = cfg.fs;
N  = cfg.channel.ir_fft_len;
f_grid = (0:N/2).' * (fs / N);

% ---- THRU (always needed: it defines the delay shift) ---------------------
[f_t, S_t] = read_touchstone_4port(ts.thru_file);
H_t = sdd21(S_t, ts.port_left, ts.port_right);
Hg = to_grid(f_t, H_t, f_grid);                 % THRU on the FFT grid
if strcmp(which, 'fext')
    [f_x, S_x] = read_touchstone_4port(ts.fext_file);
    H_x = sdd21(S_x, ts.port_left, ts.port_right);
    Hg_x = to_grid(f_x, H_x, f_grid);
end

% (a) integer-sample bulk delay: put the THRU peak at tap ts.main_cursor_idx
h0 = to_time(Hg, N);
[~, ipk] = max(abs(h0));
shift = (ipk - 1) - ts.main_cursor_idx;
lin = @(x) exp(2j*pi*f_grid*x/fs);              % advance by x samples
Hg = Hg .* lin(shift);
% (b) fractional shift (|d| <= 0.5 sample) so that the Nyquist bin is real
%     without losing magnitude (a real FIR must have a real Nyquist bin).
phiN = angle(Hg(end));
d = phiN/pi - round(phiN/pi);                   % delay in samples, in [-0.5, 0.5]
lag = @(x) exp(-2j*pi*f_grid*x/fs);             % delay by x samples
Hg = Hg .* lag(d);

if strcmp(which, 'fext')
    Hg_x = Hg_x .* lin(shift) .* lag(d);        % same timing as the THRU
    h_full = to_time(Hg_x, N);
else
    h_full = to_time(Hg, N);
end

nt = min(ts.num_taps, N);
h = h_full(1:nt);
if ts.num_taps > N, h(end+1:ts.num_taps) = 0; end
h = h(:);

info = struct();
info.delay_removed_s = (shift + d) / fs;
info.energy_in_taps_pct = 100 * sum(h.^2) / max(sum(h_full.^2), eps);
info.f_file = f_t;
info.f_max_file = f_t(end);
loss_dB = -20*log10(max(abs(H_t), 1e-12));
info.loss_dB_fn = @(f) interp1(f_t, loss_dB, f, 'linear', 'extrap');
cache_keys{end+1} = ts_key; cache_h{end+1} = h; cache_info{end+1} = info;
end

% ---------------------------------------------------------------------------
function v = getfield_def(st, name, def)
if isfield(st, name), v = st.(name); else, v = def; end
end

function H = sdd21(S, pl, pr)
% Differential thru transfer: left pair (a,b) -> right pair (c,d)
a = pl(1); b = pl(2); c = pr(1); d = pr(2);
H = 0.5 * (squeeze(S(:,c,a)) - squeeze(S(:,c,b)) - squeeze(S(:,d,a)) + squeeze(S(:,d,b)));
end

function Hg = to_grid(f_in, H_in, f_grid)
% Interpolate magnitude and unwrapped phase on f_grid (phase zero at DC).
f_in = f_in(:); H_in = H_in(:);
mag = abs(H_in); ph = unwrap(angle(H_in));
fm = f_in(end);
mag_g = interp1([0; f_in], [mag(1); mag], f_grid, 'linear');
ph_g  = interp1([0; f_in], [0; ph],       f_grid, 'linear');
over = f_grid > fm;
if any(over)
    warning('touchstone_channel:band', ...
        'Data ends at %.1f GHz but the model needs up to %.1f GHz: extrapolating.', ...
        fm/1e9, f_grid(end)/1e9);
    i2 = find(f_in > 0.9*fm); i2 = i2(:).';
    p  = polyfit(f_in(i2), 20*log10(mag(i2)), 1);
    mag_g(over) = 10.^(polyval(p, f_grid(over)) / 20);
    q  = polyfit(f_in(i2), ph(i2), 1);
    ph_g(over) = polyval(q, f_grid(over));
end
Hg = mag_g .* exp(1j * ph_g);
end

function h = to_time(Hg, N)
% Hermitian extension 0..fs/2 -> real periodic impulse response
Hg = Hg(:);
Hg(1) = real(Hg(1));
Hg(end) = real(Hg(end));
Hfull = [Hg; conj(Hg(end-1:-1:2))];
h = real(ifft(Hfull, N));
end

function [f, S] = read_touchstone_4port(path)
% Minimal Touchstone v1 reader for 4-port files: "# <unit> S <MA|DB|RI> R <z0>"
txt = fileread(path);
txt = strrep(txt, char(13), '');
lines = strsplit(txt, char(10));
unit = 1; fmt = 'ma'; vals = [];
buf = cell(1, numel(lines)); nb = 0;
for i = 1:numel(lines)
    ln = strtrim(lines{i});
    if isempty(ln) || ln(1) == '!', continue; end
    if ln(1) == '#'
        t = strsplit(lower(strtrim(ln(2:end))));
        switch t{1}
            case 'hz',  unit = 1;
            case 'khz', unit = 1e3;
            case 'mhz', unit = 1e6;
            case 'ghz', unit = 1e9;
        end
        fmt = t{3};
        continue;
    end
    nb = nb + 1; buf{nb} = ln;
end
vals = sscanf(strjoin(buf(1:nb), ' '), '%f');
nblk = floor(numel(vals) / 33);
vals = reshape(vals(1:nblk*33), 33, nblk).';
f = vals(:,1) * unit;
A = vals(:, 2:2:33); B = vals(:, 3:2:33);
switch fmt
    case 'ma', Z = A .* exp(1j*deg2rad_(B));
    case 'db', Z = 10.^(A/20) .* exp(1j*deg2rad_(B));
    otherwise, Z = A + 1j*B;
end
S = zeros(nblk, 4, 4);
for r = 1:4
    for c = 1:4
        % Touchstone v1 four-port data is row-major (unlike two-port data).
        S(:, r, c) = Z(:, (r-1)*4 + c);
    end
end
end

function r = deg2rad_(d)
r = d * pi / 180;
end
