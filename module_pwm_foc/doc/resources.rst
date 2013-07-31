Resource Requirements
=====================

+----------------+-------+-------+
| Resource       | Server| Client| 
+================+=======+=======+
| Logical Cores  |   1   |   1   |
+----------------+-------+-------+
| 1bit i/p Ports |   1   |       |
+----------------+-------+-------+
| 1bit o/p Ports |   6   |       |
+----------------+-------+-------+
| Channel Ends   |   2   |   1   |
+----------------+-------+-------+
| Timers         |       |       |
+----------------+-------+-------+
| Clocks         |   1   |       |
+----------------+-------+-------+
| Code memory    | 1332B |       |
+----------------+-------+-------+
| Data memory    | 542B  |       |
+----------------+-------+-------+


Performance
+++++++++++

The PWM resolution is 2^n. The default value of n is 12, giving a resolution of 4096 steps. Accordingly the main loop of the PWM server lasts 4096 xCORE reference clock cycles. Currently only 276 cycles of processing are required in the main loop, giving 3820 idle cycles.

