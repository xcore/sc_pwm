Overview
========

This module contains a Pulse-Width-Modulation (PWM) interface component for Motor Control systems.

It currently has the following specification:-

  * Maximum loop frequency: 360 kHz if using a reference frequency of 100 MHz (inner PWM loop requires 276 cycles)
  * PWM duty cycle: 4096 cycles, (allows 2048 different voltages)
  * A trigger pulse is output at a fixed offset into the PWM duty cycle. This can be used to synchronise with the ADC xSOFTip module.
  * For each PWM phase, voltages are driven on both a high-leg and low-leg of a balanced line. The low-leg pulse is inverted with respect to the high-leg pulse. The high-leg and low-leg pulse widths can be different sizes. This avoids dangerous current overload of the FET's. Both high-leg and low-leg pulses are symmetrically aligned around a centre line.
