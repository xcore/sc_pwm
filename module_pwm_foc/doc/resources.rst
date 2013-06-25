Resource Requirements
=====================

Processing Requirements
+++++++++++++++++++++++

+---------------+-------+-------+
| Resource      | Server| Client| 
+===============+=======+=======+
+---------------+-------+-------+
| Logical Cores |   1   |   1   |
+---------------+-------+-------+
| Input Ports   |   1   |       |
+---------------+-------+-------+
| Output Ports  |   6   |       |
+---------------+-------+-------+
| Channel Ends  |   2   |   1   |
+---------------+-------+-------+
| Timers        |       |       |
+---------------+-------+-------+
| Clocks        |   1   |       |
+---------------+-------+-------+


Memory Requirements
+++++++++++++++++++

Approximate memory usage for this module is (figures shown in Bytes):

* codememory: 1332 Bytes
* datamemory:  542 Bytes


Performance
+++++++++++
The PWM resolution is 2^n. Currently n=12, giving a resolution of 4096.
This means the main loop of the PWM server lasts 4096 cycles.
Currently only 276 cycles of processing are required in the main loop, giving 3820 idle cycles.
