# Open Questions

Per Part 12 of the project brief: issues in the paper(s) that are ambiguous or missing, and assumptions
that materially affect reproducibility, are listed here explicitly rather than silently worked around.

## Missing parameters (from the papers)

1. **Exact channel S-parameters.** [FEXT] Fig. 8 and [DSE] Fig. 9 (channel "CH3") both reference an
   external source (IEEE P802.3ck Task Force tools page, ref. [17]/[28]) rather than printing numeric
   data. Without downloading and parsing that external tool's channel files (not provided to us, and not
   guaranteed to still correspond exactly to what was used in 2022-2023), the physical channel used in this
   project is necessarily a parameterized approximation. **Action for the team**: if the IEEE 802.3ck public
   channel tool/files are available, loading a real S-parameter touchstone file into `channel/main_channel.m`
   / `channel/fext_channel.m` (replacing the synthetic model) is the single highest-value improvement to
   make before the next milestone.
2. **CHEST pilot sequence values.** The protocol (2 symbols/cycle, opposite/same polarity) is fully
   specified, but the actual Sk values are only described as "known ... equal magnitude" -- not given
   numerically.
3. **Number of OFDM symbols simulated** for the paper's own reported SER/BER figures is not stated, so we
   cannot match their statistical confidence exactly.
4. **FEC scheme/rate** is not specified (all reported numbers are explicitly pre-FEC).
5. **Jitter process type** (white vs. correlated) beyond the RMS figure.
6. **Whether the two main-channel responses (H13, H24) or the two FEXT responses (H23, H14) are identical**
   for the specific 2x2 measured channel used -- not stated.

## Ambiguous statements

1. The abstract states "23 dB of loss at Nyquist" for long-reach channels in general discussion, but also
   separately "23 dB loss at 40 GHz" for the specific simulated channel -- and the baseline's actual Nyquist
   frequency (37.625 GHz, from N_FFT/CP/Fs) is slightly below 40 GHz. We treat "23 dB @ 40 GHz" as the
   literal calibration anchor (Section 6 of `specs/224G_paper_specs.md`) since it is the number given
   alongside the specific 224 Gb/s/23dB/1.4e-5 SER headline result.
2. A separate sentence near the end of Section V ("...communicating at 224 Gb/s of data rate through
   channels with >32 dB loss at 56 GHz") appears in the extracted PDF text in a position that suggests it
   may be part of a figure caption or a different context (column-order artifact of PDF text extraction) --
   we have not incorporated this second loss figure into the channel calibration, since it's unclear whether
   it refers to the same channel or a different, more general claim. Flagged here rather than silently
   picking one interpretation.

## Unavailable channel/ADC/DAC detail

- No S-parameter files were available to this project (see item 1 above).
- No frequency-dependent SNDR curve for the DAC/ADC is given (only a flat ENOB=7 is stated); [DSE] Sec.
  IV-B notes SNDR is frequency-dependent in real converters but does not give a formula.

## Assumptions that affect reproducibility (see `docs/assumptions.md` for full detail)

- Synthetic channel shape (skin/dielectric split, FEXT ratio roll-off law).
- Symmetric main/FEXT coupling across lanes.
- CHEST pilot sequence.
- AWGN noise shape.
- i.i.d. Gaussian jitter process.
- Ideal TX-RX sample synchronization (no synchronization-circuit-level errors modeled).
- 400G scaling rule (bandwidth-proportional-to-rate as the *default*; the sweep framework treats this as
  one axis among many, not a foregone conclusion).

## 400G sweep observations worth flagging to the team

- **FFT size shows almost no BER sensitivity** in our model (≈0.114 BER across N_FFT ∈ {256,512,1024,2048}
  with fixed N_CP=8), in contrast to [DSE]'s finding of a >10x BER improvement from 256 to 1024 taps. Our
  channel's FIR tap count (`cfg.channel.num_taps`, default 64) is fixed regardless of N_FFT/Baudrate, so the
  CP-vs-ISI trade-off that [DSE] Sec. III-C studies in detail is not fully captured by this simplified
  model. **Recommended follow-up**: scale `cfg.channel.num_taps` (and re-derive N_CP per [DSE] eq. 6's
  ISI-residual criterion) as a function of N_FFT/Baudrate for a more faithful CP-length study.
- The 400G data-rate/bandwidth scaling sweep (axis A) uses ONE particular scaling rule (bandwidth grows
  linearly with data rate, modulation/FFT held fixed) as the *default* baseline for the OTHER sweep axes.
  Whether this is the "right" way to scale toward 400G is exactly the open research question the sweep
  framework is meant to help the team explore -- axes D (modulation order) and F (FFT size) are the
  alternative/complementary scaling knobs.

## What we need to obtain to make the model more faithful to the paper

1. The actual IEEE 802.3ck channel S-parameter files (or the specific "CH3" touchstone file from [DSE]).
2. Any available detail on the paper's exact pilot sequence and number of simulated OFDM symbols (e.g. by
   contacting the author or checking for a supplementary dataset).
3. Confirmation of whether the two main/two FEXT channel responses were identical in the paper's model.

## Added with the bug-fix pass (see docs/fix_log.md)

- **Where does the 1.8 mV noise act?** [FEXT] says "RX input random noise"; [DSE] says "on the AFE". With
  the gains frozen and the clipping ratios corrected, putting it before the VGA (default,
  `cfg.noise.reference = 'rx_input'`) gives SER ~3e-2, after the VGA (`'adc_input'`) ~8e-4 in the Python
  cross-check. The paper's 1.4e-5 needs even less noise (about 0.3-0.6 mV at the RX input), so the exact
  noise reference of the paper should be clarified with the author if possible.
- **The measured channel** (IEEE P802.3ck) would replace the synthetic one; its impulse response also decides
  the cyclic-prefix length.
- **Does the paper moving-average P (the inverse) rather than H?** Fig. 7 of [FEXT] suggests P; this code
  averages H and then inverts. Equivalent to first order at high SNR; not tested.
- **Result files.** `results_old_pre_fix/` holds the figures and .mat written by the ORIGINAL code
  (Octave text format). Re-run `main_224G.m` to regenerate `results/` (MATLAB-readable -v7 MAT file).
