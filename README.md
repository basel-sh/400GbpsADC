# From 224G to 400G: a MATLAB MIMO-OFDM link study

We are a student team at Cairo University, Faculty of Engineering. Our project starts with a published ADC-based serial-link architecture and asks what would need to change to support **400 Gb/s per lane**.

We are in the modeling and planning phase. We have tested a 400G operating point in MATLAB, but we still need real channel and circuit data before we can claim that the hardware is feasible.

Documentation updated: **10 October 2026**. The numerical results below come from the saved MATLAB runs completed on 7 and 8 October. Updating this README did not rerun or change those experiments.

## Where we are now

| Question | Current answer |
|---|---|
| Does the 224G framing reach the paper's advertised rate? | Yes. The calculated gross rate is 223.5625 Gb/s per lane, rounded to 224G. |
| Have we reproduced the paper's BER and SER? | No. Our current confirmed 224G readings remain above the paper's targets, and channel/noise differences are unresolved. |
| Does the model support a 400G candidate? | Yes, conditionally. The tested 64-QAM candidate produced zero observed errors in three independent long runs. |
| Is 400G hardware verified? | No. The passing model uses a synthetic channel and ideal converters. |
| Have we chosen a transistor process or FEC code? | No. These decisions need the professor's input and supporting data. |

BER is the fraction of recovered bits that are wrong. SER is the fraction of recovered QAM symbols that are wrong. A low BER shows reliable recovery under the tested conditions; it does not set the link speed by itself.

## Current readings compared with the paper

The current 224G confirmation uses fixed DAC/ADC clipping of **12.6/13.4 dB**, CHEST averaging L=1000, and three independent seeds. It tested 103,017,600 bits across two lanes.

| Metric | Current 224G confirmation | Paper comparison | Remaining gap |
|---|---:|---:|---:|
| Gross rate per lane | 223.5625 Gb/s | 224 Gb/s, rounded | Rate matches the rounded headline |
| SER with FEXT cancellation | 7.43173982e-5 | 1.4e-5 | About 5.31 times higher |
| Pre-FEC BER with cancellation | 1.23862330e-5 | 2.4e-6 | About 5.16 times higher |
| DAC / ADC clipping | 12.6 / 13.4 dB | 12.6 / 13.4 dB | Kept fixed |

These are the independent L1000 confirmation numbers. `main_224G` runs a different L200 baseline, so it will not print this exact row. The imported channel has weaker FEXT than the paper's plotted case, and the current 224G entry script places noise after VGA. The 400G verification uses noise before VGA. The readings therefore cannot establish a like-for-like paper reproduction or isolate a single cause of improvement between 224G and 400G.

Source: [224G run and reproduction notes](docs/friend_channel_reproduction.md), including the saved confirmation CSV.

## What we found at 400G

All rows below have a gross rate of 400 Gb/s per lane and retain the paper's 12.6/13.4 dB clipping settings.

| Independently tested candidate | Sample rate | Ideal DAC / ADC bits | Pooled BER | Pooled SER | Paper comparison targets |
|---|---:|---:|---:|---:|---|
| 64-QAM, L200 | 134.638 GS/s | 8 / 8 | 0 observed; nominal 95% upper bound 2.908e-8 | 0 observed; nominal 95% upper bound 1.745e-7 | Conditional model pass |
| 256-QAM, L200 | 100.978 GS/s | 9 / 9 | 3.524e-6 | 2.819e-5 | Not met |
| 256-QAM, lower noise and jitter | 100.978 GS/s | 9 / 9 | 2.774e-6 | 2.219e-5 | Not met |
| 256-QAM, L1000 | 100.978 GS/s | 9 / 9 | 3.516e-6 | 2.790e-5 | Not met |

The 64-QAM result counts **zero bit errors in 103,017,600 bits** and zero symbol errors in 17,169,600 symbols. Every confirmation seed has zero errors on both lanes. Each 256-QAM row counts 137,356,800 bits across three independent long runs.

Zero observed errors does not mean the true BER is zero. The reported confidence bound assumes independent Bernoulli decisions. Correlated OFDM decisions, shared training estimates, and errors in the physical model are outside that bound.

Read [validation](docs/validation.md) for counts and conditions, or [the detailed 400G report](docs/400G_verification_for_doctor.md) for the full investigation.

## What has to improve for the tested 400G candidate

| Budget | 224G scalar starting point | Tested 64-QAM 400G candidate |
|---|---:|---:|
| Sampling rate | 75.25 GS/s | 134.638 GS/s |
| Nyquist frequency coverage | 37.625 GHz | 67.319 GHz |
| Ideal converter resolution | 7 bits | 8 bits |
| Synthetic channel loss anchor at 40 GHz | 23 dB | 5 dB |
| RX input noise budget | 1.8 mV RMS | 0.3 mV RMS, before VGA |
| RMS jitter for each TX/RX timing process | 132.89 fs, using UI=1/Fs | 22.282 fs |
| TX loading across the data tones | -10.5 to 0 dB | -3.5 to 0 dB |
| DAC / ADC clipping | 12.6 / 13.4 dB | 12.6 / 13.4 dB |

This combination worked in the model. It is not a set of proven minimum specifications. Ideal converter bits are also not a measured ENOB requirement. The channel's full frequency response matters, not just its loss at 40 GHz.

Simply raising the rate while keeping the original scalar budgets gives BER **0.09297** in screening. Raising only converter resolution to 9 ideal bits still gives **0.09019**. The useful path is a combined improvement in channel, clock, noise, and converter behavior.

## How the rate is calculated

For 1024-point real OFDM with an 8-sample cyclic prefix, 511 positive-frequency tones carry data:

```text
Gross rate per lane = 511 * log2(QAM order) * Fs / (1024 + 8)
64-QAM at Fs = 75.25 GS/s gives 223.5625 Gb/s.
64-QAM at Fs = 134.6379648 GS/s gives 400 Gb/s.
256-QAM at Fs = 100.9784736 GS/s gives 400 Gb/s.
```

The project target is per lane. The error counts above pool two modeled lanes, which does not turn the target into an aggregate-rate claim.

400G here is **gross rate before training and FEC overhead**. As an illustration, two training symbols per 200 data symbols and a 0.94 FEC code rate would leave about **372.28 Gb/s of payload**. We have not selected or implemented that FEC scheme. A 400G payload target needs a higher sampling rate and separate verification.

## Run the project in MATLAB

Use the project root as MATLAB's current folder. The communication model uses base MATLAB, with custom QAM modulation and demodulation. The current saved verification runs used MATLAB R2026b.

Start with the functional checks:

```matlab
validate_phase1
```

Run the current 224G suite, then the fixed-clipping optimization and confirmation:

```matlab
main_224G
run_friend_channel_optimization
```

If you already have the optimization result and only want to repeat its independent confirmations:

```matlab
friend_resume_confirmation = true;
run_friend_channel_optimization
clear friend_resume_confirmation
```

For the current 400G investigation, run these sequentially:

```matlab
run_400G_verification
run_400G_cp_verification
run_400G_training_verification
plot_400G_verification
```

The first 400G script creates inputs needed by the CP and training studies. These are long experiments, not quick checks. Scripts write results to their named output files, so copy a result folder first if you want to preserve a separate run. `run_400G_sweep` remains available for exploratory architecture sweeps; its historical results are not the current confirmation table.

## Results and project files

| Location | What you will find |
|---|---|
| `results/pulled_friend_exact/paper_clipping_confirmation.csv` | Current independent 224G readings with clipping fixed |
| `results/400G_verification/pooled.csv` | Three primary 400G candidates, pooled counts and nominal bounds |
| `results/400G_verification/confirmation.csv` | Per-seed and per-lane measurements |
| `results/400G_verification/training_pooled.csv` | The independent 256-QAM L1000 result |
| `results/400G_verification/figures/` | Upgrade-bottleneck and confirmation charts |
| `presentations/Cairo_University_400G_Proposal.pptx` | Editable proposal slides with speaker notes |

Large generated `results_224G.mat` snapshots stay local and are excluded from Git. Their exclusion does not delete your results. Share the small CSV summaries, figures, configurations, and scripts when reviewing the work.

The model is organized into `tx/`, `channel/`, `rx/`, `mimo/`, `impairments/`, `experiments/`, and `analysis/`. Configuration lives in `config/`. Pass configuration changes explicitly instead of hiding values inside processing functions.

## The next phase

We propose 64-QAM as the first candidate for circuit feasibility. The next work is to obtain a measured channel covering at least 67.319 GHz plus margin, characterize real converters and clocks, and add fixed-point, nonlinearity, interleaving, synchronization, and PVT effects.

A smaller CMOS process cannot be selected from MATLAB BER alone. We need an available PDK, converter accuracy versus frequency, analog bandwidth, jitter, noise, power, area, and timing evidence. The professor also needs to settle the reach, gross versus payload target, and acceptable BER/FEC requirements.

## Documentation

| Read this | For this question |
|---|---|
| [Progress and decisions](docs/project_progress.md) | What did we change, what helped, and what remains open? |
| [Current validation](docs/validation.md) | What do the saved numbers actually establish? |
| [400G feasibility report](docs/400G_verification_for_doctor.md) | What budgets and limitations should we discuss? |
| [Project plan](docs/400G_approval_plan.md) | How do we take the whole project toward implementation? |
| [Open questions](docs/open_questions.md) | What information do we still need? |
| [Paper specifications](specs/224G_paper_specs.md) | Which settings are stated, derived, or assumed? |
| [Mathematical model](docs/mathematical_model.md) | How are the processing blocks represented? |
| [Simulation flow](docs/simulation_flow.md) | How do the scripts and model blocks connect? |

Earlier reports remain available as historical evidence. Use the current validation and 400G report when quoting today's status.

## Reference papers

G. Kim, "Far-End Crosstalk Cancellation With MIMO OFDM for >200 Gb/s ADC-Based Serial Links," IEEE Transactions on Circuits and Systems II, vol. 70, no. 1, pp. 81-85, January 2023.

G. Kim, "Design Space Exploration of Single-Lane OFDM-Based Serial Links for High-Speed Wireline Communications," IEEE Open Journal of Circuits and Systems, vol. 3, pp. 134-146, 2022.

The source PDFs are in the project root. Their specifications remain the reference for the 224G study; the proposed 400G budgets are our design exploration.
