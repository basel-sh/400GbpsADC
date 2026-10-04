# Validation

This document reports what `main_224G.m` actually produced (a real run, not a hand-picked example), compares
it against the paper's reported numbers, and states plainly what matches, what is approximate, and what
cannot be reproduced given the information available. Per the project brief (Part 5/12): **we do not claim
exact reproduction of the paper.**

Run configuration for the numbers below: `config_224G()` defaults (N_FFT=1024, N_CP=8, 64-QAM, 2000 data
OFDM symbols, CHEST L=200 moving-average cycles), Octave 8.4 (a MATLAB-compatible open-source environment
used here to verify the code executes correctly end-to-end; re-running in MATLAB will reproduce the same
numbers since every random draw is seeded).

> **Status of the numbers (read this first).** The TEST table below reports the run of the *original*
> code (Octave 8.4), kept as the "before" record (its figures are in `results_old_pre_fix/`). That code had
> two modelling errors that are corrected in this version (`docs/fix_log.md`). I could not execute
> MATLAB/Octave while making the corrections, so the "after the fixes" numbers in this file come from an
> independent Python re-implementation of the same equations and are labelled as such. **Re-run
> `main_224G.m` and `tests/run_all_tests.m` and replace them with your own numbers before presenting.**

## TEST-by-TEST results (original code, before the fixes)

| Test | Description | Measured | Paper reference |
|---|---|---|---|
| 1 | Ideal 64-QAM AWGN vs. theory (1.02 M symbols) | within 0.12 decades of theory at every SNR where the sample can resolve it (Es/N0 10-26 dB, SER >= 2e-5); at 28 and 30 dB no error is observed (theory 7e-8 and 9e-12) | n/a (sanity check only) |
| 2 | OFDM + main channel only, no FEXT | SER = 0.000e+00 | n/a (sanity check only) |
| 3 | 2x2 MIMO, FEXT present, **no** cancellation | SER = 4.407e-01 | **SER = 4e-1** ([FEXT] p.85) |
| 4 | 2x2 MIMO, FEXT present, **with** cancellation (genie channel, no converter impairments) | SER = 0.000e+00 | n/a (paper's equivalent case includes impairments; ours isolates architecture) |
| 5 | Full impairments + minimal (L=1) CHEST | SER = 2.472e-01, BER = 4.525e-02, EVM = 15.9% | n/a (cf. [FEXT] Fig. 9) |
| 6 | Full 224G baseline: full impairments + converged CHEST (L=200) | SER = 1.386e-01, BER = 2.425e-02, EVM = 12.7% (no-cancel: SER = 4.729e-01) | SER (with cancel) = **1.4e-5**, SER (without) = **4e-1**, BER (with cancel) = **2.4e-6** |

TESTS 1-4 do not use the converters and are unchanged by the fixes.

## What matches well

- **TEST 3's SER without FEXT cancellation (4.41e-1) matches the paper's reported 4e-1.** With FEXT present
  and uncancelled, 64-QAM is close to random guessing, so this number is not very sensitive to the exact
  channel shape; it validates the architecture, not the channel.
- **The FEXT-cancellation math is exact**: given the true channel, the 2x2 inverse recovers the symbols (TEST 4:
  SER = 0 in 2.04 M symbols; `tests/test_mimo_math.m`).
- **The channel-estimation equations (7-12) are exact** when both pilot symbols see the same gain.
- **The OFDM round trip is exact** (`tests/test_ofdm_roundtrip.m`).
- **Qualitative trends match the paper**: cancellation reduces SER dramatically; low sub-channels (k up to
  ~50) are practically unaffected by FEXT while higher ones need the cancellation ([FEXT] Fig. 10(d)).

## What did NOT match, and why (corrected diagnosis)

The original TEST 6 was ~4 orders of magnitude worse than the paper (1.39e-1 vs 1.4e-5). The original version
of this document attributed that to the unavailable measured channel. **That diagnosis was wrong for the
largest part of the gap**, as the per-sub-channel results show: even for k < 50, where the channel loses
< 4 dB and FEXT is >= 28 dB down, the SER was 6.3 %. Two modelling errors were found (details and evidence
in `docs/fix_log.md`):

1. **Converter gains were re-normalized on every call.** The DAC scale and the RX VGA gain followed the RMS
   of each individual block. The two CHEST pilot symbols reach the ADC with different power (FEXT subtracts in
   one, adds in the other), got VGA gains 4.33 vs 3.72, and the sum/difference estimator leaked 7.6 % of the
   main channel into the FEXT estimate: an error floor of 20*log10(0.076) = -22.4 dB, independent of noise.
   Fixed: gains are measured once on a data-like block and frozen (`run_224G_test.m`, `link_forward_pass.m`).
2. **Clipping ratios were misread.** [FEXT] gives threshold / MEAN MAGNITUDE (12.6, 13.4 dB); [DSE] defines
   R_clip = threshold / RMS and uses 3.41 and 3.73. For a Gaussian-like signal these are the same numbers
   (10^(12.6/20)*sqrt(2/pi) = 3.40). The code used 4.27 / 4.68. Fixed (`impairments/clip_ratio_to_rms.m`).

### After the fixes (independent Python re-implementation; replace by your MATLAB re-run)

| configuration | SER (with cancellation) | low k (1-50) | high k (451-511) |
|---|---|---|---|
| original code | 1.26e-1 | 4.4e-2 | 2.9e-1 |
| fixes, noise 1.8 mV at the RX input (default) | 2.7e-2 | 1e-3 | 1.2e-1 |
| fixes, noise 1.8 mV at the ADC input (`cfg.noise.reference = 'adc_input'`) | 7.8e-4 | < 1e-4 | 5e-3 |

(500 symbols, L = 100, 3 seeds each; the spread between seeds was +-5 %.)

### What is still different from the paper

The paper's 1.4e-5 is not reached. In the corrected model the remaining error is a genuine SNR-budget
question: the mean per-tone SNR is ~22 dB (24 dB at low k, 18 dB at the top) while 64-QAM needs 26 dB for 1.4e-5.
Candidate explanations that this repository cannot settle from the paper text:

- **Where the 1.8 mV acts.** [FEXT] says "RX input random noise", [DSE] says "on the AFE". Putting it at the
  ADC input (after the VGA) is a ~1.5-decade difference (table above). Both are available in the config.
- **The channel.** The paper uses a measured IEEE 802.3ck channel; ours is synthetic (two anchor points).
- **Finite simulation length** (here 2000 symbols; [DSE] used 48 Mbit).

An optimizer-style re-balancing of the de-emphasis (flat per-tone SNR) did not improve the SER in the
corrected model, so the paper's -10.5 dB -> 0 dB law is not the limiting factor.

## Per-block correctness checks

Automated now in `tests/` (run `run_all_tests`): quantizer (mid-rise, 2^bits symmetric levels), clip-ratio
conversion (3.40 / 3.73) and DAC output ratio, de-emphasis law, OFDM round trip, 2x2 canceller exactness,
frozen-gain consistency between pilots and data, and a **noise-free whole-loop floor test** (converters in the
path, noise/jitter/quantization/clipping off: EVM must be < 2 %; the original code gave ~7.6 %).
Informal checks from development: `qam_modulate` <-> `qam_demodulate` round trip; the minimum-phase FIR
reproduces the target magnitude to < 0.02 dB; `channel_estimation.m` recovers H exactly for noiseless pilots.

## 400G sweep

The nine 400G sweeps in `experiments/experiment_400G_sweep.m` were produced with the *original* code and
were all in the failure regime (best BER 1.8e-2), so they say little about which parameter limits a 400G link.
Re-run them after the 224G baseline is validated; also see `docs/open_questions.md`.

## Bottom line for the supervisor meeting

The architecture, the math and the signal chain are implemented correctly and validated block by block. The
original TEST 6 gap was mostly caused by two identifiable modelling errors (now fixed); the remaining gap is a
noise-reference / channel question that should be presented as open, not as a reproduction of the paper's
1.4e-5.
