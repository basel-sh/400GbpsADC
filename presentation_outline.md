# Doctor meeting: 400 Gb/s/lane modeling results (8 October 2026)

Use the current [verification brief](docs/400G_verification_for_doctor.md)
and CSV evidence in `results/400G_verification/`. This is a phase-one
behavioral feasibility discussion. No PDK or transistor implementation has
been verified. DAC/ADC clipping remains **12.6/13.4 dB** throughout.

## Slide 1 — What we have demonstrated

- 224G framing works at 223.56 Gb/s/lane; the paper's exact error result and
  channel/noise conditions are not reproduced.
- The current model supports a conditional 400G 64-QAM candidate.
- Today's decision: approve checking the candidate hardware requirements
  against real channel data and available CMOS circuit/process data.

Say: "This is a verified operating point inside our behavioral model.
Our next task is to establish whether actual hardware can supply its budgets."

## Slide 2 — Two ways to reach the rate

`R = 511 * log2(QAM) * Fs / 1032`

| Architecture | Sampling rate | Nyquist coverage | Main trade-off |
|---|---:|---:|---|
| 64-QAM | 134.638 GS/s | 67.319 GHz | More analog bandwidth, wider constellation spacing |
| 256-QAM | 100.978 GS/s | 50.489 GHz | Less bandwidth, tighter accuracy requirement |

400G here is per lane, gross before pilot scheduling and FEC. It is not
aggregate across two lanes or a verified 400G payload rate.

## Slide 3 — What the new simulations actually show

Insert `results/400G_verification/figures/400G_upgrade_bottlenecks.png`
and `400G_independent_confirmation.png`.

- Simply raising speed with original scalar budgets: BER approximately 0.093.
- Changing only converter resolution to 9 bits: still approximately 0.090.
- 64-QAM upgraded combination, ideal 8-bit converters: **zero observed errors
  over 103 million bits**, nominal 95% BER upper bound **2.91e-8**.
- Standard 256-QAM, ideal 9-bit converters: BER **3.52e-6**, SER **2.82e-5**;
  misses paper comparison targets **2.4e-6 / 1.4e-5**.
- Lower noise/jitter, more averaging and CP screening did not establish a
  reliable 256-QAM pass. Screening seeds alone can be misleading.

Say: "Zero observed errors is a finite-test result, not zero true BER.
The statistical bound does not cover uncertainty in the hardware model."

## Slide 4 — The exact 64-QAM requirements to discuss

| Block/setting | Tested assumption |
|---|---|
| ADC/DAC | Ideal 8-bit codes, 134.638 GS/s |
| Channel | Synthetic low-loss response, 5 dB loss at 40 GHz |
| AFE input noise | 0.3 mV RMS, before VGA |
| Clock/converter jitter | 22.282 fs RMS per TX/RX process |
| TX power loading | -3.5 to 0 dB across data tones |
| Clipping | Paper DAC/ADC 12.6/13.4 dB |
| Framing/training | FFT 1024, CP8, L200 |

These are a tested combination, not proven minimum specifications.
The channel needs reach/material/package work; it does not improve merely
by shrinking transistors. Actual converter ENOB/SNDR must replace ideal bits.

## Slide 5 — What smaller CMOS can and cannot establish

- Imec's [2026 5-nm ADC result](https://www.imec-int.com/en/press/imec-unveils-7-bit-175gss-massively-time-interleaved-slope-adc-pairing-record-small-footprint)
  demonstrates 175 GS/s with nominal 7-bit conversion. Its speed is relevant;
  it does not qualify our ideal 8-bit accuracy, swing, jitter or full bandwidth.
- Obtain ADC/DAC accuracy curves, AFE noise/bandwidth, absolute clock jitter,
  interleaving mismatch and PVT from the intended PDK/IP or circuit simulations.
- Feed those characteristics into MATLAB and repeat counted BER verification.
- Parallel DSP can reduce the digital clock requirement: Fs/128 = 1.052 GHz
  for the 64-QAM candidate. Timing, area and power still need actual synthesis.

Say: "We cannot approve a technology node by name. We compare its measured
or simulated circuit capabilities with these system requirements."

## Slide 6 — Decisions and next deliverables

1. Agree on per-lane rate, gross versus payload, BER target and FEC.
2. Prioritize 64-QAM for circuit feasibility; retain 256-QAM as research.
3. Approve obtaining a low-loss THRU/FEXT model over at least 67.319 GHz.
4. Obtain candidate-process analog/clock data and digital cell libraries.
5. Repeat realistic converter/AFE/mismatch and fixed-point DSP simulations;
   report BER margins together with power, area and latency.

Suggested closing statement: **"We verified conditional 400G behavior with
fixed paper clipping. The next phase is to verify the required channel,
converter and clock budgets in a realizable implementation."**

<details>
<summary>Historical October 2 outline — superseded; do not use its numerical results</summary>

# Historical Presentation Outline -- Supervisor Meeting (02/10/2026)

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

</details>
