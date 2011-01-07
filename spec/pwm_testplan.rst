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
   :setup: XK1
   :configurations: PWM_MULITPLE_PORTS.* , PWM_RESOLUTION.* , PWM_TIMESTEP.* , PWM_MODULATION_TYPE.*
   :features: PWM_SINGLE_BIT_DEMO

   This test run with dutycycle which varies from 0 to 32.

.. test:: single_bit_test
   :setup: SIMULATOR
   :configurations: PWM_MULITPLE_PORTS.* , PWM_RESOLUTION.* , PWM_TIMESTEP.* , PWM_MODULATION_TYPE.*
   :features: PWM_SINGLE_BIT

   This test runs with dutycycle 20 and 200.

.. test:: multibit_demo
   :setup: XK1
   :configurations: PWM_PORT_WIDTH.* , PWM_RESOLUTION.* , PWM_TIMESTEP.* , PWM_MODULATION_TYPE.*
   :features: PWM_MULTI_BIT_DEMO

   This test run with dutycycle which varies from 0 to 32.
.. test:: multi_bit_test
   :setup: SIMULATOR
   :configurations: PWM_MULITPLE_PORTS.* , PWM_RESOLUTION.* , PWM_TIMESTEP.* , PWM_MODULATION_TYPE.*
   :features: PWM_MULTI_BIT 

   This test runs with dutycycle 20 and 200.
   test

