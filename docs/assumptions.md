# Assumptions behind the current results

Updated 10 October 2026. We want each result to be understandable from its conditions, rather than treating a good BER as proof that every block is realistic.

## Common model choices

The model represents two lanes with frequency-domain MIMO equalization and physical channel convolution. The current confirmation uses real OFDM, 1024-point FFT, 8-sample CP, and 511 data tones. QAM has Gray-coded decisions. Converter quantization is ideal apart from the configured clipping and timing impairments.

DAC and ADC clipping remain 12.6 and 13.4 dB. The present interpretation uses mean absolute magnitude. That reference must be reconciled with the papers' clipping conventions. Full scales remain 1.0 and 0.5 Vpp.

Training and data share calibrated gains. TX/RX jitter draws are independent, and the investigated estimator averages inverse equalizer coefficients. These implementation checks improve consistency but do not validate the analog models against hardware.

## The 224G confirmation

The current 224G entry uses public Channel1 THRU/FEXT1 files and 1.8 mV noise after VGA. Its fixed-clipping confirmation uses L1000. The paper's described RX-input noise belongs before VGA, and the available channel does not match the paper's plotted coupling.

We cannot assume that the friend code, our merged workspace, and the paper are equivalent experiments. See [the reproduction notes](friend_channel_reproduction.md) for the measured differences.

## The passing 400G candidate

The 64-QAM candidate uses a synthetic channel with a 5 dB loss anchor at 40 GHz, 0.3 mV noise before VGA, 22.282 fs RMS jitter for each independent TX/RX process, ideal 8-bit converters, and -3.5 to 0 dB loading. It assumes the full channel shape and lane symmetry, not just that one loss value.

The synthetic response is not a measurement of an approved interconnect. Converter code resolution is not ENOB. The spectral-linear jitter model is a first-order waveform-derivative approximation; alternative-model sensitivity is useful, but neither model is a measured clock or aperture characterization.

These assumptions are why we describe the result as conditional behavioral feasibility. They must be replaced or supported by measured channel, converter, clock, and AFE data before hardware approval.

## Rate, overhead, and confidence

The reported 400G is gross per lane. FEC is not implemented. The example of two training symbols per 200 data symbols is an overhead budget, not a demonstrated tracking loop. A 0.94 FEC code rate is an illustration, not a selected code.

Nominal 95% error bounds assume independent Bernoulli decisions. OFDM decisions and shared estimates can be correlated. The bounds do not cover physical model uncertainty or PVT variation.

## What the model does not yet establish

We have no selected PDK, extracted layout, transistor implementation, fixed-point timing closure, or validated transceiver power/area result. A smaller process is an option to study, not an automatic consequence of the MATLAB numbers.

Read [validation](validation.md) for the current counts and [open questions](open_questions.md) for the next evidence to obtain. The earlier assumptions are retained in [history](history/2026-10-07_assumptions.md).
