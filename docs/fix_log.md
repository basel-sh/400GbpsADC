# Fix log: what was wrong in the 224G code, what was changed, and how it was checked

Scope: the 224 Gb/s baseline (`main_224G.m` and everything it calls). The 400G files were only touched where a
renamed config field required it.

**Verification status (important).** MATLAB/Octave was not available while these fixes were written. The
changes were (a) checked statically (a script that verifies block balance and the argument/output counts of every
call against every function signature; it reports 0 problems for the 47 `.m` files and was confirmed to
detect deliberately broken test files), (b) mirrored line-by-line in an independent Python re-implementation of
the same equations, which reproduced the original results before the fixes (TEST 3, TEST 4, TEST 6 band trend)
and gives the numbers below after them. **Run `tests/run_all_tests.m` and `main_224G.m` and use your own numbers.**

## The two errors that mattered

### Bug 1: converter gains recomputed on every call (error floor of -22.4 dB)
* **Where:** `tx/dac_model.m`, `rx/adc_model.m` (scale = target_rms/rms_in per block), used by
  `experiments/link_forward_pass.m`.
* **Why wrong:** the CHEST estimator (paper eqs. 11-12) needs the SAME scalar gain on both pilot symbols. The two
  pilot symbols reach the ADC with RMS 0.0247 V ((S,-S): FEXT subtracts) and 0.0288 V ((S,+S): adds), so the VGA
  applied 4.33 and 3.72. With g_m=(g1+g2)/2 and d=(g2-g1)/2 the estimates become H23_est = g_m*H23 + d*H13, i.e. 7.6 %
  of the main channel leaks into the FEXT estimate: 20*log10(0.076) = -22.4 dB, measured -22.4 dB with all noise,
  jitter, quantization and clipping off. A real AGC loop is far slower than a 2-symbol pilot sequence.
* **Fix:** `dac_model`/`adc_model` take an optional frozen gain; `link_forward_pass` accepts `opts.agc` and
  `opts.noise` and reports the gains/noise it used; `run_224G_test` measures them once on 100 data-like symbols
  and passes the frozen values to the pilot phase and the data phase.
* **Evidence:** noise-free whole-loop EVM floor 7.7 % -> 0.76 % (-42 dB; residual = CP leakage).

### Bug 2: clipping ratio misread (about 2 dB lost per converter)
* **Where:** `config/config_224G.m` + `dac_model.m`/`adc_model.m` (10^(dB/20) used as beta/RMS).
* **Why wrong:** [FEXT] gives threshold / MEAN MAGNITUDE (12.6, 13.4 dB). [DSE] defines R_clip = threshold / RMS =
  3.41 / 3.73. For a Gaussian-like OFDM signal E|x| = sigma*sqrt(2/pi): 10^(12.6/20)*sqrt(2/pi) = 3.40,
  10^(13.4/20)*sqrt(2/pi) = 3.73. The code used 4.27 / 4.68: DAC output 2 dB too small relative to the 1.8 mV
  noise, SQNR 34.3/33.5 dB instead of 36.3/35.5 dB.
* **Fix:** new `impairments/clip_ratio_to_rms.m`, `cfg.clip_ratio_is_mean_abs = true`.

## Smaller errors fixed

| # | issue | file(s) | fix |
|---|---|---|---|
| 3 | Jitter seeds constant (1000/2000): same jitter on both lanes and on every pilot cycle | `link_forward_pass`, `dac_model`, `adc_model` | distinct seed per call, lane and stage (`jitter_seed` argument) |
| 4 | `snr_override_dB` not applied to the pilots (pilots saw 1.8 mV, data the swept noise) | `run_224G_test` | noise level measured once and frozen for pilots and data (`opts.noise`) |
| 5 | Quantizer documented as mid-rise but implemented mid-tread | `quantization_model.m` | true mid-rise (floor, (code+0.5)*LSB; 2^N symmetric levels, no zero level) |
| 6 | `cfg.deemph.gain_dB` handle captured the values at creation: changing `k1_dB` later had no effect | `deemphasis_gain_vector.m`, `config_224G.m` | gain computed from `k1_dB`/`k511_dB` directly |
| 7 | `ser_per_subchannel` used lane 1 only while the headline SER averages both lanes | `run_224G_test.m` | mean of both lanes |
| 8 | Dead/misnamed config fields (`M_symbol_period`, `use_ctle`, `num_lanes`, `noise.type`; `random_phase_seed` is the pilot seed) | `config_224G.m`, `estimate_mimo_channel.m`, `experiment_400G_sweep.m` | removed / renamed `pilot_seed` |
| 9 | TEST 1 reported "max gap" mixing resolvable and zero-error points (8.5 decades) and plotted zeros at 1e-16 | `experiment_ideal_channel.m` | compares only points with >= 20 expected errors; zeros drawn at a labelled floor |
| 10 | Bar chart TEST 2-4 showed no bars for the zero values | `experiment_fext.m` | floor + printed values |
| 11 | TEST 6 constellation mixed all 511 tones (unreadable square) | `experiment_224G.m` | one tone at a time (3 figures) |
| 12 | Channel figure mixed the analytic main law and the FEXT FIR | `plot_channel_response.m` | both curves from the simulation FIRs |
| 13 | SNR figures labelled "RX input SNR" (it is total power over all tones) and titled "Fig. 6/7/8" (paper numbering differs) | `experiment_224G.m` | relabelled; comparison bar chart now shows the paper values next to the model |
| 14 | `ber_naive(i) = rc.ber;` leftover | `experiment_224G.m` | removed |
| 15 | `.mat` files saved in Octave text format (MATLAB cannot `load` them) | `main_224G.m`, `experiment_400G_sweep.m` | `-v7` |
| 16 | Docs said the gap was due to the unavailable channel; "TEST 1 ~ 0 decades"; "pilots and data see the same chain" | `docs/*.md`, `specs`, `presentation_outline.md` | rewritten (validation.md, assumptions.md, ...) |

## Deliberately NOT changed (and why)

* **Global RNG re-seeding** (`generate_bits`, `add_noise`, `jitter_model` call `rng(seed)`): deterministic and
  working; replacing it (RandStream is not available in Octave) risks breaking Octave compatibility for little gain.
* **Channel FIR recomputed on every link pass:** performance only; caching has to key on every channel
  parameter (sweeps change them). Left as is.
* **Zero-forcing equalizer, smooth synthetic FEXT, 64-QAM without bit-loading:** modelling choices of the
  reproduction (the paper uses ZF and uniform QAM); improvements belong to the next phase.
* **The paper's absolute 1.4e-5:** NOT reached (see below). Nothing was tuned to force it.

## Result after the fixes (independent Python re-implementation; your MATLAB numbers will differ in the last digits)

500 data symbols, CHEST L = 100, 3 seeds (spread about +-5 %):

| configuration | SER (cancel) | k 1-50 | k 451-511 |
|---|---|---|---|
| original code | 1.26e-1 | 4.4e-2 | 2.9e-1 |
| fixed, noise 1.8 mV at RX input (default) | 2.7e-2 | 1e-3 | 1.2e-1 |
| fixed, noise 1.8 mV at ADC input (`cfg.noise.reference='adc_input'`) | 7.8e-4 | < 1e-4 | 5e-3 |

SNR sweep after the fix (noise frozen, total RX-input SNR, SER cancel / naive):
10 dB 0.72/0.74, 16 dB 0.40/0.56, 20 dB 0.18/0.49, 24 dB 4.9e-2/0.46, 28 dB 6.7e-3/0.45, 30 dB 1.9e-3/0.45
(original code at 30 dB: 4.0e-2: the noise-independent floor of Bug 1 is gone).

Remaining gap to the paper: the paper's 1.4e-5 needs a mean per-tone SNR near 26 dB. With the noise at the
RX input the model reaches ~22 dB; with the noise at the ADC input ~25 dB. The paper does not say where the
1.8 mV acts ([FEXT]: "RX input"; [DSE]: "on the AFE") and its measured channel is not available, so this
is reported as an open question, not tuned away.
