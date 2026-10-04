# Assumptions

Every assumption below exists because the reference paper(s) do not specify the corresponding value or
mechanism (tag **[C]** in `specs/224G_paper_specs.md`). Each is implemented as an explicit, configurable
parameter in `config/config_224G.m` (or documented in code) -- nothing is silently hard-coded inside a
signal-processing function.

## 1. Channel model (biggest assumption in the project)

The paper cites a *measured* channel (IEEE P802.3ck task-force tool/S-parameters) but only shows a plot
(Fig. 8) -- no numeric table. We calibrate a standard skin-effect + dielectric-loss magnitude model to the
paper's two published numeric anchors (23 dB loss @ 40 GHz; ~28 dB main-to-FEXT ratio @ 3.7 GHz), and
reconstruct a causal impulse response via the minimum-phase (real-cepstrum) method since no phase data is
published either. **This is the single largest source of quantitative mismatch between our simulation
results and the paper's reported SER/BER** (see `docs/validation.md`) -- the paper's real channel shape
(and its interaction with the specific de-emphasis profile) is presumably tuned so overall SER lands at
1.4e-5; our hand-calibrated channel is not.

- Skin/dielectric split (`cfg.channel.skin_dielectric_split = 0.5`): arbitrary 50/50 split of the anchor
  loss between the sqrt(f) and f terms. A different split would change the loss curve's shape between DC
  and the anchor frequency.
- Main-to-FEXT ratio roll-off (`cfg.channel.fext_ratio_slope_dB_per_decade = 20`,
  `fext_ratio_floor_dB = 3`): the paper only states the ratio decreases with frequency qualitatively; the
  exact roll-off law and floor are assumed.
- Symmetric coupling: H13 = H24 (both lanes' main channel identical) and H23 = H14 (FEXT identical in both
  directions). The paper does not state whether this symmetry holds for its measured channel.
- 40 GHz exceeds this configuration's Nyquist bandwidth (37.625 GHz for the 224G baseline) -- the anchor is
  used purely to fix the closed-form loss law's shape parameters; the model's actual in-band loss at
  Nyquist works out to ≈22 dB, consistent with extrapolating smoothly to 23 dB at 40 GHz.

## 2. CHEST pilot sequence

The paper specifies the CHEST *protocol* exactly (opposite/same-polarity pilot pairs, eqs. 7-12) but not
the actual pilot values Sk beyond "known, equal-magnitude QAM values". A fixed, seeded pseudo-random +/-1
sequence is used (`rx/estimate_mimo_channel.m`) -- chosen specifically to avoid the very high peak-to-average
power ratio (PAPR) of an all-equal-phase pilot tone, which would clip pathologically under the paper's own
clipping-ratio settings.

## 3. Why CHEST must use the same pipeline as data -- and the same GAINS (an implementation constraint, not a free choice)

TX de-emphasis and the DAC/ADC gain stages are linear operations applied identically to pilots and data. A
real receiver's CHEST *automatically* captures their combined effect because pilots physically pass through
the same DAC/channel/VGA/ADC chain as data. Our `experiments/link_forward_pass.m` is therefore used for BOTH
phases.

**The gains must be constant between pilots and data.** The sum/difference estimator of eqs. (11)-(12)
assumes that both pilot symbols are multiplied by the same scalar. A real VGA/AGC loop is far slower than a
two-symbol pilot sequence, so its gain is frozen. Earlier versions of this code re-normalized the DAC scale and
the VGA gain to the RMS of every block they received; because the two pilot symbols reach the ADC with
different power, they were amplified differently and the estimate was biased (docs/fix_log.md, Bug 1). Now
`run_224G_test.m` measures the gains once on a data-like block (`ncal = min(100, Nsym)` symbols) and passes
them frozen (`opts.agc`, `opts.noise`) to the pilot phase and to the data phase.

An *oracle* ("genie") equalizer that only knows the synthetic channel's closed-form response (bypassing
CHEST) is only valid when converter impairments are disabled (`apply_impairments=false`): with impairments on,
the effective channel also contains the frozen DAC and VGA gains, which the oracle does not know, and
`experiments/run_224G_test.m` raises an error if `use_genie_channel=true` is combined with
`apply_impairments=true`.

## 4. Jitter process

The paper states an RMS jitter figure (1% UI) but not the process (white vs. correlated phase noise). We
model i.i.d. Gaussian per-sample timing error with the stated RMS, reconstructing the waveform via cubic
spline interpolation at the jittered instants (`impairments/jitter_model.m`).

## 5. Noise spectral shape

"1.8 mV RMS RX input random noise" is modeled as additive white Gaussian noise (`channel/add_noise.m`) --
the paper gives only an RMS amplitude, not a spectral shape.

## 6. TX-RX synchronization

Sample-level TX-RX synchronization (CP-index alignment) is assumed ideal -- `rx/ofdm_demodulate.m` operates
on already-aligned blocks. The paper's own synchronization sequence/correlator ([DSE] Sec. II-D) is not
implemented at the DSP-block level; this project focuses on the OFDM/MIMO/FEXT/impairment chain specified
in [FEXT], not the separate synchronization sub-system.

## 7. FEC

Both papers report **pre-FEC** BER/SER only, and note FEC is present in the general architecture (Fig. 1 of
[FEXT]) without specifying a code or rate. No FEC is modeled; all BER/SER numbers in this project are
pre-FEC, directly comparable to the paper's own pre-FEC figures.

## 8. 400G scaling rule (`config/config_400G.m`)

The **default** 400G scaling rule keeps N_FFT, N_CP, and modulation order fixed at the 224G baseline values
and scales the DAC/ADC sampling rate (and therefore occupied bandwidth) linearly with the data-rate ratio.
This is one reasonable default among several possible strategies (increasing modulation order, ADC
resolution, or FFT size instead of/in addition to bandwidth are all explored as separate, independent sweep
axes in `experiments/experiment_400G_sweep.m` -- the sweep framework does NOT assume the default scaling
rule is correct or optimal; that is precisely the open question Part 7-8 asks us to investigate).

The TX de-emphasis law is re-mapped linearly onto a general N_used range so its relative *shape* is
preserved when N_FFT changes -- an explicit choice, not implied by the paper (which only defines the law
for N_used=511).

## 9. 400G sweep performance/precision trade-off

`experiments/experiment_400G_sweep.m` caps the number of data OFDM symbols at 100 and the CHEST
moving-average window at 120 (vs. the 224G baseline's 2000 symbols / L=200) purely so the full ~50-point
sweep completes in minutes rather than hours. Every sweep BER/SER value therefore has more statistical
variance than the corresponding `main_224G.m` baseline number -- re-run an individual configuration with
`config_400G()`'s full defaults (or via `experiments/run_224G_test.m` directly) for a precision number.

## 10. Pilot magnitude convention

QAM symbols (data and pilots alike) are normalized to unit average energy (`E[|s|^2]=1`); all power/clipping
budget calculations in the DAC/ADC models are relative to this convention, consistent with how the paper's
clipping-ratio and RMS figures are defined relative to the actual transmitted composite waveform.
