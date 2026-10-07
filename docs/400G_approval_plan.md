# 400 Gb/s upgrade: phase-one approval package

**Update, 8 October 2026:** Current merged-code verification and the
recommended ideal 8-bit/64-QAM candidate are recorded in
[400G verification for the Doctor](400G_verification_for_doctor.md).
The results and 9-bit candidate below describe earlier exploratory runs.

Decision requested from the project supervisor: approve a bounded phase-two
feasibility study of the candidate requirements below. Circuit implementation
approval remains pending the measurable acceptance gates. This document does
not grant approval or claim a hardware demonstration.

The working target is **400 Gb/s per lane**, consistent with the repository.
If 400 Gb/s is an aggregate two-lane requirement, a two-lane ~224 Gb/s design
already offers ~447.125 Gb/s gross, and this is a materially different project.
The requirements owner must settle per-lane versus aggregate and coded versus
payload throughput before implementation.

## Rate and bandwidth requirements

For homogeneous QAM and this framing:

R_gross = (NFFT/2-1) log2(QAM) Fs / (NFFT+NCP).

| 400G option, 1024 FFT / 8 CP | Required Fs | Nyquist bandwidth | Implication |
|---|---:|---:|---|
| 16-QAM | 201.9569 GS/s | 100.9785 GHz | Highest analog burden; best point in initial grid still missed 1e-4 BER |
| 64-QAM | 134.6380 GS/s | 67.3190 GHz | Lower QAM SNR burden; useful conditional candidate |
| 256-QAM | 100.9785 GS/s | 50.4892 GHz | Lower converter rate, stricter ENOB/noise/jitter burden |

Increasing FFT size alone cannot create the missing spectral efficiency.
At 75.25 GS/s, even 256-QAM gives only 298.0833 Gb/s with this framing.
The 400G search solves Fs from the rate equation at each modulation/FFT/CP
choice; a BER improvement achieved by reducing actual throughput is not a pass.

## Conditional candidate budgets supported by simulation

Both candidates use a deliberately changed **synthetic channel with 5 dB loss
at 40 GHz**, **0.3 mV RMS noise before VGA**, **0.3% UI jitter**, 1 Vpp DAC,
0.5 Vpp ADC, 1024/8 FFT/CP, L200 training, and -3.5 dB to 0 dB power loading.
The changed channel/noise/jitter requirements are substantial upgrades, not
paper reproduction. Measured-channel results, confidence limits and converter
resolution sensitivity are in `phase1_findings.md` and the accompanying CSVs.

- 64-QAM: conditional long run uses ideal 9-bit converters at 134.638 GS/s.
  8-bit converters are promising in screening but need independent long confirmation.
- 256-QAM: conditional long run uses ideal 9-bit converters at 100.978 GS/s,
  including spectral derivative jitter sensitivity. 7/8-bit screening is worse.

At these rates, 0.3% UI corresponds to ~22.3 fs RMS per TX/RX timing process
for 64-QAM, and ~29.7 fs for 256-QAM. This is an assumed budget that must be
demonstrated by real clock/converter designs. It is not an available IP specification.
If the physical timing error instead stays at the baseline ~132.9 fs, its
fractional UI rises as Fs rises; constant-percent-UI sweeps would be optimistic.

## Payload accounting

With two training symbols after each M=200 data symbols, data duty is 200/202.
This gives 396.04 Gb/s data-bearing throughput from 400 Gb/s gross, before FEC.
R_payload = R_gross * M/(M+2) * r_FEC * eta_other.

The FEXT text quotes 1/M percent overhead although its MIMO procedure uses two
symbols. That convention is unresolved; the approval budget must count the
actual schedule. To guarantee 400 Gb/s payload, increase Fs by
1/[M/(M+2)*r_FEC*eta_other] and rerun the channel/noise analysis. No FEC coding
gain is included in the current BER results.

## What hardware would be required

| Block | Required feasibility evidence |
|---|---|
| DAC and ADC | ENOB/SNDR versus input frequency and sample rate, swing, INL/DNL, aperture jitter, interleaving mismatch, power and area; ideal 9-bit codes are not proof of 9 ENOB |
| AFE/VGA and package | Noise <= tested input-referred budget, linearity, gain range and at least the relevant signal bandwidth, with package/ESD/bump parasitics |
| Interconnect | Full complex measured differential THRU/FEXT matrix for the actual length/material/connectors, not just one loss anchor; include return loss, impedance, NEXT and additional aggressors |
| Clocking | Absolute integrated jitter budget, phase-noise/correlation assumptions, skew calibration and margin over PVT |
| FFT/IFFT and FDE | Fixed-point word-length/overflow study, cycle schedule, memory bandwidth, measured synthesis timing/area/power in the available PDK |
| Training/synchronization | Sign-correlation acquisition per DSE Fig.10, retiming/framing, periodic two-symbol pilots, averaging/tracking under drift and shared stable gains |
| FEC | Named code, code rate, decoder latency/power, pre/post-FEC thresholds and payload requirement |

For a K=64 sample-wide partially serial path, Fs/K is approximately 2.104 GHz
for 64-QAM and 1.578 GHz for 256-QAM. K=128 reduces these to 1.052/0.789 GHz,
at the cost of parallel arithmetic and registers. A cycle-accurate schedule
must confirm those throughput estimates; they are not timing closure results.
DSE Eq.3 provides complex FFT multiplier scaling:
M_NFFT = M_KFFT + K/2 + (K/4)(log2(N/K)-1).
FEXT Eq.5 adds one complex multiplication plus an addition per carrier/lane
per aggressor beyond a single-lane equalizer. No numerical 22 nm power or
area is asserted without libraries, synthesis and analog implementation data.

## Approval gates and deliverables

1. **Requirements agreement:** signed per-lane/payload definition, reach, power,
   area, latency, BER/post-FEC target, process and allowed package/material changes.
2. **Paper reproduction:** identify the exact four complex responses, resolve
   clipping/noise/UI/pilot conventions, and recover the 224G error-rate target
   without removing the stated impairments. Otherwise obtain an author/model
   clarification and explicitly approve a different baseline.
3. **400G channel feasibility:** actual measured models support the full bandwidth;
   demonstrate BER at the agreed threshold with counted pilot/FEC overhead,
   independent seeds and noise/channel/jitter margins. Validate model sensitivity.
4. **Circuit feasibility:** PDK/IP data support the converter/AFE/clock budgets.
   Add fixed-point DSP, synchronization, interleaving mismatch, nonlinearity and PVT.
5. **Implementation authorization:** supervisor signs off only after gates 1-4
   and the power/area/latency review. Then proceed to RTL/circuit architecture.

Recommended present decision: approve measurements, channel identification,
requirements closure and converter/PDK feasibility work. Select 64-QAM and
256-QAM as competing studies; do not yet freeze or authorize a 400G silicon design.
