# How we propose to take the project to 400G

Updated 10 October 2026. This is the plan for discussion with the professor, not an approval already granted.

We recommend starting circuit feasibility with the **64-QAM 400 Gb/s-per-lane candidate**. It has independent model confirmation under explicit assumptions. The latest evidence is in [validation](validation.md) and [the detailed 400G report](400G_verification_for_doctor.md).

## Decisions to settle first

1. Is the target 400 Gb/s per lane or aggregate? Our current model target is per lane.
2. Does 400G mean gross rate or delivered payload after training and FEC?
3. What BER, post-FEC reliability, reach, latency, power, and area are acceptable?
4. Can the interconnect reach, material, package, or connector path change?
5. Which PDK, converter data, cell libraries, tools, and fabrication resources are available?

The paper's BER 2.4e-6 and SER 1.4e-5 are our current comparison values. They are not yet an approved system acceptance specification.

## The candidate to investigate

| Item | Tested 64-QAM candidate |
|---|---:|
| Gross data rate per lane | 400 Gb/s |
| Sample rate / Nyquist coverage | 134.638 GS/s / 67.319 GHz |
| FFT / CP / data tones | 1024 / 8 / 511 |
| Ideal DAC / ADC resolution | 8 / 8 bits |
| DAC / ADC full scale | 1.0 / 0.5 Vpp |
| DAC / ADC clipping | 12.6 / 13.4 dB |
| Synthetic channel loss anchor | 5 dB at 40 GHz |
| Noise before VGA | 0.3 mV RMS |
| Jitter per independent TX/RX process | 22.282 fs RMS |
| TX loading / CHEST averaging | -3.5 to 0 dB / L200 |

The result is zero observed errors over 103,017,600 bits, with nominal BER upper95 2.908e-8. These budgets form one tested combination, not minimum physical specifications. Ideal bits do not directly determine required ENOB.

## Work plan for the whole project

| Phase | Work | Deliverable and review gate |
|---|---|---|
| 1. Understand and model | Audit the papers, document assumptions, reproduce the baseline, identify 400G candidates | Reproducible results and agreed requirements. Current phase; conditional 400G modeling is complete, paper reproduction remains open. |
| 2. Validate physical budgets | Use measured THRU/FEXT responses, converter curves, clock/noise models, independent seeds and margin sweeps | Evidence that the target survives realistic link conditions |
| 3. Design the blocks | Characterize ADC/DAC/AFE with the PDK; build fixed-point OFDM and MIMO processing; develop a parallel RTL schedule | Analog PVT results, digital timing, and credible power/area/latency estimates |
| 4. Integrate and evaluate | Circuit/DSP co-simulation, system verification, and a prototype if resources allow | End-to-end result against the approved acceptance criteria |

Team roles, dates, resources, and implementation limits should be assigned with the professor. We have not assumed access to fabrication or promised a tapeout.

## What must be verified before implementation

The measured interconnect must cover at least 67.319 GHz plus margin. The ADC and DAC need suitable bandwidth, frequency-dependent SNDR/ENOB, linearity, input/output swings, and interleaving calibration. The clock study must include aperture jitter and the relevant phase-noise behavior.

The digital study must account for fixed-point error and a real processing schedule. A 64-sample-wide path implies a nominal 2.104 GHz sample-processing clock; a 128-wide path implies 1.052 GHz. This is throughput arithmetic, not evidence of FFT timing closure.

If 400G means payload, account for training and FEC first. For example, 2 training symbols per 200 data symbols with a 0.94 code rate leave 372.28 Gb/s payload at 400G gross. The corresponding 400G-payload 64-QAM rate would require about 144.664 GS/s and a new verification run.

## Recommended decision now

Approve the next phase of measurements and circuit feasibility using 64-QAM as the primary candidate. Keep 256-QAM as a lower-bandwidth alternative. Do not freeze a process node or claim a 400G hardware implementation until the measured budgets and implementation checks support it.

The earlier plan is preserved in [the historical record](history/2026-10-07_400G_approval_plan.md). Its statement that 8-bit confirmation is pending has been superseded by the independent runs reported above.
