Pulse Wave Modulation (PWM) Interface Component
===============================================

:scope: Early Development
:description: The PWM module is a xSoftIP component of the FOC Motor control suite for generating a set of PWM Voltages to be applied to the motor
:keywords: PWM, "Pulse Wave Modulation", FOC, Motor Control
:boards: XP-MC-CTRL-L2, XA-MC-PWR-DLV

Features
--------

   * Computes following PWM parameters: Synchronisation pulse for ADC, 6 PWM signals: consisting of 3 phases for both high-leg and how-leg voltages. where high-leg is a positive going pulse, and low-leg is a negative going pulse.
   * The S/W for each motor runs in its own core to maximise PWM resolution.

Evaluation
----------

This module can be evaluated using the following demo applications:

   * PWM test harness ``Pulse Wave Modulation Interface Test Harness`` (app_foc_pwm)

