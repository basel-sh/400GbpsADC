# Target-seeking update - 7 October 2026

> Status, 10 October 2026: this document retains earlier experiments and assumptions. Use [current validation](validation.md), [project progress](project_progress.md), and [400G verification](400G_verification_for_doctor.md) for the latest confirmed numbers.

## Outcome

The published 224 Gb/s/lane headline is **not reproduced**. The stated throughput is reproduced (223.5625 Gb/s/lane from the paper's rounded parameters), but no run using all disclosed impairments reaches the published pre-FEC BER of 2.4e-6 or SER of 1.4e-5.

## New MATLAB experiments

The all-paper-parameter baseline was repeated for three independent seeds and 5,600 OFDM symbols per seed. It tested 103,017,600 bits in total across both lanes, with BER 0.00437007 and SER 0.0256361. A paper-equation experiment applied the channel independently on each OFDM subcarrier, thereby removing inter-block leakage from the long assumed channel impulse response while retaining the specified 8-sample CP. It produced BER 0.00435088 and SER 0.0255183 over the same total bits. This shows that residual time-domain channel memory is not the main cause of the baseline gap.

The 1.8 mV channel-output noise interpretation was also checked with a perfect-channel AWGN oracle. It yielded BER about 2.795e-3 and SER about 0.01647 across 103 million bits, before converter, jitter, or channel-estimation penalties. Under that interpretation, the target cannot be reached by tuning CHEST or the MIMO equalizer: the thermal-noise-only decision bound already exceeds the published BER by over three orders of magnitude.

A longer noise-budget sweep used 0, 0.025, 0.05, 0.075, 0.1, 0.15, 0.2 and 0.3 mV across the same three seeds, with 34.34 million bits per seed. Pooled BER ranged from 2.51e-6 to 3.22e-6 at 0.1–0.3 mV; individual seeds sometimes crossed the target, but those are not a reliable multi-seed pass. At zero noise, eight seeds (274.7 million bits) gave BER 2.443e-6 and SER 1.466e-5, just above the paper's point targets. Thus even removing the stated noise does not establish a pass in this model, although the counts are close enough that further receiver/channel-model investigation is warranted. The zero-noise case is a diagnostic only and violates the paper's 1.8 mV setting.

Increasing the CHEST averaging window from L=1000 to L=2000 at zero noise did not materially lower BER on three matched seeds (2.15e-6, 2.39e-6, 2.18e-6). More averaging is not a demonstrated path to the missing margin.

As a favorable interpretation, noise was placed at the ADC input after VGA, and the TX/RX RMS clipping ratios were screened around the paper's settings. The best short screening point (3.41 TX / 3.50 RX) gave BER 5.54e-5 over 1.23 million bits. Three longer seeds then gave BER 7.48e-5, 7.52e-5, and 7.69e-5 over 34.34 million bits each. This remains about 31 times above target and uses an RX clipping ratio different from the paper's 3.73 RMS setting. With the paper's 3.41/3.73 RMS clipping and after-VGA noise, the full three-seed result was BER 1.0407e-4.

The closest public IEEE channel-magnitude candidate from the available 802.3ck backplane archive was `Bch2_7_t.s4p` (23.76 dB loss at 40 GHz; 1.40 dB RMSE against the paper's digitized THRU curve). Its documented FEXT companion does not match the paper's Fig. 8 FEXT curve: its loss at 3.7 GHz implies roughly 54.5 dB THRU-to-FEXT separation, while the paper states about 28 dB. Pairing its measured complex THRU with the digitized paper FEXT magnitude produced BER about 2.90e-3 in the favorable after-VGA noise experiment. The pairing is hybrid and is not a valid recreation of the paper's measured 2x2 channel.

The public measured-phase C2C candidate was separately swept over CP lengths 8, 16, 32, 64 and 70 at a gross 224 Gb/s rate and 0.1 mV noise. The best short run was CP64 at BER 4.08e-5, but this changes the paper's CP and sampling rate and does not reach target. The long public-channel runs at the specified CP8 and 1.8 mV also miss by orders of magnitude.

## What the search establishes

The papers state the headline BER/SER and scalar link settings, but do not publish the exact complex 2x2 channel matrix, its phase/group delay, the exact channel file identity, or a complete noise/VGA reference-plane and bandwidth definition. Their reference points to the public IEEE 802.3ck tools archive, which contains many possible channels but does not identify a unique file matching Fig. 8. The author’s institutional record also has no associated paper download. The closest public magnitude match is not sufficient: its FEXT response differs materially.

The 224 target therefore cannot be honestly claimed from the available inputs. The result is not improved by further numerical tuning of the same assumptions. The next work that can resolve the mismatch is to obtain the authors' exact channel files or simulation model and clarify whether the 1.8 mV RMS noise is integrated before or after the VGA, over what bandwidth, and how it is applied per sample. Until then, the existing BER gap must remain explicitly labeled as unresolved model reproduction, rather than being closed by silently changing noise, clipping, CP, or converter settings.

## Reproduction scripts and data

The script names below record the historical investigation. These launchers
and their `results/target_reproduction/` outputs were removed during cleanup
on 24 October 2026. For current executable entry points and evidence, use the README.

- `run_diagonal_channel_check.m` - full-length, three-seed paper-equation check.
- `run_adc_input_full.m` - full-length, three-seed favorable noise-reference check.
- `run_adc_clipping_grid.m` and `run_adc_input_best_clip_full.m` - clipping search and long confirmation.
- `run_ieee_channel_adc_input.m` - public IEEE candidate sensitivity run.
- `run_cp_phase_noise_sweep.m` - CP/rate sensitivity sweep.
- `run_noise_threshold_full.m` and `run_noise_floor_full.m` - multi-seed noise budget sweeps.
- `run_zero_noise_extended.m` - eight-seed zero-noise floor estimate.
- `run_zero_noise_l2000.m` - matched-seed CHEST averaging check.
- The old machine-readable outputs and MATLAB structs are no longer retained locally.

`cfg.channel.ofdm_diagonal=true` is an optional comparison path that implements the paper's independent-subcarrier equations. It assumes that the CP fully removes inter-block interference; it is not evidence that a physical channel with a longer impulse response is protected by an 8-sample CP. The default physical-convolution path remains unchanged.

## 400 Gb/s planning implication

The 400 Gb/s approval plan remains conditional. First close or formally bound the 224 Gb/s model gap and obtain a measured 2x2 channel/noise model. Then compare an architecture budget against those calibrated inputs. A simulation that changes the channel, noise, clipping, converter ENOB, jitter, or occupied bandwidth can identify requirements, but cannot serve as approval evidence that the paper's implementation achieves 400 Gb/s.
