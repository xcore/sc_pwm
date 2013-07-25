Symmetrical Pulse Wave Modulation (PWM) Component for FOC
=========================================================

:scope: Early Development
:description: PWM driver component for FOC Motor control
:keywords: PWM, FOC, Motor Control
:boards: XP-MC-CTRL-L2, XA-MC-PWR-DLV

Features
--------

   * Computes following PWM parameters: Synchronisation pulse for ADC, 6 PWM signals: consisting of 3 phases for both high-leg and low-leg voltages. where high-leg is a positive going pulse, and low-leg is a negative going pulse.
   * The S/W for each motor runs in its own core to maximise PWM resolution.

Evaluation
----------

This module can be evaluated using the following demo applications:

   * PWM test harness ``Pulse Wave Modulation Interface Test Harness`` (app_foc_pwm)

