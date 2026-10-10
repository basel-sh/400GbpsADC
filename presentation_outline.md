# Professor proposal: presentation outline

Updated 10 October 2026. Use [the editable PowerPoint](presentations/Cairo_University_400G_Proposal.pptx) for the 10 to 15 minute proposal. Team and professor names remain placeholders.

The story is straightforward: understand the published architecture, show what our model currently establishes, and propose the work that would make a 400G implementation credible.

| Slide | Main point to explain |
|---|---|
| 1. Toward a 400 Gb/s serial link | Introduce the Cairo University project and the model-first approach. |
| 2. Our team and the proposed project | Present the communication, analog, digital, and integration workstreams. Assign people later. |
| 3. The research question | Ask whether 400G per lane survives realistic hardware constraints. |
| 4. How the link works | Explain QAM, OFDM, the channel, converters, and MIMO FEXT cancellation. |
| 5. Current 224G comparison | The rate is 223.5625 Gb/s; confirmed BER 1.239e-5 and SER 7.432e-5 still miss the paper targets. |
| 6. Rate equation | Show why 64-QAM needs 134.638 GS/s to carry 400G with FFT1024 and CP8. |
| 7. Required upgrades | Explain the tested 8-bit, 5 dB channel, 0.3 mV noise, and 22.282 fs jitter budgets. Clipping stays fixed. |
| 8. Why sample rate alone fails | Screening BER is 0.09297 with the original scalar budgets, and 0.09019 with only converter resolution increased. |
| 9. Conditional 400G result | Zero observed errors in 103,017,600 bits; nominal BER upper95 is 2.908e-8. Explain the model conditions. |
| 10. 64-QAM versus 256-QAM | 256-QAM lowers bandwidth, but the independently tested candidates still miss the comparison targets. |
| 11. Smaller transistor processes | Require real converter, clock, PDK, and interconnect evidence before selecting a node. |
| 12. Whole-project plan | Move from modeling to physical-budget validation, block design, and integration. |
| 13. Next verification work | Obtain full-band THRU/FEXT data, converter/clock curves, fixed-point DSP, and operating-condition margins. |
| 14. Professor decisions | Agree on rate, payload/FEC, reach, process resources, team responsibilities, and scope. |
| 15. Payload appendix | Illustrative training and 0.94 FEC leave 372.28 Gb/s payload at 400G gross. |
| 16. Evidence appendix | Point to the papers, scripts, result CSVs, and current verification report. |

## Statements to keep accurate

The 224G rate is established, but the paper's complete error performance is not reproduced. The 400G result is conditional behavioral evidence. We have not demonstrated silicon, chosen an available process, or selected a FEC code. Zero observed errors is not zero true BER.

Read [validation](docs/validation.md) before quoting the numbers and [the project plan](docs/400G_approval_plan.md) before describing the next phase.
