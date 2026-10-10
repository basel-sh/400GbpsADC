# What we have changed and learned

Updated 10 October 2026. This is a plain-language account of the project so far, based on the saved experiment reports. The current readings are in [validation](validation.md).

## First, make the comparison trustworthy

We checked the framing equation, QAM/OFDM recovery, and MIMO channel estimation. The model now shares calibrated DAC/VGA gains between training and data, uses independently seeded TX/RX jitter, and averages the inverse equalizer coefficients consistently with the investigated paper procedure.

We also checked the Touchstone interpretation instead of assuming that every difference was caused by channel loss. The four-port ordering was verified and its original numerical behavior restored. The public channel files were imported and their provenance recorded.

These steps make the experiments more reproducible. They should not be described as a measured hardware improvement or as a clean comparison with the friend's original revision, which has not been established.

## Then, repeat the 224G readings

The friend's pasted BER was 4.346e-5 and SER was 2.603e-4. In our merged workspace, the recorded L200 baseline was BER 1.23124592e-5 and SER 7.38747554e-5. Different code/configuration conditions prevent us from assigning that difference to one optimization.

We explored more channel-estimation averaging. L1000 with the restored paper clipping gave pooled BER **1.23862330e-5** and SER **7.43173982e-5** across three independent seeds. This did not confirm a useful improvement from averaging alone. The paper targets are still unmet.

An earlier candidate improved BER to 8.82373497e-6 and SER to 5.29424098e-5, but it changed ADC clipping to 12.5 dB. We restored **DAC 12.6 dB and ADC 13.4 dB**, removed that clipping search from the current 224G optimization runner, and stopped treating the earlier 28% improvement as a current result.

## Next, ask what 400G really requires

We solved the sampling rate from the actual framing equation. That avoids calling a lower-throughput run a 400G result. With FFT1024 and CP8, 64-QAM needs **134.638 GS/s**, while 256-QAM needs **100.978 GS/s**.

Screening showed that just raising the sample rate fails. Original scalar budgets gave BER **0.09297**; changing only ideal converter resolution to 9 bits gave **0.09019**. Channel loss, loading, receiver noise, and absolute timing jitter had to improve together.

The selected 64-QAM combination uses ideal 8-bit converters, a synthetic 5 dB loss anchor at 40 GHz, 0.3 mV before-VGA noise, 22.282 fs TX/RX jitter, and -3.5 to 0 dB loading. It kept the paper clipping values fixed.

Three independent long runs then counted **zero errors in 103,017,600 bits**. The nominal BER upper95 is **2.908e-8**. This establishes a conditional behavioral operating point. It does not establish that an available chip or channel can meet those budgets.

## What did not solve 256-QAM

The standard 256-QAM candidate gave BER **3.524e-6**. Reducing noise and jitter gave **2.774e-6**. Increasing CHEST averaging to L1000 gave **3.516e-6**. Each independent result remained above the paper's BER comparison value of 2.4e-6 and also missed its SER target.

The CP sweep showed no consistent improvement. One attractive screening result did not survive independent long confirmation. We therefore keep 256-QAM as an alternative research path, not a verified replacement for 64-QAM.

## What happens next

Our strongest next step is to test whether the passing 64-QAM budgets are realistic. We need measured channel data, real converter accuracy across frequency, clock/noise data, an available PDK, and a fixed-point digital implementation study.

We prepared [the professor proposal](../presentations/Cairo_University_400G_Proposal.pptx) and [the project plan](400G_approval_plan.md) to discuss those decisions. The proposal covers the complete project, but implementation and process selection remain open.
