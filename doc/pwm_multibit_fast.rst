Fast 8-bit wide PWM
===================

This module implements a 100 Mhz PWM on 8 bits simultaneously. It performs
this task by utilising two threads: one thread reads a block of memory and
outputs values from memory to the 8-bit port as quickly as possible. The
other thread arranges the values in memory to be output. The values are
arranged in the form of a small program that has instructions to output a
group of different values in sequence, or the same value N times. The
thread that writes to memory effectively compiles the PWM requirements into
instructions that will cause PWM on the 8-bit port.


Status
------

This is a proof of concept. For completion a couple of things need doing:

#. Exhaustive testing of the sorting function.

#. Put synchronisation in place between two threads. This can take the form
   of a timer or a timed port.

#. Extensive testing of the PWM function

#. Enable three threads to be used to drive 16 bits (@ 80 MIPS or with more
   optimisations).

Performance
-----------

Current performance using 62.5 MIPS threads (8 threads at 500 MHz) is:

* Half a PWM cycle takes approx 16 us, so a full cycle will take 32 us,
  giving around 30 KHz.

* PWM thread requires no more than 62.5 MIPS to keep running without gaps.

Usage
-----

Call ``pwmWide1()`` with two arguments: an 8-bit buffered port (32-bits
transfer width), and a channel end. Over the channel end, output
the initial port value, and the time that the first output should happen;
this is the value in counter ticks on the port, and should be at least one
PWM cycle in the future. Then in a ``master`` transaction, output eight
values signalling when pins 1-8 should change. Values should be output as
32-bit integer times, counting in 100 Mhz. The wire will change when the
last 16-bits of the 32-bit value match the port counter.

By keeping the 8-bit port synchronised with all other PWM ports and other
signals that should be synchronous (such as ADC sampling), the PWM
component can be made to run synchronous with the algorithm and other I/O.


Instruction Set
---------------

The PWM thread is programmable by means of a set of instructions that are
provided as a linked list of instructions. Each instruction has a pointer
to a block of memory that contains the next instruction. In addition, each
instruction also contains the next instruction (!). The block of memory
contains parameters for the current instruction, such as the value(s) to
output.

The instructions are::

   setTime  NextPC, ThisInstr, Time, Value
   changeN  NextPC, ThisInstr, loopAround, Counter, Value, Value*N
   changeN  NextPC, ThisInstr, stableK, dontcare, Value, Value*N

Each instruction contains a pointer to the code for this instruction, and a next program
counter. At the end of an instruction, the next program counter is
extracted, and that is used to retrieve the code address for the next
instruction. 

The ``change`` instruction informs the PWM thread that a group of values is
provided that needs to be supplied in succession. After that, the signal
will either be stable for a period of up to K steps (using stableK) or for
any length of time (using loopAround). Note that a series of changes must always be
followed by a stable signal. The nextPC of a change instruction always
points to a change instruction.

The ``stable`` instruction can only be part of a change instruction informs
the PWM thread that all signals should be kept stable for N clock ticks.
Only a fixed set of stable instructions are supported: stable4...stable16.

Because the shortest stable signal after a change instruction is 5 clocks,
anything that should be stable for 4 clocks or less needs to be created by a
changeN instruction. Since there are at most eight successive changes in a
PWM signal, that requires at most a change32 instruction (8*4).
