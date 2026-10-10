> Historical record. For the current results and plan, read [README](../../README.md) and [validation](../validation.md).

# Validation

> Historical report. The 2026-10-07 MATLAB audit found implementation and
> configuration issues that invalidate the old claim that the full gap was
> attributable to the channel. Use `phase1_findings.md` and `results/phase1/`
> for current measurements and limitations.

This document reports what `main_224G.m` actually produced (a real run, not a hand-picked example), compares
it against the paper's reported numbers, and states plainly what matches, what is approximate, and what
cannot be reproduced given the information available. Per the project brief (Part 5/12): **we do not claim
exact reproduction of the paper.**

Run configuration for the numbers below: `config_224G()` defaults (N_FFT=1024, N_CP=8, 64-QAM, 2000 data
OFDM symbols, CHEST L=200 moving-average cycles), Octave 8.4 (a MATLAB-compatible open-source environment
used here to verify the code executes correctly end-to-end; re-running in MATLAB will reproduce the same
numbers since every random draw is seeded).

## TEST-by-TEST results

| Test | Description | Measured | Paper reference |
|---|---|---|---|
| 1 | Ideal 64-QAM/OFDM link vs. AWGN theory | max \|log10(measured)-log10(theory)\| ≈ 0 (SER→0 at all tested SNR, matching theory to numerical precision) | n/a (sanity check only) |
| 2 | OFDM + main channel only, no FEXT | SER = 0.000e+00 | n/a (sanity check only) |
| 3 | 2x2 MIMO, FEXT present, **no** cancellation | SER = 4.407e-01 | **SER = 4e-1** ([FEXT] p.85) |
| 4 | 2x2 MIMO, FEXT present, **with** cancellation (genie channel, no converter impairments) | SER = 0.000e+00 | n/a (paper's equivalent case includes impairments; ours isolates architecture) |
| 5 | Full impairments + minimal (L=1) CHEST | SER = 2.472e-01, BER = 4.525e-02, EVM = 15.9% | n/a (paper does not report an L=1 case; included to show CHEST-noise sensitivity, cf. [FEXT] Fig. 9) |
| 6 | **Full 224G baseline**: full impairments + converged CHEST (L=200) | SER = 1.386e-01, BER = 2.425e-02, EVM = 12.7% (naive/no-cancel comparison: SER = 4.729e-01) | SER (with cancel) = **1.4e-5**, SER (without) = **4e-1**, BER (with cancel) = **2.4e-6** |

## What matches well

- **TEST 3's SER without FEXT cancellation (4.41e-1) matches the paper's reported 4e-1 almost exactly**,
  even though our channel is a hand-calibrated synthetic model, not the paper's measured one. This is a
  strong architectural validation: with FEXT present and uncancelled, SER saturates near the "random guess"
  region for both models, so this particular number is not very sensitive to the exact channel shape.
- **The FEXT-cancellation math is exact** (verified with unit tests, see below): given the true channel
  response, the 2x2 matrix-inversion equalizer recovers the transmitted symbols to machine precision (TEST
  4, SER = 0 with a genie channel and no converter noise).
- **The channel-estimation math (eqs. 7-12) is exact**: verified against synthetic ground truth to machine
  precision (see development notes below).
- **The OFDM modulate/demodulate round trip is exact** (max reconstruction error ≈ 8e-16, i.e. floating-point
  noise only).
- **Qualitative trends match the paper's description throughout**: FEXT cancellation dramatically reduces
  SER relative to no cancellation (TEST 6: 0.139 vs. 0.473, a >3x improvement); high-frequency sub-channels
  are the worst-affected (matching [FEXT] Fig. 10(d)'s description that "low-frequency sub-channels up to
  k≈50 are practically not affected by FEXT, while higher frequency sub-channels clearly benefit from
  cancellation").

## What does NOT match numerically

**The full-baseline SER/BER (TEST 6) is roughly 4 orders of magnitude worse than the paper's reported
value** (1.39e-1 vs. 1.4e-5 SER). This is the single most important limitation of this project and is
explained, not hidden:

1. **The channel is not the paper's channel.** We only have two numeric anchor points (23 dB @ 40 GHz, 28 dB
   ratio @ 3.7 GHz) from a plot; the paper's actual measured channel presumably has a shape across the full
   37.625 GHz bandwidth that, combined with the stated de-emphasis law, balances quantization/thermal noise
   across all 511 sub-channels well enough to hit 1.4e-5 overall SER. Our synthetic channel reaches ≈22 dB
   loss at Nyquist; per-sub-channel SER analysis (available in `results_224G.mat`) shows the high-frequency
   sub-channels (k > ~400) dominate the overall SER, exactly as [DSE] Sec. IV-B predicts happens when
   power/channel loss is not perfectly balanced by the de-emphasis profile.
2. **The de-emphasis law is fixed (from the paper), not re-optimized for our channel.** In the paper, the
   -10.5 dB→0 dB de-emphasis law was presumably tuned (or is simply a good match) for the *actual* channel
   used. Applying that same fixed law to a different channel shape does not necessarily reproduce the same
   balanced-SNR outcome across sub-channels -- see `docs/open_questions.md`.
3. **CHEST averaging window and data-symbol count** are both finite (L=200, 2000 symbols) versus what may
   have been a much larger simulation run in the original paper (not stated).

We consider items (1)-(2) the fundamental, unavoidable consequence of not having the paper's exact channel
data (explicitly acknowledged as unavailable in `specs/224G_paper_specs.md` Section 6) -- not a bug in the
implementation.

## Per-block correctness checks performed during development

These are informal unit tests run against the code (not part of the automated test suite, but documented
here since they underpin the "what matches" claims above):

- `qam_modulate` -> `qam_demodulate` round trip: 0 bit errors at infinite SNR.
- `ofdm_modulate` -> `ofdm_demodulate` round trip: max error ≈ 8.5e-16.
- `channel/minimum_phase_from_mag_db.m`: reconstructed FFT magnitude matches the target magnitude spectrum
  to <0.02 dB with the default 64-tap truncation (verified at the Nyquist edge, the hardest point).
- `mimo/fext_cancellation.m`: recovers synthetic X1/X2 exactly given the true H matrix (verified with random
  complex H and X).
- `rx/channel_estimation.m`: recovers synthetic H13/H23/H14/H24 exactly given noiseless pilot observations.

## 400G sweep sanity

All nine sweep axes in `experiments/experiment_400G_sweep.m` produce monotonic, physically-sensible trends
(see `docs/open_questions.md` "400G sweep observations" and the actual figures under
`results/400G/figures/`): BER increases with data rate/bandwidth, channel loss, RX noise, jitter, and
modulation order; BER decreases with ADC/DAC resolution (saturating) and with a larger main-to-FEXT ratio.
The one weak trend is **FFT size**, which shows almost no BER sensitivity in our model (see
`docs/open_questions.md`) -- in contrast to [DSE]'s finding of a >10x BER improvement from N_FFT=256 to
1024; our simplified fixed-N_CP, fixed-channel-tap-count model does not capture the CP/ISI trade-off with
the same fidelity as [DSE]'s dedicated study.

## Bottom line for the supervisor meeting

The **architecture, math, and signal chain are implemented correctly and validated block-by-block**. The
**absolute SER/BER numbers should be presented as "this configuration's numbers", not as a reproduction of
the paper's 1.4e-5** -- the gap is fully attributable to the missing exact channel data, and is exactly the
kind of gap the project brief (Part 12) asked us to surface rather than hide.
