# 22 nm Technology Mapping (System-Level to Future Implementation)

**Important distinction, per the project brief (Part 9):** the reference papers ([FEXT], [DSE]) present a
**system-level, behavioral/architectural** study. Neither paper states that its 224 Gb/s MIMO-OFDM link was
implemented, or is intended to be implemented, in a 22 nm process -- no semiconductor technology node is
mentioned anywhere in either paper's text for this specific architecture. **This project does NOT assume the
paper's system was built in 22 nm.** The 22 nm process is only the technology the team happens to have
access to for a *possible future* silicon implementation of (a scaled version of) this architecture -- a
separate, forward-looking question from reproducing the paper's system-level results.

This MATLAB project is a **system-level (behavioral) simulation only**. It contains no transistor-level,
layout-level, or PDK-specific information, and none is invented here.

## Blocks that would eventually need a 22 nm circuit implementation

| Block | System-level model in this project | What a 22 nm implementation would need (not provided here) |
|---|---|---|
| DAC | `tx/dac_model.m`: ideal 7-bit (baseline) / swept N-bit quantizer + clipping | DAC architecture (current-steering, segmented, etc.), achievable ENOB at the target sample rate in 22 nm, output swing vs. supply, INL/DNL |
| ADC | `rx/adc_model.m`: ideal N-bit quantizer + clipping + VGA | ADC architecture (SAR, time-interleaved SAR, pipeline, flash), achievable ENOB/SNDR vs. sampling rate in 22 nm (frequency-dependent SNDR, not modeled here -- [DSE] Sec. IV-B notes this is a real effect), aperture jitter, comparator offset |
| Analog front-end (AFE) | Not separately modeled; VGA folded into `rx/adc_model.m` | Noise figure, bandwidth, linearity of any AFE circuitry in 22 nm |
| CTLE | **Not used** in the 224G baseline (paper explicitly states "CTLE is not considered", [FEXT] p.84) | If a future 22 nm design chooses to add one (e.g. to relax ADC ENOB requirements), its transfer function, area, and power in 22 nm |
| VGA | `rx/adc_model.m`: ideal automatic gain to ADC full-scale | Achievable gain range, bandwidth, noise contribution of a 22 nm VGA |
| DSP (FFT/IFFT, CP) | `tx/ofdm_modulate.m`, `rx/ofdm_demodulate.m` (functional, not cycle-accurate) | Partially-serial FFT architecture area/power estimation per [DSE] Sec. III (complex multiplier counts, KFFT sizing, CKDSP) -- [DSE] eq. (3) gives the multiplier-count formula that WOULD be the starting point for a 22 nm area/power estimate, but no 22 nm standard-cell/library numbers exist in either paper or in this project |
| MIMO equalizer (FDE) | `mimo/fext_cancellation.m`, `mimo/mimo_fde.m` (functional) | [FEXT] Fig. 6/Table I describe the circuit-level structure (one extra complex multiplier per sub-channel per aggressor) -- translating that to 22 nm area/power requires a 22 nm multiplier/adder library, which is not available to this project |
| Clocking | Not modeled | Clock distribution, jitter budget allocation between clock generation and other blocks in 22 nm -- our jitter model (`impairments/jitter_model.m`) only takes a single end-to-end RMS jitter number as an INPUT assumption, it does not derive one from a clocking architecture |

## What information is needed from the 22 nm PDK before any implementation-level work can start

1. Standard-cell library timing/power/area characteristics (for DSP/FFT/FDE area-power estimation, following
   the methodology in [DSE] Sec. III).
2. Available ADC/DAC IP (or a target ENOB-vs-sample-rate curve achievable in this specific 22 nm process) --
   this directly determines whether the 224G baseline's 7-bit/75.25 GS/s assumption, or any 400G-scaled
   variant, is realistic in silicon.
3. Achievable analog bandwidth for the AFE/VGA at the required signal bandwidth (37.6 GHz baseline, up to
   ~67-135 GHz for various 400G scaling scenarios explored in `experiments/experiment_400G_sweep.m`).
4. Clock generation/distribution jitter performance in this process node.
5. I/O and packaging parasitics, which affect the *system-level channel* itself (not modeled at all in this
   project -- our channel model, Section 6 of `docs/mathematical_model.md`, is purely a calibrated
   behavioral approximation of the PCB/package/connector channel, independent of the transceiver's own
   silicon process).

Until these are available, any 22 nm area/power number would be fabricated, not derived -- consistent with
Part 9's explicit instruction not to invent transistor-level specifications.
