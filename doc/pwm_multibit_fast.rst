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

#. Make the sort function "wrap" tolerant (using ``(a-b)<0`` rather than
   ``a<b``)

#. Exhaustive testing of the sorting function.

#. Put synchronisation in place between two threads. This can take the form
   of a timer or a timed port.

#. Make the time difference function wrap tolerant (in pwmProgrammer.xc,
   find the todo)

#. Extensive testing of the PWM function

#. Enable three threads to be used to drive 16 bits (@ 80 MIPS or with more
   optimisations).

Performance
-----------

Current performance using 62.5 MIPS threads (8 threads at 500 MHz) is:

* Half a PWM cycle takes approx 16 us, so a full cycle will take 32 us,
  giving around 30 KHz.

* PWM thread requires no more than 62.5 MIPS to keep running without gaps.

Instruction Set
---------------

The PWM thread is programmable by means of a set of instructions that are
provided as a linked list of instructions. Each instruction has a pointer
to a block of memory that contains the next instruction. In addition, each
instruction also contains the next instruction (!). The block of memory
contains parameters for the current instruction, such as the value(s) to
output.

The instructions are::

   setTime  NextPC, NextInstr, Time, Value
   changeN  NextPC, NextInstr, loopEven, Counter, Value, Value*N
   changeN  NextPC, NextInstr, loopOdd, Counter, Value, Value*N
   changeN  NextPC, NextInstr, stableK, dontcare, Value, Value*N

Each instruction contains both a next instruction, and a next program
counter. The next instruction will be executed, and then the next program
counter is used by the next instruction to retrieve the subsequent
instruction.

For example, the ``stable`` instruction informs the PWM thread that all
signals should be kept stable for N clock ticks. Only a fixed set of stable
instructions are supported: stable3...stable8.

The ``change`` instruction informs the PWM thread that a group of values is
provided that needs to be supplied in succession, after that, the signal is
stable for K+2 steps. Only a limited set of change instructions are
supported: change64...change1. Note that a series of changes must always be
followed by a stable signal

Because the shortest stable signal after a change instruction is 5 clocks,
anything that should be stable for 4 clocks or less needs to be created by a
changeN instruction. Since there are at most eight successive changes in a
PWM signal, that requires at most a change32 instruction (8*4).
