# Questions we still need to answer

Updated 10 October 2026. These questions define the next work, rather than reasons to hide or adjust the current results.

| Question | Why it matters | Evidence or decision needed |
|---|---|---|
| Which exact complex THRU/FEXT responses produced the paper's result? | Our public channel pair has different coupling, so matching its main loss anchor is insufficient. | Identify the paper's files, ports, reach, and full frequency responses. |
| How should clipping, analog gains, and RX input noise be interpreted? | The after-VGA 224G entry and before-VGA 400G verification have different noise conditions. | Resolve the paper conventions and test one agreed baseline without changing its stated settings. |
| Is the target 400G gross or payload, per lane or aggregate? | The answer changes sampling rate and overhead requirements. | Professor-approved throughput and FEC specification. |
| Can a real interconnect meet the synthetic candidate's response? | 5 dB at 40 GHz is only an anchor in an assumed full channel. | Measured complex THRU/FEXT data covering at least 67.319 GHz plus margin. |
| What converter accuracy is achievable at that rate and bandwidth? | Ideal 8-bit quantization is not a real ENOB/SNDR specification. | Frequency-dependent ADC/DAC data, linearity, mismatch, calibration, and power. |
| Can the clock and AFE meet the tested noise/jitter budgets? | 0.3 mV input noise and 22.282 fs jitter are assumed requirements. | Clock/AFE characterization, aperture jitter, phase noise, and model sensitivity. |
| Which process and implementation resources are available? | MATLAB cannot select a transistor node or predict silicon power/area. | PDK access, circuit models, cell libraries, tools, and resource limits. |
| Why does 256-QAM still miss both comparison targets? | Lower bandwidth is attractive, but longer averaging and tested lower noise/jitter did not establish a pass. | Per-tone estimator bias, clipping/nonlinearity, independent seeds, and realistic AFE analysis. |
| How will the digital chain sustain the sample throughput? | Arithmetic parallelism alone does not prove timing or latency. | Fixed-point design, cycle-accurate schedule, RTL synthesis, and timing checks. |
| How reliable is the candidate across operating conditions? | A static symmetric link and nominal statistical bounds do not cover drift or hardware variation. | Lane asymmetry, channel variation, PVT, synchronization, tracking, and agreed margin sweeps. |

For the current counts and conditions, read [validation](validation.md). For the proposed sequence of work, read [the project plan](400G_approval_plan.md). Earlier paper questions are retained in [the historical record](history/2026-10-07_open_questions.md).
