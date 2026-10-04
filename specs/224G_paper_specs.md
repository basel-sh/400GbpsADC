# 224 Gb/s Baseline — Parameter Extraction From the Reference Paper

Primary reference (cited as **[FEXT]** below):
G. Kim, "Far-End Crosstalk Cancellation With MIMO OFDM for >200 Gb/s ADC-Based Serial Links,"
IEEE Trans. Circuits Syst. II, vol. 70, no. 1, pp. 81–85, Jan. 2023.

Secondary reference (cited as **[DSE]** below, same author, provides supporting system-level modeling
detail — FFT/CP/clipping/ENOB methodology — for the same 224 Gb/s design point):
G. Kim, "Design Space Exploration of Single-Lane OFDM-Based Serial Links for High-Speed Wireline
Communications," IEEE Open J. Circuits Syst., vol. 3, pp. 134–146, 2022.

Every row below is tagged:
- **(A)** = explicitly stated by a paper (page + location given)
- **(B)** = derived mathematically from (A) values
- **(C)** = NOT SPECIFIED IN REFERENCE PAPER → modeled as a configurable assumption in `config/config_224G.m`

---

## 1. Data rate and modulation

| Parameter | Value | Tag | Source |
|---|---|---|---|
| Per-lane data rate (DR) | 224 Gb/s | A | [FEXT] p.84, Sec. V, "data rate DR = 224 Gb/s" |
| Modulation | 64-QAM, all sub-channels (homogeneous, no bit-loading) | A | [FEXT] p.84, Sec. V, "64-QAM symbols for all sub-channels"; consistent with [DSE] p.140 Sec. IV-A discussion of homogeneous QAM vs. bit-loading (this brief uses homogeneous QAM only) |
| Bits/QAM symbol | 6 | B | log2(64) = 6 |

## 2. OFDM parameters

| Parameter | Value | Tag | Source |
|---|---|---|---|
| FFT size (N_FFT) | 1024 | A | [FEXT] p.84, Sec. V |
| Cyclic prefix length (N_CP) | 8 samples | A | [FEXT] p.84, Sec. V |
| OFDM-occupied bandwidth | 37.625 GHz | A | [FEXT] p.84, Sec. V |
| DAC/ADC sampling rate (Fs) | 75.25 GS/s | A | [FEXT] p.84, Sec. V |
| Number of usable (modulated) sub-channels | N_FFT/2 − 1 = 511 (k = 1…511), DC and Nyquist bin unused | B | [FEXT] p.83, Sec. II-B: "only the first half of the total DFT output bins are to be equalized (excluding the DC bin)"; de-emphasis description on p.84 explicitly references k up to 511 |
| Sub-channel spacing | Fs / N_FFT = 75.25 GS/s / 1024 ≈ 73.49 MHz | B | derived |
| CP overhead | 100 × N_CP/N_FFT ≈ 0.78 % | B | [DSE] eq. (4), p.141 |
| Symbol rate (Baud) | Fs / (N_FFT + N_CP) ≈ 72.9 M OFDM-symbols/s | B | derived |
| Bit rate check | (N_FFT/2 − 1) sub-channels × 6 bits × Fs/(N_FFT+N_CP) ≈ 223.5 Gb/s ≈ 224 Gb/s (paper's stated rate, rounding) | B | derived, consistent with stated DR |

## 3. Data converters

| Parameter | Value | Tag | Source |
|---|---|---|---|
| DAC resolution | 7 bit | A | [FEXT] p.84, Sec. V, "7-bit DAC/ADC" |
| ADC resolution | 7 bit | A | [FEXT] p.84, Sec. V |
| DAC output full-scale | 1 V_pp,diff | A | [FEXT] p.84, Sec. V |
| ADC input full-scale | 0.5 V_pp,diff | A | [FEXT] p.84, Sec. V |
| DAC clipping threshold-to-average ratio | 12.6 dB | A | [FEXT] p.84, Sec. V, "clipping threshold-to-average magnitude ratios are 12.6 dB on the TX output" |
| ADC clipping threshold-to-average ratio | 13.4 dB | A | [FEXT] p.84, Sec. V, "13.4 dB on the RX input" |
| Definition of clipping ratio | [DSE]: R_clip = β / A_RMS (threshold-to-RMS), R_clip,DAC = 3.41, R_clip,ADC = 3.73. [FEXT]'s 12.6 / 13.4 dB are threshold / MEAN MAGNITUDE; converting with E\|x\| = σ·√(2/π) gives 10^(12.6/20)·√(2/π) = 3.40 and 10^(13.4/20)·√(2/π) = 3.73, i.e. the same values (implemented in `impairments/clip_ratio_to_rms.m`, `cfg.clip_ratio_is_mean_abs`) | A / B | [DSE] p.143, Sec. V, eq. surrounding "R_clip,DAC = β_DAC/A_RMS,DAC" |
| CTLE | Not used ("CTLE is not considered") | A | [FEXT] p.84, Sec. V |
| VGA | RX VGA scales the input so the ADC uses its full input range | A | [FEXT] p.84, Sec. V |

## 4. Impairments

| Parameter | Value | Tag | Source |
|---|---|---|---|
| TX/RX sampling jitter | 1 % UI, RMS, random | A | [FEXT] p.84, Sec. V, "1% UI root-mean-square (RMS) TX/RX sampling jitter" |
| RX input random (thermal/AFE) noise | 1.8 mV RMS | A | [FEXT] p.84, Sec. V, "1.8 mV RMS RX input random noise" |
| Noise injection point | Default: referred to the RX input (before VGA/ADC) -- but [DSE] says only "on the AFE", so the paper does not settle it; `cfg.noise.reference = 'adc_input'` puts it after the VGA (see docs/fix_log.md) | A / C | [FEXT] p.84, Sec. V wording ("RX input random noise"); [DSE] p.143 Sec. V "random noise RMS amplitude of 1.8 mV on the AFE" |
| Quantization noise | Implicit from 7-bit DAC/ADC; not given a separate closed-form noise figure — modeled directly by quantizing the signal | B | derived from DAC/ADC resolution |
| DAC/ADC quantization SNR (QSNR) concept | Frequency-dependent SNDR of DAC/ADC acknowledged qualitatively; no numeric SNDR-vs-frequency curve given | A (qualitative only) | [DSE] p.141, Sec. IV-B |

## 5. TX de-emphasis / power loading

| Parameter | Value | Tag | Source |
|---|---|---|---|
| De-emphasis scheme | Homogeneous QAM (no bit-loading), but per-sub-channel TX de-emphasis is applied | A | [FEXT] p.84, Sec. V |
| De-emphasis at k = 1 | −10.5 dB | A | [FEXT] p.84, Sec. V, "-10.5 dB of de-emphasis at sub-channel k = 1" |
| De-emphasis at k = 511 | 0 dB | A | [FEXT] p.84, Sec. V, "gain is 0 dB at k = 511" |
| De-emphasis law between k=1 and k=511 | Linear in dB vs. sub-channel index k | A | [FEXT] p.84, Sec. V, "fewer de-emphasis levels that are linearly proportional to the sub-channel index k in dB-scale" |
| De-emphasis formula (derived) | dEmph_dB(k) = −10.5 × (511 − k) / (511 − 1), for k = 1…511 | B | linear interpolation matching both stated endpoints |

## 6. Channel (main + FEXT)

| Parameter | Value | Tag | Source |
|---|---|---|---|
| Channel source | "Measured channel frequency response [17]" = IEEE P802.3ck Task Force public channel tool/S-parameter set | A | [FEXT] p.84–85, Sec. V, Fig. 8, ref. [17]; [DSE] Fig. 9, ref. [28] (same IEEE 802.3ck source, referred to there as "CH3") |
| Main-channel loss (used in FEXT paper's headline result) | 23 dB at 40 GHz | A | [FEXT] Abstract, p.81 |
| Main-to-FEXT ratio | ≈28 dB at sub-channel k = 50 (≈3.7 GHz) | A | [FEXT] p.84–85, Sec. V |
| Exact S-parameter / transfer-function data | **NOT SPECIFIED IN REFERENCE PAPER** — the brief only shows a plot (Fig. 8) and cites an external, non-numeric source ([17], a web tools page); no table of the channel's frequency response is printed in the text | C | — |
| MIMO configuration | 2×2 (two TX lanes, two RX lanes), a single FEXT aggressor (one victim + one aggressor lane) | A | [FEXT] p.83, Sec. III, Fig. 5 |
| Channel matrix structure | H(k) = [[H13(k), H23(k)], [H14(k), H24(k)]], where H13/H24 are the two main (THRU) responses and H23/H14 are the two FEXT (crosstalk) responses | A | [FEXT] eqs. (2), (4), p.83 |

Because the exact measured S-parameters are not reproduced in the text of either paper, `channel/main_channel.m` and
`channel/fext_channel.m` implement a **parameterized, configurable synthetic channel model** (skin-effect + dielectric
loss style frequency-dependent attenuation for the main channel, and a separately-scaled weak-at-low-frequency /
stronger-at-high-frequency FEXT coupling model) whose free parameters are tuned so that the two headline anchor points
above (−23 dB @ 40 GHz main-channel loss, and ≈28 dB main-to-FEXT ratio at ≈3.7 GHz) are matched. This is flagged
throughout the code and in `docs/assumptions.md` and `docs/open_questions.md` as an assumption, not a reproduction of
the paper's exact measured channel.

## 7. Channel estimation (CHEST)

| Parameter | Value | Tag | Source |
|---|---|---|---|
| CHEST method | 2 OFDM symbols per estimation cycle: (n=1) opposite-polarity pilots per lane, (n=2) identical pilots per lane; H13/H23/H14/H24 obtained by sum/difference per eqs. (7)–(12) | A | [FEXT] p.83–84, Sec. IV-A, eqs. (7)–(12) |
| CHEST repetition period | Every M OFDM symbols, M > 100 recommended (effective rate loss = 100/M %, negligible for M > 100) | A | [FEXT] p.83, Sec. IV |
| Moving-average window for P1:4,k | L > 100 (paper sweeps L = 1…1000 and shows stabilization from L ≥ 100) | A | [FEXT] p.84–85, Sec. IV-A / Sec. V, Fig. 9 |
| Initial CHEST burst length | "Hundreds of pilot symbols (<10 µs)" for NFFT=1024, DR=224 Gb/s | A | [FEXT] p.84, Sec. IV |

## 8. Equalization

| Parameter | Value | Tag | Source |
|---|---|---|---|
| Single-lane FDE | X̂(k) = Y(k)·H⁻¹(k), one complex multiplier/sub-channel | A | [FEXT] eq. (1), p.82–83 |
| 2×2 MIMO FDE | [X̂1,k; X̂2,k] = Pk·[Y1,k; Y2,k], Pk = H_k⁻¹ (closed-form 2×2 inverse, eq. (6)) | A | [FEXT] eqs. (3)–(6), p.83 |
| Equalizer type | Zero-forcing (direct matrix inverse); no MMSE or other regularized equalizer is described | A (by omission — no alternative is presented) | [FEXT] Sec. III |

## 9. Reported results (used for validation targets, not reproduction targets)

| Result | Value | Tag | Source |
|---|---|---|---|
| SER without FEXT cancellation | 4×10⁻¹ | A | [FEXT] Abstract & p.85 |
| SER with FEXT cancellation | 1.4×10⁻⁵ | A | [FEXT] Abstract & p.85 |
| Pre-FEC BER with FEXT cancellation (assuming gray coding) | 2.4×10⁻⁶ | A | [FEXT] p.85, Sec. V |
| Target single-lane pre-FEC BER (no FEXT) design assumption | < 10⁻⁴ | A | [FEXT] p.83, Sec. III |
| BER requirement used for CP-length design rule in [DSE] | < 10⁻⁵ (with C_thres = 0.25) | A | [DSE] eq. (6) and surrounding text, p.142–143 |

## 10. Explicitly NOT specified in either paper (must be modeled as configurable assumptions)

- Exact channel S-parameters / transfer function tables (only plots + external tool reference) — **(C)**
- Semiconductor process node for the 224 Gb/s system-level study (no node is stated for the architectural/behavioral
  model in either paper) — **(C)**. Do not assume 22 nm for the paper's own study; 22 nm is only the *candidate future
  implementation node* the user has access to (see `docs/22nm_mapping.md`).
- Random-number-generator seed / exact bit sequence used in the paper's own simulations — **(C)**
- Number of OFDM symbols simulated for each reported BER/SER (not stated) — **(C)**
- Exact CHEST pilot sequence values S_k beyond "known QAM values with equal magnitude, opposite/same polarity" — **(C)**
- FEC scheme/code rate (FEC is mentioned as present in the general architecture, Fig. 1, but no FEC parameters are
  given; all BER/SER figures reported are **pre-FEC**) — **(C)**
- Explicit AWGN vs. colored-noise spectral shape for the "1.8 mV RMS RX input random noise" (paper only gives an RMS
  amplitude) — assumed white/Gaussian — **(C)**
- Whether jitter is modeled as pure sampling-instant jitter only, or also includes coupled TX/RX independent jitter
  sources — assumed independent identically distributed (i.i.d.) Gaussian jitter with the given RMS UI, applied
  independently at TX (DAC) and RX (ADC) — **(C)**

See `docs/assumptions.md` and `docs/open_questions.md` for the full, non-duplicated list with implementation
implications.
