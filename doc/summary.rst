PWM software
============

PWM, or Pulse Width Modulation, repeatedly asserts and deasserts a signal.
It is kept high for a fraction *f* of the time, and hence when passed
through a low pass filter the signal will appear as an analogue signal with
a value if *f*.

Important characteristics of a PWM unit are the following:

* The period - PWM with a long period can only drive signals with a low
  frequency. PWM with a short period can drive signals at a high frequency,
  but since the drive transistors switch more often the efficiency is
  reduced. Typical periods are 50 us (20 KHz).

* Synchronisity - whether all PWM signals have the same period and are in
  sync with each other.

* The minimum and maximum modulation. The shortest period that the signal
  can stay high or low. Typical, there is a minimum time for the signal to
  be high or low, say 500 ns (resulting in a minimum modulation of 1% and a
  maximum modulation of 99% assuming a 50 us period)

* The granularity of the signal. In a software defined PWM, the time that
  the signal stays high is an integral number of *clock-ticks*. The period
  of this clock governs how fine a step can be made. 

* The jitter. How much the signal is perturbed randomly.

* The number of PWM channels. In applications where the signal drives a
  device directly, one typically uses one PWM channel per device (eg, a
  LED). But when driving halfbridges (such as a class D amplifier or motor
  control), two PWM channels are required per halfbridge. In this case, one
  signal will change from high to low (closing a FET), then a short period
  later the other signal will change (opening the complementary FET). The
  time inbetween the changes is the *dead* time that no FET is driven; it
  is required to prevent the two FETs shorting the power supply.

On top of the PWM component, something needs to compute the time periods.
This component needs to take a required analogue value, and truncate/round
this to the nearest integer PWM value, possibly using dithering and
fractional counters to reduce the effects of rounding.

A standard XMOS PWM component is limited to a granularity of 10 ns,
although 2 ns granularity is possible at a cost of a higher number of
threads. Granularities of more than 10 ns require fewer threads. Higher
granularities are fine for visual effects, such as driving a LED. Good
quality audio needs 2ns or better.


module_pwm_multibit_fast
------------------------

This module is designed for many *synchronous* PWM channels with a granularity
of 10 ns (or higher), and a period of 25 us (40 KHz) or slower. There is no
minimum or maximum modulation. The signals need to have the same period,
but the centers do not need to be aligned. The jitter is 150 ps (???). The
number of channels that can be driven depends on the number of threads.
Assuming eight threads on a 500 MHz part:

+---------+----------+----------------+--------------------------------------+
| Threads | Channels | Period         | Status                               |
+---------+----------+----------------+--------------------------------------+
| 2       | 8        | 25 us (40 KHz) | Implemented, not tested exhaustively |
+---------+----------+----------------+--------------------------------------+
| 3       | 16       | 50 us (20 KHz) | Minor tweaks to codebase required    |
+---------+----------+----------------+--------------------------------------+
| 4       | 24       | 75 us (13 KHz) | Minor tweaks to codebase required    |
+---------+----------+----------------+--------------------------------------+
| 5       | 32       | 100 us (10 KHz)| Minor tweaks to codebase required    |
+---------+----------+----------------+--------------------------------------+


