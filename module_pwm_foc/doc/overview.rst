Overview
========

This module contains a Pulse-Width-Modulation (PWM) interface component for Motor Control systems.

For each motor, the main Motor Control loop, test harness, or other supervisory function, calculates the required pulse-width for the 3 motor phases. This information is then passed by calling the PWM Client function. The PWM Server runs in its own logical core and receives pulse-width input data from the PWM Client. Each pulse-width is converted into a bit-stream that is timed to rise (to one) and fall (to zero) at a defined time in order to create a PWM wave-train with the required mark/space ratio. This bit stream is driven onto 6 sets of output pins. High-leg and Low-leg (of a balanced-line) for each of the 3 motor-phases.

The pulse-width information is transmitted from the PWM Client to the PWM Server, either down a channel, or via shared memory. If a channel is used, the PWM server evaluates the bit-pattern and time-stamp information. Conversly, if shared memory is used, the PWM Client evaluates this information. By default the information is passed over a channel. If memory is plentiful, but timing on the PWM server core can NOT be met, then the shared memory option should be tried.

The PWM resolution determines how many different voltages may be applied to the motor coils. For example, a resolution of 12 bits will allow a PWM wave with a period of 4096 bits. Assuming this period starts low (at zero) and finishes high (at one), then there are 4095 points inbetween at which the pulse can rise. If the pulse rises early, the majority of the pulse will consist of ones, this will create a large voltage in the motor, and a fast speed. Conversly a pulse which rises late will consist mainly of zeros, this will create a small voltage in the motor, and a slow speed. If the patterns of all-ones and all-zeros (no voltage) are included, 4096 different voltages are possible.

The PWM to ADC trigger is used to signal to the ADC module when it should sample the motor current, in order to estimate the back EMF in the motor coils. The trigger is required because the sampling should be done in the middle of a high portion of the pulse. That is, when the PWM bitstream is held at one. Due to symmetry constraints, this means there should be an even number of ones in a pulse. This reduces the PWM resolution from 4096 to 2048 possible voltages. 

