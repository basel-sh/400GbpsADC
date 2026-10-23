# Current validation results

Updated 10 October 2026 using the saved MATLAB runs from 7 and 8 October. No new link simulation was run for this documentation update.

We keep three questions separate: the rate the framing carries, the errors counted in the model, and whether real hardware can meet the assumed budgets.

## 224G: the rate matches, the error targets do not

| Measurement | Current L1000 confirmation | Paper reference |
|---|---:|---:|
| Gross rate per lane | 223.5625 Gb/s | 224 Gb/s, rounded |
| SER with cancellation | 7.43173982e-5 | 1.4e-5 |
| Pre-FEC BER with cancellation | 1.23862330e-5 | 2.4e-6 |
| DAC / ADC clipping | 12.6 / 13.4 dB | 12.6 / 13.4 dB |

Seeds 31, 53, and 79 each used 5,600 data OFDM symbols per lane. Across two lanes, the pooled result is **1,276 bit errors in 103,017,600 bits** and **1,276 symbol errors in 17,169,600 QAM symbols**. The BER is about 5.16 times the paper comparison value; the SER is about 5.31 times higher.

Evidence: [confirmation CSV](../results/224G/paper_clipping_confirmation.csv) and [full 224G notes](friend_channel_reproduction.md).

`main_224` uses L200 rather than the confirmed L1000 window. Its recorded baseline BER is 1.23124592e-5 and SER is 7.38747554e-5. Increasing averaging alone did not establish a meaningful improvement across independent seeds.

The imported main channel has about 22.41 dB loss at 40 GHz, close to the paper's 23 dB anchor. However, its retained FIR main-to-FEXT ratio is about 60.03 dB at 3.7 GHz, compared with the paper's roughly 28 dB. This is not the same coupling case. The current 224G script also adds 1.8 mV noise after VGA. Moving that noise before VGA in the controlled L200 check gives BER 1.38617091e-3 and SER 8.27250489e-3.

For these reasons, the current model does not reproduce the complete paper result. Earlier statements attributing the entire mismatch to channel shape should not be used as a current conclusion.

## 400G: independently confirmed model candidates

| Candidate | Bit errors / tested bits | Pooled BER | Pooled SER | Outcome against BER 2.4e-6 and SER 1.4e-5 |
|---|---:|---:|---:|---|
| 64-QAM, ideal 8-bit, L200 | 0 / 103,017,600 | 0 observed; upper95 2.908e-8 | 0 observed; upper95 1.745e-7 | Conditional nominal-bound pass |
| 256-QAM, ideal 9-bit, L200 | 484 / 137,356,800 | 3.52366974e-6 | 2.81893579e-5 | Targets not met |
| 256-QAM, lower noise/jitter | 381 / 137,356,800 | 2.77379788e-6 | 2.21903830e-5 | Targets not met |
| 256-QAM, ideal 9-bit, L1000 | 483 / 137,356,800 | 3.51638943e-6 | 2.78981456e-5 | Targets not met |

All rows represent three independent long runs at 400 Gb/s gross per lane. The primary confirmation seeds are 431, 457, and 479. The L1000 study uses 641, 673, and 701. The L1000 row has 479 symbol errors; bit and symbol error counts need not be identical.

Evidence: [primary pooled results](../results/400G/verification/pooled.csv), [primary confirmations](../results/400G/verification/confirmation.csv), and [L1000 pooled results](../results/400G/verification/training_pooled.csv).

The passing 64-QAM candidate uses FFT1024, CP8, 511 tones, 134.638 GS/s, ideal 8-bit DAC/ADC, a synthetic 5 dB-at-40 GHz channel, 0.3 mV noise before VGA, 22.282 fs independent RMS jitter per TX/RX process, and -3.5 to 0 dB loading. Clipping remains 12.6/13.4 dB; full scales remain 1.0/0.5 Vpp.

The standard 256-QAM candidate uses 100.978 GS/s and ideal 9-bit converters with the same channel/noise/jitter budgets. Its lower-noise/jitter alternative uses 0.1 mV and 10 fs. The full conditions and sensitivities are in [the 400G report](400G_verification_for_doctor.md).

## What the confidence bounds mean

Zero counted errors gives a point estimate of zero. Under independent Bernoulli trials, the one-sided 95% upper bound is `1 - 0.05^(1/N)`, approximately `3/N`. This gives BER upper95 2.907981e-8 for 103,017,600 bits.

Each 64-QAM lane separately has zero errors in 51,508,800 bits, giving a nominal BER bound of 5.816e-8. Both lanes have zero errors in every confirmation seed.

These are nominal statistical bounds. OFDM decisions may be correlated, and training is shared across a run. The bounds do not quantify errors in the channel, converter, or jitter model. A hardware reliability claim needs physical evidence as well as counted decisions.

## What has been checked and what remains

`validate_phase1` previously passed rate arithmetic, QAM/OFDM recovery, shared gain behavior, independent jitter, and CHEST algebra checks. Those are functional checks of the model. They do not certify a converter circuit or a transistor process.

The available friend channel ends at 50 GHz. The Bch2_7 channel ends at 67 GHz. Neither fully covers the 67.319 GHz Nyquist requirement of the 64-QAM candidate. We still need measured complex THRU/FEXT responses with frequency margin, real ADC/DAC behavior, clock and noise characterization, fixed-point DSP, and PVT verification.

The earlier Octave validation report is preserved in [the historical record](history/2026-10-07_validation.md). Its numbers and reproduction claims are not the current results.
