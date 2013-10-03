Implementing software PWM drivers on xCORE multicore microcontrollers
=====================================================================

PWM Overview
------------

PWM, or Pulse Width Modulation, repeatedly asserts and deasserts a signal.
It is kept high for a fraction *f* of the time, and hence when passed
through a low pass filter the signal will appear as an analogue signal with
a value of *f*.

Important characteristics of a PWM signal are the following:

* The number of PWM channels. In applications where the signal drives a
  device directly, one typically uses one PWM channel per device (e.g. a
  LED). But when driving halfbridges (such as a class D amplifier or motor
  control), two PWM channels are required per halfbridge. In this case, one
  signal will change from high to low (closing a FET), then a short period
  later the other signal will change (opening the complementary FET). The
  time in between the changes is the *dead* time that no FET is driven; it
  is required to prevent the two FETs shorting the power supply.

* The period - PWM with a long period can only drive signals with a low
  frequency. PWM with a short period can drive signals at a high frequency,
  but since the drive transistors switch more often the efficiency is
  reduced. Typical periods are 50 us, and they are typically reported as a
  frequency, ie 20 KHz.

* The granularity of the signal. In a software defined PWM, the time that
  the signal stays high is an integral number of *clock-ticks*. The period
  of this clock governs how fine a step can be made. 

* The "number of bits". This is related to the period and the granularity:
  2^bits x granularity = period. For example, a period of 50 us (20 KHz)
  with 12 bits of precision requires a granularity of 50/2^12 = 12.5 ns.
  Conversely, a granularity of 100 ns at a period of 50 us results in nine
  bits of precision (100 x 2^9 = 50 us).

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

PWM on the xCORE
----------------

A standard XMOS PWM component is limited to a granularity of 10 ns,
although 2 ns granularity is possible at a cost of a higher number of
logical cores. Granularities of more than 10 ns require fewer logical cores. Higher
granularities are fine for visual effects, such as driving a LED. Good
quality audio needs 2ns or better.

Because IO tasks like PWM are implemented entirely in software on the xCORE, a wide variety of
PWM implementations can be realized which trade off resource usage against the various performance
metrics outlined in the previous section.

The remainder of this document gives an overview of various PWM drivers that have been implemented or
studied by XMOS.

module_pwm_singlebit_port
-------------------------

This module is designed for many PWM channels with a granularity
of 200 ns (or higher), and a period of 2 MHz or slower. There is no
minimum or maximum modulation.

Assuming eight logical cores on a 500 MHz part:

+----------------------------------+-----------------------------+-------------+
| Functionality                    | Resources required          | Status      |
+----------+---------+-------------+----------+---------+--------+             |
| Channels | Max KHz | Granularity | 1b ports | Cores   | Memory |             |
+----------+---------+-------------+----------+---------+--------+-------------+
| 1-13     | 2000    |      200 ns | 1-13     | 1       | 8 KB   | Implemented |
+----------+---------+-------------+----------+---------+--------+-------------+
| 14-16    | 1000    |      400 ns | 14-16    | 1       | 8 KB   | Implemented |
+----------+---------+-------------+----------+---------+--------+-------------+

This module performs a simple mapping to compute the PWM cycle time, and
runs PWM signals asynchronous.

module_pwm_multibit_port
------------------------

This module is designed for many PWM channels with a granularity
of 3000 ns (or higher), and a period of 166 KHz or slower. There is no
minimum or maximum modulation.

Assuming eight logical cores on a 500 MHz part:

+----------------------------------+---------------------------+-------------+
| Functionality provided           | Resources required        | Status      |
+----------+---------+-------------+----------+-------+--------+             |
| Channels | Max KHz | Granularity | 8b ports | Cores | Memory |             |
+----------+---------+-------------+----------+-------+--------+-------------+
| 8        | 166     |     3000 ns | 1        | 1     | 7 KB   | Implemented |
+----------+---------+-------------+----------+-------+--------+-------------+
| 16       | 166     |     3000 ns | 2        | 2     | 8 KB   | Implemented |
+----------+---------+-------------+----------+-------+--------+-------------+
| 24       | 166     |     3000 ns | 3        | 3     | 9 KB   | Implemented |
+----------+---------+-------------+----------+-------+--------+-------------+
| 32       | 166     |     3000 ns | 4        | 4     | 10 KB  | Implemented |
+----------+---------+-------------+----------+-------+--------+-------------+

This module performs a simple mapping to compute the PWM cycle time, and
runs PWM signals asynchronously.


module_pwm_singlebit_simple
---------------------------

This module is designed for many *synchronous* PWM channels with a granularity
of 10 ns (or higher). The PWM period depends on the number of channels.
Unlike any of the other PWM modules, the minimum up and down time both
depend on the number of PWM channels. The channels must have identical periods,
and the centers must be aligned. The jitter is 150 ps. The
number of channels that can be driven depends on the number of 1-bit ports
available.

Assuming eight logical cores on a 500 MHz part:

+-------------------------------------------------+---------------------------+--------------------------+
| Functionality provided                          | Resources required        | Status                   | 
+----------+---------+-------------+--------------+----------+-------+--------+                          |
| Channels | Max KHz | Granularity | Min up time  | 1b ports | Cores | Memory |                          |
+----------+---------+-------------+--------------+----------+-------+--------+--------------------------+
| 1        | 2000    |       10 ns | 2 ns         | 1        | 1     | 0.6 KB | Implemented, part tested |
+----------+---------+-------------+--------------+----------+-------+--------+--------------------------+
| 2        | 1000    |       10 ns | 130 ns       | 2        | 1     | 0.6 KB | Implemented, part tested |
+----------+---------+-------------+--------------+----------+-------+--------+--------------------------+
| N        | 2000/N  |       10 ns | (N-1)*130 ns | N        | 1     | 0.6 KB | Implemented, part tested |
+----------+---------+-------------+--------------+----------+-------+--------+--------------------------+

This module is designed to support applications such as motor control,
where many PWM channels are required with a high resolution. If 1-bit ports
are required for other purposes, then the multibit module below allows
8-bit ports to be used at the expense of an extra logical core.

This module does not provide a mechanism to compute where to put the PWM
edges, as it is assumed that a higher level control loop will provide those
values and keep them in sync with external activities such as sampling ADCs.

module_pwm_multibit_fast
------------------------

This module is designed for many *synchronous* PWM channels with a granularity
of 10 ns (or higher), and a period of 25 us (40 KHz) or slower. There is no
minimum or maximum modulation. The signals need to have the same period,
but the centers do not need to be aligned. The jitter is 150 ps. The
number of channels that can be driven depends on the number of logical cores.
Assuming eight logical cores on a 500 MHz part:

+----------------------------------+----------------------------+--------------------------+
| Functionality provided           | Resources required         | Status                   | 
+----------+---------+-------------+-----------+-------+--------+                          |
| Channels | Max KHz | Granularity | 8b ports  | Cores | Memory |                          |
+----------+---------+-------------+-----------+-------+--------+--------------------------+
| 8        | 40      | 10 ns       | 1         | 2     | 4 KB   | Implemented, part tested |
+----------+---------+-------------+-----------+-------+--------+--------------------------+
| 16       | 20      | 10 ns       | 2         | 3     | 5 KB   | minor updates required   |
+----------+---------+-------------+-----------+-------+--------+--------------------------+
| 24       | 13      | 10 ns       | 3         | 4     | 6 KB   | minor updates required   |
+----------+---------+-------------+-----------+-------+--------+--------------------------+
| 24       | 20      | 10 ns       | 4         | 5     | 6 KB   | minor updates required   |
+----------+---------+-------------+-----------+-------+--------+--------------------------+
| 32       | 10      | 10 ns       | 4         | 5     | 7 KB   | minor updates required   |
+----------+---------+-------------+-----------+-------+--------+--------------------------+
| 32       | 20      | 10 ns       | 1         | 6     | 7 KB   | minor updates required   |
+----------+---------+-------------+-----------+-------+--------+                          |
| Channels | Max KHz | Granularity | 16b ports | Cores | Memory |                          |
+----------+---------+-------------+-----------+-------+--------+--------------------------+
| 16       | 10      | 40 ns       | 1         | 2     | 4 KB   | Not Implemented          |
+----------+---------+-------------+-----------+-------+--------+--------------------------+
| 32       | 10      | 40 ns       | 2         | 3     | 5 KB   | Not Implemented          |
+----------+---------+-------------+-----------+-------+--------+--------------------------+

On a 400 MHz part, this software can achieve at best 20 ns granularity.

This module is designed to support applications such as motor control,
where many PWM channels are required with a high resolution. This can
either be achieved by using many 1-bit ports, but if these are required for
other purposes, then this module enables 8-bit ports to be used for PWM.

This module does not provide a mechanism to compute where to put the PWM
edges, as it is assumed that a higher level control loop will provide those
values and keep them in sync with external activities such as sampling ADCs.

module_pwm_foc
--------------

This module contains a Pulse-Width-Modulation (PWM) interface component specifically optimised for 
advanced Motor Control using Field Oriented Control and designed to interface with other xSOFTip blocks specifically design for this application. For each PWM phase, voltages are driven on both a high-leg and low-leg of a balanced line. The low-leg pulse is inverted with respect to the high-leg pulse. The high-leg and low-leg pulse widths can be different sizes. This avoids dangerous current overload of the FET's. Both high-leg and low-leg pulses are symmetrically aligned around a centre line.

It currently has the following specification:-

   * Maximum loop frequency: 360 kHz if using a reference frequency of 100 MHz (inner PWM loop requires 276 cycles)
   * PWM duty cycle: 4096 cycles, (allows 2048 different voltages)

A trigger pulse is output at a fixed offset into the PWM duty cycle. This can be used to synchronise with another logical core responsible for interfacing with an external ADC.

