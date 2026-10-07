# 224G_400G_MIMO_OFDM

**2026-10-07 paper audit:** run `validate_phase1`, `run_phase1_audit`, then
`run_phase1_requirements`. New results are saved under `results/phase1/`.
Read `docs/phase1_findings.md` and `docs/400G_approval_plan.md` for current
evidence, unresolved reproduction assumptions, and conditional upgrade budgets.
Historical validation numbers below and in older documents predate this audit.

A MATLAB system-level simulation of the 2x2 MIMO-OFDM FEXT-cancelling wireline link described in:

> G. Kim, "Far-End Crosstalk Cancellation With MIMO OFDM for >200 Gb/s ADC-Based Serial Links,"
> IEEE Trans. Circuits Syst. II, vol. 70, no. 1, pp. 81-85, Jan. 2023.

plus a parameterized framework for investigating what changes when scaling the architecture toward
400 Gb/s/lane, informed by the companion paper:

> G. Kim, "Design Space Exploration of Single-Lane OFDM-Based Serial Links for High-Speed Wireline
> Communications," IEEE Open J. Circuits Syst., vol. 3, pp. 134-146, 2022.

**Start here if you're new to the project**: `specs/224G_paper_specs.md` (every parameter, with its exact
source in the papers) and `docs/validation.md` (what this simulation actually reproduces, and what it
doesn't, honestly stated).

## Requirements

- **MATLAB, base install only. No toolboxes required.** QAM modulation/demodulation is implemented from
  scratch (`tx/qam_modulate.m`, `rx/qam_demodulate.m`) specifically so the Communications Toolbox is not
  needed -- if your MATLAB does NOT have the Communications Toolbox, this project still runs unmodified. If
  you DO have the Communications Toolbox and prefer `qammod`/`qamdemod`, they are drop-in-compatible in
  convention (Gray-coded, unit-average-energy square QAM) and could replace `tx/qam_modulate.m` /
  `rx/qam_demodulate.m` with minimal changes -- not necessary, just an option.
- Functions used: `fft`/`ifft`, `interp1`, basic array/struct operations, `figure`/`plot`/`bar`/`text`,
  `exportgraphics` (falls back to `print` automatically if unavailable in older MATLAB versions).
- Tested for correctness in GNU Octave 8.4 (a free, MATLAB-compatible environment) during development --
  every function avoids Octave-incompatible MATLAB-only functions (e.g. `RandStream`, `categorical`,
  `xline` were deliberately avoided/replaced with portable equivalents) so the same code path was actually
  exercised end-to-end, not just written and assumed to work.

## Quick start

1. Open MATLAB.
2. Set the current folder to this project's root (`224G_400G_MIMO_OFDM/`).
3. Run:
   ```matlab
   main_224G
   ```
   This runs TESTS 1-6 (Part 5 of the project plan), prints a summary table to the console, and saves every
   figure under `results/224G/figures/` and a `results_224G.mat` struct under `results/224G/`.

4. For the 400 Gb/s scaling investigation:
   ```matlab
   run_400G_sweep
   ```
   Saves figures under `results/400G/figures/` and `sweep_results_400G.mat` under `results/400G/`.

Both scripts `addpath(genpath(...))` the project root automatically, so no manual path setup is needed.

**Expected runtime**: `main_224G` takes several minutes (dominated by the CHEST channel-estimation loop,
L=200 pilot cycles per test point, run at full precision). `run_400G_sweep` runs ~50 configurations at a
reduced (still paper-consistent) precision for tractable runtime -- see `docs/assumptions.md` Section 9.

## Folder structure

```
config/        Centralized parameters (config_224G.m = paper-faithful baseline; config_400G.m = scaling)
tx/            Bit generation, QAM modulation, OFDM modulation, DAC model
channel/       Main (THRU) channel, FEXT channel, 2x2 MIMO channel application, RX noise
rx/            ADC model, OFDM demodulation, CHEST channel estimation, QAM demodulation
mimo/          2x2 MIMO frequency-domain equalizer / FEXT cancellation
impairments/   Clipping, jitter, quantization, TX de-emphasis (shared, reusable building blocks)
analysis/      BER/SER/EVM, all plotting functions
experiments/   Test scripts (TEST 1-6), the 400G sweep, and the shared simulation engine
results/       Auto-generated: 224G/ and 400G/ figures + .mat result files
docs/          Mathematical model, simulation flow, assumptions, validation, 22nm mapping, open questions
specs/         224G_paper_specs.md -- every parameter with its exact page/section source
```

## How to modify parameters

Edit `config/config_224G.m` (baseline) or pass an `overrides` struct to `config_400G(overrides)` (see its
header comment and `experiments/experiment_400G_sweep.m` for many examples). Never hard-code a parameter
inside a `tx/`, `channel/`, `rx/`, `mimo/`, or `impairments/` function -- they all take `cfg` as an input.

## Where results are saved

- `results/224G/results_224G.mat` -- struct with every TEST's SER/BER/EVM, channel estimates (H13/H23/
  H14/H24), per-sub-channel SER, cfg, etc. **Note:** when you run `main_224G` yourself it will also save
  the full per-symbol TX/RX arrays (`tx_syms1/2`, `rx_syms1/2`, ...) inside this struct, which is
  scientifically useful (e.g. for redrawing constellations) but makes the file ~1.3 GB. The copy delivered
  with this project has those large raw-symbol arrays stripped out (everything else kept, including the
  full per-sub-channel breakdown) so it stays a manageable ~700 KB -- all summary numbers, channel
  estimates and figures were generated from the full run and are unaffected.
- `results/224G/figures/*.png` -- all supervisor-meeting-ready figures (Part 6 of the project plan).
- `results/400G/sweep_results_400G.mat`, `results/400G/figures/*.png` -- the 400G sweep's data and figures.

## Documentation map

| File | Contents |
|---|---|
| `specs/224G_paper_specs.md` | Every parameter, tagged A (paper-stated) / B (derived) / C (assumed), with exact source |
| `docs/mathematical_model.md` | The math behind every block, mapped to the implementing function |
| `docs/simulation_flow.md` | How the code is organized and orchestrated |
| `docs/assumptions.md` | Every assumption, why it was necessary, and its consequence |
| `docs/validation.md` | Honest comparison of measured vs. paper-reported results |
| `docs/22nm_mapping.md` | System-level blocks vs. what a future 22 nm implementation would need |
| `docs/open_questions.md` | Missing/ambiguous information, and what to obtain to close the gap |
| `presentation_outline.md` | Slide-by-slide outline for the supervisor meeting |
