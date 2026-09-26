# Simulation Flow

## Signal chain (per lane, x2 for the 2x2 MIMO link)

```
Random bits (tx/generate_bits.m)
  -> 64-QAM modulate (tx/qam_modulate.m)
  -> TX de-emphasis / power loading (impairments/tx_deemphasis.m)
  -> OFDM mapping + IDFT + cyclic prefix (tx/ofdm_modulate.m)
  -> serialize
  -> DAC: RMS normalize -> clip -> jitter -> quantize (tx/dac_model.m,
     impairments/clipping_model.m, impairments/jitter_model.m,
     impairments/quantization_model.m)
  -> 2x2 MIMO channel: main + FEXT convolution (channel/mimo_channel.m,
     channel/main_channel.m, channel/fext_channel.m)
  -> RX input random noise (channel/add_noise.m)
  -> ADC: VGA -> clip -> jitter -> quantize (rx/adc_model.m)
  -> de-serialize into OFDM symbol blocks
  -> CP removal + DFT (rx/ofdm_demodulate.m)
  -> 2x2 MIMO frequency-domain equalization (mimo/mimo_fde.m,
     mimo/fext_cancellation.m), using a channel estimate from CHEST
     (rx/estimate_mimo_channel.m, rx/channel_estimation.m)
  -> QAM demodulate (rx/qam_demodulate.m)
  -> BER / SER / EVM (analysis/calculate_*.m)
```

This entire chain (excluding bit generation/demod/scoring) is implemented once, in
`experiments/link_forward_pass.m`, and reused for BOTH the CHEST pilot phase and the data-symbol phase --
exactly like real hardware, where pilots and data traverse the identical analog/DSP path. This is what lets
the channel estimate correctly absorb de-emphasis, VGA gain, and channel effects together (see
`docs/assumptions.md`, "Why CHEST must use the same pipeline as data").

## Orchestration

- `experiments/run_224G_test.m` -- single-configuration engine: generates data, obtains a channel estimate
  (CHEST, or an oracle/genie channel when impairments are disabled), equalizes, demodulates, scores.
- `experiments/experiment_ideal_channel.m` -- TEST 1 (symbol-level AWGN sanity check).
- `experiments/experiment_fext.m` -- TESTS 2-4 (channel / MIMO-FEXT architecture, no converter impairments).
- `experiments/experiment_224G.m` -- TESTS 5-6 (full impairments, minimal vs. converged CHEST) + headline
  figures for the supervisor meeting.
- `experiments/experiment_400G_sweep.m` -- the parameterized 400G scaling investigation (Part 7-8).
- `main_224G.m` -- runs TESTS 1-6 in order and saves all results/figures.
- `run_400G_sweep.m` -- runs the full 400G parameter sweep and saves all results/figures.

## Configuration

All numeric parameters live in `config/config_224G.m` (paper-faithful baseline) and `config/config_400G.m`
(builds on the 224G baseline, overriding only what's needed for a target data rate / sweep axis). No
function outside `config/` hard-codes a numeric parameter -- every block receives its parameters through
the `cfg` struct.

## Reproducibility

Every random draw (bit generation, AWGN, jitter) is seeded (`cfg.sim.rng_seed`, plus per-call offsets), so
re-running any script produces identical results.
