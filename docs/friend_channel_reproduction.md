# Current 224G readings and what we learned from the friend code

Folder update, 24 October 2026: the active outputs previously called
`results/pulled_friend_exact/` now live in `results/224G/`. The older synthetic
224G outputs were preserved in `results/history/224G_synthetic/`.

Run date: 7 October 2026, MATLAB R2026b, base MATLAB.
Documentation reviewed 10 October 2026. The current fixed-clipping readings below remain the latest independent 224G confirmation; see [validation](validation.md) for the project-wide comparison.

## Current settings: paper clipping restored

At the user's request, DAC/ADC clipping is fixed at **12.6/13.4 dB**.
`config_224G` and `main_224` already used these values. The optimization
runner now also enforces them, removes the ADC clipping sweep, and excludes
saved alternatives with different clipping settings when resuming.
Only CHEST averaging is varied. The selected averaging window is L=1000.

Three independent runs (seed offsets 31/53/79, 5,600 symbols/lane each)
confirmed the restored settings over 103,017,600 bits / 17,169,600 QAM symbols:

| Metric | Current, DAC/ADC 12.6/13.4 dB | Paper target |
|---|---:|---:|
| SER with FEXT cancellation | 7.43173982e-5 | 1.4e-5 |
| Pre-FEC BER with cancellation | 1.23862330e-5 | 2.4e-6 |

The small single-seed reduction from increasing averaging is insufficient
to establish a meaningful improvement across independent runs. The earlier
28% improvement depended on changing ADC clipping and no longer applies.

Current output files use the `paper_clipping_` prefix under
`results/224G/`, preserving the earlier exploratory runs.
The earlier 12.5 dB candidate below is historical and is no longer the current
configuration. Fixing clipping does not resolve the channel/noise mismatch
with the paper discussed below.

The full `main_224` suite ran with the THRU/FEXT1 files named in the pulled
script. The absent D: drive path was replaced with a repository-local path.
The measured readings do **not** reproduce the friend's pasted numbers.
This is the current merged workspace, including existing calibration, training
and jitter changes; it is not a clean checkout of the friend's original code.
An unresolved conflict in `experiments/link_forward_pass.m` was resolved using
the pulled after-VGA noise injection implementation and independently seeded
ADC jitter. Therefore matching filenames alone cannot establish an identical
software/configuration baseline to the friend's run.

## Inputs and reproducibility

- Official archive: [IEEE 802.3ck C2C channels](https://www.ieee802.org/3/ck/public/tools/c2c/lim_3ck_05_0719_c2c.zip), linked from the [IEEE tools page](https://www.ieee802.org/3/ck/public/tools/index.html).
- THRU: `channel/data/ieee_8023ck_c2c/Channel1/Asic_Mezz_Retimer_L10_Thru.s4p`.
- FEXT: `channel/data/ieee_8023ck_c2c/Channel1/Asic_Mezz_Retimer_L10_FEXT1.s4p`.
- SHA256 values are saved in `channel/data/ieee_8023ck_c2c/provenance.json`.
- Defaults: FFT 1024, CP 8, 511 tones, 64-QAM, 75.25 GS/s, 7-bit DAC/ADC,
  1.0/0.5 Vpp full scales, 1% UI TX/RX jitter, 1.8 mV RMS noise,
  linear -10.5 to 0 dB TX de-emphasis, zero-forcing MIMO and averaged inverse coefficients.
- Baseline: 2,000 data OFDM symbols/lane, seed offset 3, CHEST L=200,
  DAC/ADC clipping 12.6/13.4 dB with the existing mean-absolute interpretation.
- Friend script sets `noise.reference='adc_input'`: noise is added after VGA.
- Physical convolution is used; no idealized diagonal-channel shortcut.
- Actual raw OFDM data rate is 223.5625 Gb/s per lane, rounded to 224 Gb/s.
  This includes CP and unused tones; training and FEC overhead are additional.

From the project root in MATLAB:

```matlab
main_224
run(fullfile('scripts', '224G', 'run_friend_channel_optimization.m'))
```

The optimization script writes CSV rows, a MAT file and a log. To repeat
only independent confirmations of the saved best candidate:

```matlab
friend_resume_confirmation = true;
run(fullfile('scripts', '224G', 'run_friend_channel_optimization.m'))
```

Set that variable false or clear it to repeat the whole sweep.

## Historical readings before clipping restoration

| Metric | Friend's pasted run | Recorded L200 baseline | Historical 12.5 dB alternative | Paper |
|---|---:|---:|---:|---:|
| SER with cancellation | 2.603e-4 | 7.38747554e-5 | 5.29424098e-5 | 1.4e-5 |
| SER without cancellation | 3.087e-4 | 1.08610568e-4 | 7.13470319e-5 | 4e-1 |
| Pre-FEC BER with cancellation | 4.346e-5 | 1.23124592e-5 | 8.82373497e-6 | 2.4e-6 |

The baseline counts 151 erroneous symbols out of 2,044,000 and 151 erroneous
bits out of 12,264,000 across two lanes. Repeating the same configuration
returned identical baseline readings.

The full suite's figures and `results_224G.mat` are now under
`results/224G/`; the historical synthetic files are under
`results/history/224G_synthetic/`.
Completion of the suite is not proof that all paper validation criteria pass.

## Historical clipping exploration and independent confirmation

The bounded sweep varies CHEST L=500/1000 at fixed paper converter settings,
then ADC clipping 12.0/12.5/13.0 dB with L=1000. Hardware resolution, full scales,
sampling rate, jitter, noise amplitude and channel files remain fixed.

Increasing L alone to 1000 gives SER 7.19178082e-5, only about 2.65% lower.
The selected alternative uses ADC clipping 12.5 dB and L=1000. Its initial
SER is 5.47945205e-5. The 12.5 dB clipping setting differs from the paper's
13.4 dB and is a design exploration, not a paper reproduction.

Three independent seed offsets 31/53/79, each with 5,600 symbols/lane,
produce SER 5.53885938e-5, 5.03214985e-5, and 5.31171373e-5.
Pooled counts: 909 erroneous symbols / 17,169,600 QAM symbols and
909 erroneous bits / 103,017,600 bits. Pooled SER is 5.29424098e-5 and
BER is 8.82373497e-6, about 28.3% below the baseline. This exceeds the
paper targets by approximately 3.78x for SER and 3.68x for BER.

L=1000 uses 2,000 training symbols in this batch estimator, approximately
27.4 microseconds. That startup burst exceeds the paper's cited <10 microsecond
initial acquisition example; longer moving averaging could instead continue
after acquisition in a streaming implementation.

Evidence: `optimization.csv`, `confirmation.csv`, `optimization.mat`,
and `optimization.log` under `results/224G/`.

## Why this is not yet the paper's result

1. The selected THRU has approximately 22.4099 dB loss at 40 GHz, near the
   paper's 23 dB anchor. However, the imported FIR main-to-FEXT ratio is
   approximately 60.0324 dB at 3.7 GHz, versus the paper's approximately
   28 dB. At 37 GHz this FIR ratio is still approximately 37.2009 dB.
   This explains why cancellation only modestly changes the SER and why
   the no-cancellation SER differs drastically from the paper's 0.4.
   It also means the matching friend filenames have not identified the paper's
   coupling case. Scaling FEXT merely to force a target would be an assumption.
2. The current Touchstone time conversion retains 99.9945% of THRU energy
   and 83.9153% of FEXT energy in its 512 retained taps. This is an importer
   approximation that needs attention in a rigorous channel reproduction.
3. The friend's script adds noise after VGA. The paper refers to RX-input/AFE
   noise before VGA. A controlled baseline check moving the same 1.8 mV RMS
   noise before VGA gives SER 8.27250489e-3 and BER 1.38617091e-3;
   no-cancellation SER is 8.99363992e-3. The results are saved in
   `before_vga_noise_check.csv`. After-VGA readings cannot establish fidelity
   to the paper's input-referred noise specification.
4. The reader initially suspected of using the wrong matrix ordering was
   checked against the [official Touchstone specification](https://ibis.org/touchstone_ver2.1/touchstone_ver2_1.pdf):
   v1 four-port files use row-major order. Its original numerical behavior
   was restored. This was not the cause of the mismatch.

The next evidence needed is identification of the exact THRU/FEXT pair and
the analog gain/noise convention behind the paper's plotted channel and
reported SER. The original friend's config/code revision and result MAT file
would establish why their pasted readings differ from the current merged run.
The available evidence does not justify claiming that the paper target has
been reached or that a 400 Gb/s implementation has been validated.
