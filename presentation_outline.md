# Presentation Outline -- Supervisor Meeting (02/10/2026)

## 1. Problem
- Wireline SerDes data rates have doubled roughly every 4 years (10G -> 112G); next target is >200 Gb/s/lane.
- PAM-4/PAM-8 with ADC-based RX faces bandwidth, FFE/DFE complexity, and FEXT-cancellation problems at these
  speeds (heavy parallel cross-lane FIR filtering).
- OFDM's per-sub-channel frequency-domain equalization offers a much lighter-weight path to both channel
  equalization AND FEXT cancellation (one extra complex multiplier per sub-channel per aggressor, vs. heavy
  parallel FIR filters for PAM).

## 2. Reference architecture
- 2x2 MIMO-OFDM TRX: TX (bits -> QAM -> de-emphasis -> IDFT -> CP -> DAC), channel (main + one FEXT
  aggressor), RX (ADC -> CP removal -> DFT -> 2x2 MIMO FDE -> QAM demod).
- CHEST: two-symbol pilot protocol per cycle, closed-form 2x2 matrix inversion, moving-averaged over many
  cycles for noise robustness.
- [Insert Fig. 1 / Fig. 5 style block diagram from `docs/mathematical_model.md` here.]

## 3. Specifications (from the paper, not invented)
- 224 Gb/s/lane, 64-QAM, N_FFT=1024, N_CP=8, Fs=75.25 GS/s, 37.625 GHz occupied BW, 7-bit DAC/ADC.
- Full parameter table with page citations: `specs/224G_paper_specs.md`.
- What's NOT specified (exact channel S-parameters, pilot sequence, FEC, number of simulated symbols) and
  how we handled it: `docs/assumptions.md`, `docs/open_questions.md`.

## 4. Mathematical model
- Y(k) = H(k) X(k) + N(k), 2x2 H(k) with main (H13,H24) and FEXT (H23,H14) terms.
- FEXT cancellation: Pk = H(k)^-1, one extra complex multiplier per sub-channel.
- CHEST: sum/difference of opposite/same-polarity pilot pairs recovers H13/H23/H14/H24 exactly.
- Full derivation: `docs/mathematical_model.md`.

## 5. MATLAB architecture
- Modular: `tx/`, `channel/`, `rx/`, `mimo/`, `impairments/`, `analysis/`, `experiments/`.
- Every parameter centralized in `config/`; no hard-coded values in signal-processing functions.
- Shared simulation engine (`experiments/link_forward_pass.m`) ensures CHEST pilots and data symbols see an
  identical physical link, as in real hardware.
- Fully reproducible (seeded RNG throughout); validated against theoretical AWGN SER and unit-tested
  block-by-block (channel estimation, FEXT cancellation, OFDM round-trip all verified to machine precision).

## 6. 224 Gb/s results
- TEST 3 (no FEXT cancellation): SER = 4.41e-1, matching the paper's reported 4e-1.
- TEST 4 (with FEXT cancellation, ideal channel knowledge): SER = 0 (exact recovery) -- validates the
  cancellation math itself.
- TEST 6 (full baseline: real CHEST + full converter impairments): SER = 1.39e-1 with cancellation vs.
  4.73e-1 without -- a >3x improvement, correct DIRECTION, but ~4 orders of magnitude off the paper's 1.4e-5
  in absolute terms.
- [Insert: fig06_ber_vs_snr.png, fig07_ser_vs_snr.png, fig08_mimo_comparison.png, fig09_baseline_summary.png,
  constellation figures from `results/224G/figures/`.]

## 7. Limitations
- The gap between our SER (1.39e-1) and the paper's (1.4e-5) is traced to the missing exact channel
  S-parameters -- we only have two numeric anchor points from a plot, not the full measured response.
- High-frequency sub-channels dominate our overall SER (per-sub-channel breakdown available), consistent
  with [DSE]'s explanation of unbalanced quantization SNR across sub-channels when power loading isn't
  perfectly matched to the actual channel.
- Full details: `docs/validation.md`.

## 8. 400 Gb/s investigation
- NOT claiming 400 Gb/s is achieved -- investigating what breaks and what needs to change.
- Swept 9 axes: data rate, sampling rate, ADC/DAC resolution, modulation order, FFT size, channel loss, RX
  noise, jitter, FEXT strength.
- Clear bottlenecks identified: channel loss and required bandwidth/sampling rate scale the fastest with
  data rate; ADC/DAC resolution improvements saturate (noise-limited beyond ~7-8 bits); higher modulation
  order trades bandwidth for much higher BER.
- [Insert: sweepA-J figures from `results/400G/figures/`.]

## 9. Proposed next steps
1. Obtain the actual IEEE 802.3ck channel S-parameter files and replace the synthetic channel model --
   highest-value fix, directly addresses the Section-7 limitation.
2. Re-optimize (or at least re-verify) the TX de-emphasis/power-loading law for whatever channel is
   actually used, rather than assuming the paper's fixed law transfers unchanged.
3. Increase CHEST averaging (L) and data-symbol counts for final, presentation-grade precision numbers
   (current 400G sweep values are reduced-precision for runtime; see `docs/assumptions.md` Section 9).
4. Decide, with the digital/analog sub-teams, which 400G scaling axis (bandwidth vs. modulation order vs.
   FFT size vs. ADC resolution) is most realistic given the 22 nm PDK constraints (`docs/22nm_mapping.md`)
   once PDK data is available.
5. Model the FFT-size/CP-length trade-off more faithfully (scale channel tap count with N_FFT) to better
   reproduce [DSE]'s finding that larger FFT sizes substantially improve BER.
