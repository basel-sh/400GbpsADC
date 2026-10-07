# Paper coverage and evidence ledger - 7 October 2026

Primary: Gain Kim, TCAS-II 70(1), pp.81-85, DOI 10.1109/TCSII.2022.3205246.
Companion: Gain Kim, OJCAS 3, pp.134-146, DOI 10.1109/OJCAS.2022.3189550.
The two FEXT PDFs in the root contain the same paper. They are not separate experiments.

"Implemented" describes a behavioral model, not a fabricated or measured transceiver.

| Source/detail | Current treatment | Evidence or remaining limitation |
|---|---|---|
| FEXT Sec.V: 224 Gb/s/lane | Configured label; actual framing rate computed | 223.5625 Gb/s at the stated Fs, FFT, CP and 511 carriers; rounding is explicit |
| FEXT Sec.V: 1024 FFT / 8 CP | Implemented in TX/RX | Hermitian round trip checked; continuous channel convolution retains residual ISI |
| FEXT Sec.II-B: k=1..511 | Implemented | DC and Nyquist unused; conjugate half carries no new data |
| 64-QAM on every carrier, Gray coding | Implemented | QAM bit round trip checked, independent data on two lanes |
| Fs=75.25 GS/s; bandwidth 37.625 GHz | Implemented | Highest data tone is k511*Fs/1024; fs/2 is band-edge budget |
| 7-bit DAC and ADC | Implemented as uniform quantizers | This is an ideal resolution model; it does not demonstrate real ENOB or frequency-dependent SNDR |
| DAC 1 Vpp differential, ADC 0.5 Vpp differential | Implemented | Differential amplitude conventions retained; no arbitrary swing increase in paper baseline |
| TX clipping 12.6 dB / RX 13.4 dB | Implemented, both reference interpretations tested | Literal mean-absolute conversion gives RMS ratios ~3.404/3.732; RMS interpretation also measured |
| DSE p.143: RMS ratios 3.41 / 3.73 | Distinguished from FEXT dB definition | Similarity supports the mean-magnitude interpretation but does not prove author intent |
| DSE Fig.25: DAC 2.97..4.70, ADC 3.33..5.40 | Entire 11x12 clipping grid run | Separate optimization experiment; never substituted silently for the paper baseline |
| 1% UI RMS TX and RX sampling jitter | Implemented | UI=1/Fs and independent Gaussian process are assumptions; spline and spectral derivative sensitivity tested |
| 1.8 mV RMS RX random noise | Implemented | Primary assumption: channel output, before VGA. ADC-referred alternative measured separately |
| No CTLE | Preserved | A future CTLE upgrade requires a new transfer/noise model |
| VGA fills ADC range | One calibrated gain shared between pilots and data | Ensemble RMS calibration, ideal linear VGA; gain range/noise/linearity not demonstrated |
| -10.5 dB at k1, 0 dB at k511, linear in dB | Implemented and retained in baseline | Upgrade searches change power loading explicitly |
| Measured THRU/FEXT channel, Fig.8 and ref.[17] | Public IEEE channel archive inspected, candidate files downloaded | Exact paper filenames absent; two scalar anchors cannot identify a complex channel |
| 23 dB THRU loss at 40 GHz | Synthetic model anchor | Candidate Bch2_7 gives 23.763 dB, not an exact match |
| Main/FEXT ratio ~28 dB at k50 (~3.7 GHz) | Synthetic anchor | Downloaded Bch2_7_f1 gives ~54.52 dB ratio using the documented COM port pairing; it fails the paper anchor |
| 2x2 differential link / one aggressor, Eq.2 | Implemented, symmetric responses assumed | Actual four channel responses and additional aggressors still needed |
| Matrix inverse, Eqs.3-6, Fig.6 | Implemented | Four complex coefficients, two complex multiply terms per lane/carrier |
| Opposite/same-polarity pilots, Eqs.7-12 | Implemented and algebraically checked | Equal-I/Q QPSK pilots; exact sequence and pilot power unspecified |
| Fig.7 averages inverse coefficients P | Corrected implementation | Average each cycle's inverse, not only inverse of averaged H; alternative compared |
| Fig.9: L=1..1000 and stabilization >=100 | L200/L1000 sensitivity and convergence arrays | Full every-integer L data exists for training traces; pilot-only start-up ~5.49 us at L200 |
| CHEST periodic refresh / slowly varying channels | Static-channel estimation and explicit rate budget | Dynamic drift, periodic in-stream refresh and gain tracking not simulated |
| DSE Fig.10: synchronization sequence and sign correlation | Documented phase-two functional requirement | Current model assumes known framing; startup acquisition/retimer are not integrated |
| FEXT Fig.10: per-carrier SER and constellation | Per-carrier SER and raw arrays retained | Absolute headline SER is not reproduced with all stated impairments |
| FEXT Table I: FFT+FDE vs FFE+DFE; 64-way ADC | Architectural comparison only | No time-interleaved mismatch, ADC circuitry or 31-tap PAM implementation evidence |
| DSE Sec.III, Eq.3: partially serial KFFT resource scaling | Included in approval plan | FFT behavioral code has no RTL schedule, finite word lengths, synthesis area or power |
| DSE p.143: 48 million input bits | Long reruns exceed 48 million bits per lane | Seeds and measurement counts saved; FEXT itself does not state trial count |
| DSE CP/FFT trade-off, Eq.6 threshold C=0.25 | CP64 ablation and rate-correct FFT configuration | Complete channel-dependent CP design rule/FFT optimization remains to be validated on the identified channel |
| FEC input/output in Fig.1 | Report pre-FEC BER and explicit payload formula | FEC code/rate/block length/post-FEC target absent; no post-FEC claim |
| Semiconductor process and physical materials | No node or PCB material invented for the paper | IEEE candidate presentation describes Meg7/back-drilling; this does not identify the paper channel or prove 22 nm feasibility |

The corrected behavioral baseline still does not reproduce the headline result.
The outstanding items above prevent a claim that every system detail is reproduced.
They are input/implementation gaps, not variables to tune until a desired answer appears.

## Public channel provenance

- [IEEE tools/channels](https://www.ieee802.org/3/ck/public/tools/index.html)
- [Cisco measured-channel presentation](https://www.ieee802.org/3/ck/public/18_11/kareti_3ck_01a_1118.pdf)
- Archive: https://www.ieee802.org/3/ck/public/tools/backplane/kareti_3ck_01_1118_backplane.zip
- Files retained in `channel/data/ieee_candidates/` with original Readme.
- Readme port order: COM equivalent [1 3 2 4]. Differential transfer is
  (S21-S23-S41+S43)/2, using differential inputs 1/3 and outputs 2/4.
- CSV magnitude/complex responses are converted from the originals, without loss rescaling.
- Measured-complex sensitivity removes integer propagation delay, retains six
  precursors and 256 FIR taps. Delay alignment, endpoint continuation to DC,
  truncation and symmetric second lane are explicit modeling assumptions.
- These runs retain a synthetic FEXT path. They are hybrid sensitivity cases,
  not reproduction of the measured MIMO link. No measured channel is extrapolated
  beyond its 67 GHz upper frequency for the main-channel import.
