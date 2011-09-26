PWM software
============

PWM, or Pulse Width Modulation, repeatedly asserts and deasserts a signal.
It is kept high for a fraction *f* of the time, and hence when passed
through a low pass filter the signal will appear as an analogue signal with
a value of *f*.

Important characteristics of a PWM signal are the following:

* The number of PWM channels. In applications where the signal drives a
  device directly, one typically uses one PWM channel per device (eg, a
  LED). But when driving halfbridges (such as a class D amplifier or motor
  control), two PWM channels are required per halfbridge. In this case, one
  signal will change from high to low (closing a FET), then a short period
  later the other signal will change (opening the complementary FET). The
  time in between the changes is the *dead* time that no FET is driven; it
  is required to prevent the two FETs shorting the power supply.

* The period - PWM with a long period can only drive signals with a low
  frequency. PWM with a short period can drive signals at a high frequency,
  but since the drive transistors switch more often the efficiency is
  reduced. Typical periods are 50 us (20 KHz).

* The granularity of the signal. In a software defined PWM, the time that
  the signal stays high is an integral number of *clock-ticks*. The period
  of this clock governs how fine a step can be made. 

* Synchronisity - whether all PWM signals have the same period and are in
  sync with each other.

* The minimum and maximum modulation. The shortest period that the signal
  can stay high or low. Typical, there is a minimum time for the signal to
  be high or low, say 500 ns (resulting in a minimum modulation of 1% and a
  maximum modulation of 99% assuming a 50 us period)

* The jitter. How much the signal is perturbed randomly.

* The way in which the on- and off-times are computed given a digital
  signal. This may be as simple as directly using a signal that is already
  sampled at the PWM frequency, or it may require rounding, dithering,
  interpolation, etc.

A standard XMOS PWM component is limited to a granularity of 10 ns,
although 2 ns granularity is possible at a cost of a higher number of
threads. Granularities of more than 10 ns require fewer threads. Higher
granularities are fine for visual effects, such as driving a LED. Good
quality audio needs 2ns or better.


module_pwm_singlebit_port
-------------------------


TBC

This module is designed for many PWM channels with a granularity
of 3 us (or higher), and a period of 6 us (166 KHz) or slower. There is no
minimum or maximum modulation.
Assuming eight threads on a 500 MHz part:

+-----------------------------------------+--------------------+-------------+
| Functionality provided                  | Resources required | Status      | 
+----------+----------------+-------------+---------+----------+             |
| Channels | Period         | Granularity | Threads | Memory   |             |
+----------+----------------+-------------+---------+----------+-------------+
| 1-13     | 500 ns (2 MHz) |      200 ns | 1       | 8 KB     | Implemented |
+----------+----------------+-------------+---------+----------+-------------+
| 14-16    | 500 ns (2 MHz) |      400 ns | 1       | 8 KB     | Implemented |
+----------+----------------+-------------+---------+----------+-------------+

This module performs a simple mapping to compute the PWM cycle time, and
runs PWM signals asynchronous.

module_pwm_multibit_port
------------------------

TBC

This module is designed for many PWM channels with a granularity
of 3 us (or higher), and a period of 6 us (166 KHz) or slower. There is no
minimum or maximum modulation.
Assuming eight threads on a 500 MHz part:

+---------------------------+--------------------+-------------+
| Functionality provided    | Resources required | Status      | 
+----------+----------------+---------+----------+             |
| Channels | Period         | Threads | Memory   |             |
+----------+----------------+---------+----------+-------------+
| 8        | 6 us (166 KHz) | 1       | 7 KB     | Implemented |
+----------+----------------+---------+----------+-------------+

This module performs a simple mapping to compute the PWM cycle time, and
runs PWM signals asynchronous.


module_pwm_singlebit_simple
---------------------------

This module is designed for many *synchronous* PWM channels with a granularity
of 10 ns (or higher). The PWM period and the minimum up and down time both
depend on the number of PWM channels. The signals must have identical periods,
and the centers must be aligned. The jitter is 150 ps (???). The
number of channels that can be driven depends on the number of 1-bit ports
available. This module requires a single thread and around 300 bytes of
memory.

Assuming eight threads on a 500 MHz part:

+----------------------------------+--------------+--------------------------------------+
| Functionality provided           | 1-bit ports  | Status                               | 
+----------+----------+------------+              |                                      |
| Channels | Max Freq | Min up     |              |                                      |
+----------+----------+------------+--------------+--------------------------------------+
| 1        | 2 MHz    | 2 ns       | 1            | Implemented, not tested exhaustively |
+----------+----------+------------+--------------+--------------------------------------+
| 2        | 1 MHz    | 130 ns     | 2            | Implemented, not tested exhaustively |
+----------+----------+------------+--------------+--------------------------------------+
| N        | 2/N MHz  |(N-1)*130 ns| N            | Implemented, not tested exhaustively |
+----------+----------+------------+--------------+--------------------------------------+

This module is designed to support applications such as motor control,
where many PWM channels are required with a high resolution. If 1-bit ports
are required for other purposes, then the multibit module below allows
8-bit ports to be used at the expense of an extra thread.

This module does not provide a mechanism to compute where to put the PWM
edges, as it is assumed that a higher level control loop will provide those
values and keep them in sync with external activities such as sampling ADCs.

module_pwm_multibit_fast
------------------------

This module is designed for many *synchronous* PWM channels with a granularity
of 10 ns (or higher), and a period of 25 us (40 KHz) or slower. There is no
minimum or maximum modulation. The signals need to have the same period,
but the centers do not need to be aligned. The jitter is 150 ps (???). The
number of channels that can be driven depends on the number of threads.
Assuming eight threads on a 500 MHz part:

+---------------------------+--------------------+--------------------------------------+
| Functionality provided    | Resources required | Status                               | 
+----------+----------------+---------+----------+                                      |
| Channels | Period         | Threads | Memory   |                                      |
+----------+----------------+---------+----------+--------------------------------------+
| 8        | 25 us (40 KHz) | 2       | 4 KB     | Implemented, not tested exhaustively |
+----------+----------------+---------+----------+--------------------------------------+
| 16       | 50 us (20 KHz) | 3       | 5 KB     | Minor tweaks to codebase required    |
+----------+----------------+---------+----------+--------------------------------------+
| 24       | 75 us (13 KHz) | 4       | 6 KB     | Minor tweaks to codebase required    |
+----------+----------------+---------+----------+--------------------------------------+
| 24       | 50 us (20 KHz) | 5       | 6 KB     | Minor tweaks to codebase required    |
+----------+----------------+---------+----------+--------------------------------------+
| 32       | 100 us (10 KHz)| 5       | 7 KB     | Minor tweaks to codebase required    |
+----------+----------------+---------+----------+--------------------------------------+
| 32       | 50 us (20 KHz) | 6       | 7 KB     | Minor tweaks to codebase required    |
+----------+----------------+---------+----------+--------------------------------------+

The PWM channels are all on 8-bit ports, so the bottom part will use all
four 8-bit ports on a core. On a 400 MHz part, this software can achieve at
best 20 ns granularity.

This module is designed to support applications such as motor control,
where many PWM channels are required with a high resolution. This can
either be achieved by using many 1-bit ports, but if these are required for
other purposes, then this module enables 8-bit ports to be used for PWM.

This module does not provide a mechanism to compute where to put the PWM
edges, as it is assumed that a higher level control loop will provide those
values and keep them in sync with external activities such as sampling ADCs.

