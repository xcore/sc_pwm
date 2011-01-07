========================================================
 PWM  Software Component Testplan 
========================================================

:Authors: GopalaKrishna NL
:Version: 1.0

.. sectnum::


Introduction
============

This *internal* document details the testplan for testing the PWM component.

Features
========

.. feature:: PWM_MULITPLE_PORTS
   :parents: PWM_SINGLE_BIT
   :config_options: 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 |12 | 13 | 14 | 15 | 16

   The PWM_SINGLE_BIT component is configured with an array of ports, thus can produce multiple sychronised pwm signals on 
   multiple 1-bit ports. The config option for this feature is varied from single 1-bit port to sixteen 1-bit ports with increment
   of 1 for test case creation.

.. feature:: PWM_PORT_WIDTH 
   :parents: PWM_MULTI_BIT
   :config_options: 4 | 8 | 16
  

   The PWM_MULTI_BIT component is configured with a 4, 8 & 16 -bit ports, and will produce mutilple synchronised 
   pwm signals on each pin of given port. the port width is passed as run time parameter to PWM_MULTI_BIT
   server function

.. feature:: PWM_RESOLUTION
   :parents: PWM_SINGLE_BIT,PWM_MULTI_BIT
   :config_options: 32 | 64 | 192 | 256 | 640 | 1024

   The PWM resolution is defined as the maximum number of pulses that you can pack into a PWM period. The resolution of 
   each of the components is configurable. The config options for this feature is always multiple of 32
   and tested with only with values 32, 62 192, 256, 640 and 1024.This is passed as a run-time parameter to the relevent 
   server function.

.. feature:: PWM_TIMESTEP
   :parents: PWM_SINGLE_BIT, PWM_MULTI_BIT
   :config_options: 0 | 10 | 50 |100

   Timestep is passed as parameter to configure the port clock. The port clock will be 100MHz divided by two time the 
   given timestep.The time-step width of each of the components is configurable. For example, 
   setting the timestep parameter to 0 will provide a 10 ns minimum time-step.Config options for timestep is test with value 
   0,10,50 & 100. This is passed as a run-time parameter to the relevent server function.

.. feature:: PWM_MODULATION_TYPE
   :parents: PWM_SINGLE_BIT, PWM_MULTI_BIT
   :config_options: 1 | 2 | 3

   The edge of the components is configured with value 1, 2 or 3 depending on the required pulse-width modulation type
   value 1 configures the component as lead edge pwm
   2 configures the component as tail edge pwm
   3 configures the component as Centred variation pwm.

  

Setups
======

.. setup:: REVIEW
  :setup_time: 0

  Reviews require no setup. The review must take place preferably by
  someone other than the implementor.

.. setup:: XK1
  :setup_time: 2

  Setup a host PC running windows with the latest development tools
  and an XK1 dev card attached.

.. setup:: SIMULATOR
  :setup_time: 1

  Setup a host PC with the latest released development tools.

Tests
=====

.. test:: singlebit_demo
   :setup: SIMULATOR
   :configurations: PWM_MULITPLE_PORTS.* , PWM_RESOLUTION.* , PWM_TIMESTEP.* , PWM_MODULATION_TYPE.*
   :features: PWM_SINGLE_BIT

   This test run with dutycycle which varies from 0 to 32.

.. test:: single_bit_test
   :setup: XK1
   :configurations: PWM_MULITPLE_PORTS.* , PWM_RESOLUTION.* , PWM_TIMESTEP.* , PWM_MODULATION_TYPE.*
   :features: PWM_SINGLE_BIT

   This test runs with dutycycle 20 and 200.

.. test:: multibit_demo
   :setup: SIMULATOR
   :configurations: PWM_PORT_WIDTH.* , PWM_RESOLUTION.* , PWM_TIMESTEP.* , PWM_MODULATION_TYPE.*
   :features: PWM_MULTI_BIT

   This test run with dutycycle which varies from 0 to 32.
.. test:: multi_bit_test
   :setup: XK1
   :configurations: PWM_MULITPLE_PORTS.* , PWM_RESOLUTION.* , PWM_TIMESTEP.* , PWM_MODULATION_TYPE.*
   :features: PWM_MULTI_BIT 

   This test runs with dutycycle 20 and 200.
   test

