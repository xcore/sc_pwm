Pulse Width Modulation (PWM) Test Application Programming Overview
==================================================================

.. _test_pwm_Programming:

This file should be read in conjunction with the Quick-Start guide for the PWM Test-bench

The generator runs through a set of tests, these are specified formally as a *test vector* and transmitted to the test checker. For each test the generator creates the required pulse-width and sends this to the PWM Client. The PWM Client in turn sends the pulse-width to the PWM Server. The PWM Server converts the pulse-width into a PWM wave-train and drives this onto the output pins. The 3 PWM Capture cores sample their respective input pins every 32-bits, if a new sample is detected this is transmitted to the PWM Checker. The PWM Checker stores the raw PWM data in a buffer until such time when it can be checked. The PWM test checker also reads the specification in the received test vector. The received PWM data is then checked for correctness against the test vector specification.

The following tests are always performed
   #. A Small width pulse: for slow speeds
   #. A Large width pulse: for fast speeds
   #. The 'Dead-Time' gap between adjacent High-Leg and Low-Leg edges

The following tests are optional
   #. A Narrow width pulse: A 32-bit wide pulse for testing Minimum and Maximum speeds
   #. An Equal width pulse: for Square Wave
   #. ADC tests: Measures accurracy of PWM to ADC trigger

The options are selected by editing the flags in the file pwm_tests.txt

How To Instrument the Code to Use ``xSCOPE`` 
--------------------------------------------

In order to instrument code to use xSCOPE the following actions are required. (For this application they have already been done) :-

   #. In the ``Makefile`` the option ``-fxscope`` needs to be added to the ``XCC`` flags.
   #. In the ``xC`` files that use xSCOPE functions, the header file <xscope.h> needs to be included.
   #. In the ``main.xc`` file, the xSCOPE initialisation function xscope_user_init() needs to be added.
   #. In each ``xC`` file that uses xSCOPE to plot variables, one or more xSCOPE capture functions are required.

The above requirements are discussed in more detail below in the section ``Look at the Code``. Now rebuild the code as follows:-

Look at the Code
----------------

The steps below are designed to guide an initial understanding of how the testbench is constructed. More detail on the testbench structure can also be found in the section below (``Testbench Structure``).

   #. Examine the application code. In xTIMEcomposer, navigate to the ``src`` directory under ``app_test_pwm``  and double click on the ``main.xc`` file within it. The file will open in the central editor window.
   #. Review the ``main.xc`` and note that main() runs 6 tasks on 6 logical cores in parallel.

         * ``gen_all_pwm_test_data()`` Generates test data and pulse-widths on channels c_gen_chk and c_gen_pwm respectively.
         * ``foc_pwm_do_triggered()`` is the PWM Server, receiving pulse-widths on channel c_gen_pwm, and generating raw PWM data on an array of 32-bit buffered output ports(``pb32_pwm_hi`` and ``pb32_pwm_lo``), and the PWM-to-ADC trigger on channel ``c_pwm2adc_trig``
         * ``capture_pwm_leg_data()`` captures the raw PWM data from either the High-Leg or Low-leg ports which has been looped back onto a set of input pins, and transmits this over a channel to the Checker core
         * ``capture_pwm_trigger_data()`` captures the raw PWM data from the PWM-to-ADC trigger channel which has been looped back onto a set of input pins, and transmits this over channel c_cap_chk to the Checker core.
         * ``check_pwm_server_data()`` receives raw PWM data from a number of channels connected to Capture cores, checks it, and displays the results. ``gen_all_pwm_test_data()`` and ``check_all_pwm_server_data()`` both produce display information in parallel. 
         * ``config_all_ports()`` configures the timers on all ports used to capture PWM-data. These ports are all configured to run from the same clock so that their times are all synchronised.
         * The other 2 functions in ``main.xc`` are ``init_locks()`` and ``free_locks()``. These are used to control a MutEx which allows only one core at a time to print to the display.
         * As well as ``main()``, there is a function called ``xscope_user_init()``, this is called before main to initialise xSCOPE capability. In here are registered the 3 PWM signals that were described above, and seen in the xSCOPE viewer.

   #. Find the ``app_global.h`` header. At the top are the xSCOPE definitions, followed by the motor definitions which are specific to the type of motor being used and are currently set up for the LDO motors supplied with the development kit. Next down are the PWM definitions.
   #. Note in ``app_global.h`` the define VERBOSE_PRINT used to switch on verbose printing. An example of this can be found in file ``pwm_results.txt``.
   #. Find the file ``generate_pwm_tests.xc``. In here the function ``do_pwm_test()`` handles the PWM output data via the PWM Client function ``foc_pwm_put_parameters()``. It communicates with the PWM server function ``foc_pwm_do_triggered()`` via channel ``c_gen_pwm``. Before ``foc_pwm_put_parameters()``, are the xSCOPE instructions used to capture the values seen in the xSCOPE viewer.
   #. Find the ``pwm_tests.txt`` file. In the left hand column are a set of flags to switch On/Off various sets of tests.
   #. Now that the application has been run with the default settings, you could try the following alterations.

      * Test PWM Phase_B, by altering 'A' to 'B' in the left hand column.
      * Switch off all the optional tests, by setting the flags in the left hand column to 0 (zero).

   #. Make this change and then re-run the simulation (no need to re-build). The test harness will run a lot quicker. An example of the verbose printout for the minimum set of tests is in file ``pwm_min_results.txt``.
   #. To further explore the capabilities of the simulator, find the items under ``XMOS Examples:Simulator`` in the xSOFTip browser pane. Drag one of them into the Project Explorer to get started.

Testbench Structure
-------------------

The test application uses the following channels:-

   #. c_tst: Transmits test vectors from Generator to Checker core
   #. c_pwm2adc_trig: Transmits synchronisation trigger pulse from PWM server to ADC server
   #. c_pwm: Transmits required pulse-width from PWM client to PWM server
   #. c_adc: Transmitting raw PWM data from the ADC-Capture to the Checker core
   #. c_hi_leg[]: An array of channels for transmitting raw PWM data from the High-Leg-Capture to the Checker core
   #. c_lo_leg[]: An array of channels for transmitting raw PWM data from the Low-Leg-Capture to the Checker core

The test application uses the following ports:-

   #. pb32_pwm_hi[]: An array of buffered output ports for setting the High-Leg PWM voltage
   #. pb32_pwm_lo[]: An array of buffered output ports for setting the Low-Leg PWM voltage
   #. p16_adc_sync: A dummy 16-bit input port used for synchronising the PWM to ADC trigger
   #. pb32_tst_hi[]: An array of buffered input ports for the testing the High-Leg PWM voltage
   #. pb32_tst_lo[]: An array of buffered input ports for the testing the Low-Leg PWM voltage
   #. p8_tst_sync: A dummy 8-bit ouput port used for testing the PWM to ADC trigger

The test application uses the following clocks:-

   #. pwm_clk: Used for timing the PWM output wave-train
   #. comm_clk: A common clock used to synchronise the timers on all test ports

The output pins driven by the PWM server are looped back to the PWM Capture input pins using the *loopback plugin* functionality included within the xSIM simulator, which allows arbitrary definition of pin level loopbacks.
