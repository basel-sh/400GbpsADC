function result = run_224G_test(cfg, test_opts)
%RUN_224G_TEST  Single-configuration end-to-end run: generates data bits,
%QAM-modulates two independent lanes, estimates the MIMO channel via CHEST
%pilots through the actual link, equalizes the data symbols, demodulates,
%and reports BER/SER/EVM plus diagnostic signals for plotting. This is the
%shared engine behind experiments/experiment_*.m (TESTs 1-6) and main_224G.m.
%
% Inputs:
%   cfg       - config struct (config_224G / config_400G)
%   test_opts - struct, all fields optional:
%       .enable_fext         (default true)  - physical FEXT coupling present
%       .apply_impairments   (default true)  - DAC/ADC clip+quant+jitter+noise
%       .enable_channel      (default true)  - physical channel present
%       .fde_mode            (default 'cancel') - 'cancel' or 'naive' (see mimo_fde.m)
%       .snr_override_dB     (default [])    - forces a specific RX SNR
%       .use_genie_channel   (default false) - if true, skip CHEST and use the
%                            EXACT synthetic channel's per-subcarrier response
%                            (oracle equalizer) instead of the pilot-estimated
%                            one -- useful to isolate architecture (FEXT
%                            cancellation math) from CHEST estimation error.
%                            NOTE: only meaningful with apply_impairments =
%                            false. With impairments the effective channel
%                            also contains the (frozen) DAC output gain and
%                            RX VGA gain, which a genie/oracle channel does
%                            not know; the pilot-based CHEST captures them
%                            automatically because pilots pass through the
%                            same DAC/ADC stages. Combining
%                            use_genie_channel=true with apply_impairments=
%                            true throws an error -- use the (default)
%                            pilot-based CHEST path instead when impairments
%                            are enabled (see rx/estimate_mimo_channel.m).
%       .seed_offset         (default 0)     - reproducibility offset
%
% Output: result struct with fields
%   ber, ser, evm_percent, ber_no_fext_cancel (naive-FDE reference SER for
%   comparison), tx_syms1/2, rx_syms1/2 (equalized), H13/H23/H14/H24
%   (channel estimate used), ser_per_subchannel (N_used x 1), chest_diag

if nargin < 2, test_opts = struct(); end
o = default_opts(test_opts);

if o.use_genie_channel && o.apply_impairments
    error('run_224G_test:unsupportedCombo', ...
        ['use_genie_channel=true is not supported together with ', ...
         'apply_impairments=true (the DAC/ADC gains are part of the ', ...
         'effective channel and unknown to an oracle equalizer). Use the ', ...
         'default pilot-based CHEST (use_genie_channel=false) when ', ...
         'impairments are enabled.']);
end

Nused = cfg.ofdm.N_used;
bps = cfg.mod.bits_per_sym;
Nsym = cfg.sim.num_ofdm_symbols;
M = cfg.mod.order;

nbits_per_lane = Nused * bps * Nsym;

bits1 = generate_bits(nbits_per_lane, cfg.sim.rng_seed + o.seed_offset*2 + 1);
bits2 = generate_bits(nbits_per_lane, cfg.sim.rng_seed + o.seed_offset*2 + 2);

sym1_flat = qam_modulate(bits1, M);
sym2_flat = qam_modulate(bits2, M);

X1 = reshape(sym1_flat, Nused, Nsym);
X2 = reshape(sym2_flat, Nused, Nsym);

link_opts = struct('enable_fext', o.enable_fext, ...
                    'apply_impairments', o.apply_impairments, ...
                    'enable_channel', o.enable_channel, ...
                    'snr_override_dB', o.snr_override_dB, ...
                    'seed_offset', o.seed_offset*10 + 1);

% --- Analog gain / noise calibration (AGC) ---------------------------------
% A real transmitter/receiver has FIXED analog gains: the DAC output gain and
% the RX VGA gain are set by a slow loop and do not follow individual OFDM
% symbols. Earlier versions re-normalized the DAC and the VGA on EVERY call,
% so the two CHEST pilot symbols ((S,-S) and (S,+S), which reach the ADC with
% different power) were amplified by different gains (4.33 vs 3.72 measured),
% which leaks ~7.6% of the main channel into the FEXT estimate (an error floor
% of about -22 dB). Here the gains (and the noise level) are measured ONCE on
% a data-like block and then frozen for the pilots and for the data.
agc = [];
noise_frozen = [];
if o.apply_impairments && o.enable_channel
    ncal = min(100, Nsym);
    cal_opts = link_opts;
    cal_opts.seed_offset = link_opts.seed_offset + 500;
    [~, ~, cal_diag] = link_forward_pass(X1(:, 1:ncal), X2(:, 1:ncal), cfg, cal_opts);
    agc = cal_diag.agc;
    noise_frozen = cal_diag.noise;
end
link_opts.agc = agc;
link_opts.noise = noise_frozen;

% --- Channel estimation ---
chest_diag = struct();
% TX de-emphasis is applied to BOTH lanes before either the physical
% channel or nothing at all (see link_forward_pass.m); a real receiver's
% CHEST inherently estimates the COMBINED (de-emphasis * channel)
% response since pilots pass through de-emphasis too. The "genie"/oracle
% branches below must therefore fold in the same known de-emphasis gain
% so they are equalizing the same effective channel a real CHEST would see.
deemph_gain = deemphasis_gain_vector(cfg);
if ~o.enable_channel
    % No physical channel applied in link_forward_pass -> the "genie"
    % channel the equalizer should assume is just the de-emphasis gain
    % (no channel attenuation, no crosstalk), matching TEST 1's ideal-link
    % intent.
    H13 = deemph_gain; H24 = deemph_gain;
    H23 = zeros(Nused,1); H14 = zeros(Nused,1);
elseif o.use_genie_channel
    [h_main, main_info] = main_channel(cfg);
    [h_fext, ~] = fext_channel(cfg, main_info);
    Hf_main = fft(h_main, cfg.channel.ir_fft_len);
    Hf_fext = fft(h_fext, cfg.channel.ir_fft_len);
    bin_idx = round(cfg.ofdm.k_idx * cfg.channel.ir_fft_len / cfg.ofdm.N_FFT) + 1;
    bin_idx = min(max(bin_idx, 1), cfg.channel.ir_fft_len);
    H13 = deemph_gain .* Hf_main(bin_idx); H24 = deemph_gain .* Hf_main(bin_idx);
    H23 = deemph_gain .* Hf_fext(bin_idx); H14 = deemph_gain .* Hf_fext(bin_idx);
    if ~o.enable_fext
        H23 = zeros(Nused,1); H14 = zeros(Nused,1);
    end
else
    chest_opts = struct('enable_fext', o.enable_fext, ...
                         'apply_impairments', o.apply_impairments, ...
                         'enable_channel', o.enable_channel, ...
                         'agc', agc, 'noise', noise_frozen);
    [H13, H24, H23, H14, chest_diag] = estimate_mimo_channel(cfg, chest_opts);
    if ~o.enable_fext
        % No physical FEXT present -> naive/cancel equalizers should both
        % reduce to the single-lane case; force H23/H14 estimate to be used
        % as-is (they will be ~0 since there's no coupling to estimate).
    end
end

% --- Data symbols through the link ---
[Y1, Y2] = link_forward_pass(X1, X2, cfg, link_opts);

% --- Equalization ---
[Xhat1, Xhat2] = mimo_fde(Y1, Y2, H13, H23, H14, H24, o.fde_mode);

% --- Also compute the OTHER FDE mode for the headline comparison plot ---
other_mode = 'naive'; if strcmp(o.fde_mode, 'naive'), other_mode = 'cancel'; end
[Xhat1_other, Xhat2_other] = mimo_fde(Y1, Y2, H13, H23, H14, H24, other_mode);

% --- Demodulate & score ---
rx_bits1 = qam_demodulate(Xhat1(:), M);
rx_bits2 = qam_demodulate(Xhat2(:), M);

[ber1] = calculate_ber(bits1, rx_bits1);
[ber2] = calculate_ber(bits2, rx_bits2);
ber = mean([ber1, ber2]);

[ser1] = calculate_ser(X1(:), Xhat1(:), M);
[ser2] = calculate_ser(X2(:), Xhat2(:), M);
ser = mean([ser1, ser2]);

ser_other1 = calculate_ser(X1(:), Xhat1_other(:), M);
ser_other2 = calculate_ser(X2(:), Xhat2_other(:), M);
ser_other = mean([ser_other1, ser_other2]);

evm1 = calculate_evm(X1(:), Xhat1(:));
evm2 = calculate_evm(X2(:), Xhat2(:));

% Per-sub-channel SER (mean of lane 1 and lane 2, consistent with the
% headline SER), for the Fig.-10(d)-style plot
ser_per_subchannel = zeros(Nused, 1);
for k = 1:Nused
    ser_per_subchannel(k) = mean([calculate_ser(X1(k,:), Xhat1(k,:), M), ...
                                  calculate_ser(X2(k,:), Xhat2(k,:), M)]);
end

result = struct();
result.ber = ber;
result.ser = ser;
result.ser_other_mode = ser_other; % SER of the "other" FDE mode, same data
result.other_mode = other_mode;
result.evm_percent = mean([evm1, evm2]);
result.tx_syms1 = X1(:); result.tx_syms2 = X2(:);
result.rx_syms1 = Xhat1(:); result.rx_syms2 = Xhat2(:);
result.rx_syms1_other = Xhat1_other(:); result.rx_syms2_other = Xhat2_other(:);
result.H13 = H13; result.H23 = H23; result.H14 = H14; result.H24 = H24;
result.ser_per_subchannel = ser_per_subchannel;
result.chest_diag = chest_diag;
result.agc = agc;                  % frozen converter gains used (empty if no impairments)
result.noise_used = noise_frozen;  % frozen noise level used
result.opts = o;

end

function o = default_opts(o)
d = struct('enable_fext', true, 'apply_impairments', true, ...
           'enable_channel', true, 'fde_mode', 'cancel', ...
           'snr_override_dB', [], 'use_genie_channel', false, ...
           'seed_offset', 0);
flds = fieldnames(d);
for i = 1:numel(flds)
    f = flds{i};
    if ~isfield(o, f)
        o.(f) = d.(f);
    end
end
end
