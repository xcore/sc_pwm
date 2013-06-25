Programming Guide
=================

Key Files
---------

   * ``pwm_client.xc``: Contains the XC implementation of the PWM Client API
   * ``pwm_server.xc``: Contains the XC implementation of the PWM Server task

Usage
-----

The following 2 functions are designed to be called from an XC file.

   * ``foc_pwm_put_parameters()`` Client function designed to be called from an XC file each time a new set of PWM parameters are required.
   * ``foc_pwm_do_triggered()``, Server function designed to be called from an XC file. It runs on its own core, and receives data from the PWM Client.

The following PWM definitions are required. These are set in ``pwm_common.h`` or ``app_global.h``

   * PWM_RES_BITS 12 // Number of bits used to define number of different PWM pulse-widths
   * LOCK_ADC_TO_PWM 1 // Define sync. mode for ADC sampling. Default 1 is 'ADC synchronised to PWM'
   * PWM_SHARED_MEM 0 // 0: Use c_pwm channel for pwm data transfer
   * NUM_PWM_BUFS 2  // Double-buffered
   * PORT_RES_BITS 5 // PWM port width resoltion (e.g. 5 for 32-bits) 
   * PWM_DEAD_TIME ((12 * MICRO_SEC + 5) / 10) // 1200ns PWM Dead-Time WARNING: Safety critical
   * PLATFORM_REFERENCE_HZ // Platform Reference Frequency
   * MAX_SPEC_RPM // Maximium specified motor speed

Test Applications
=================

Pulse-Width-Modulation Interface (PWM) Xcore Simulator
------------------------------------------------------

To get started with this application, run through the instructions in the quickstart guide.
The application is in app_test_pwm
The quickstart guide is in doc_quickstart/pwm/index.rst

This application uses module_pwm_foc to process simulated PWM input test data.
The PWM output data is transmitted on a 6 ports: High-leg and Low-leg of a balanced-line for each of the 3 motor phases. Each port is 1-bit wide with a 32-bit buffer.
The PWM inputs (pulse-widths) are received in a PWM data structure.

Makefile
........

The Makefile is found in the top level directory of the application (e.g. app_test_pwm)

The application is for the simulator. 
However the platform being simulated is a Motor control board.
The Makefile TARGET variable needs to be set to Motor control board being used.
E.g. If the platform configuration file is XP-MC-CTRL-L2.xn, then
TARGET = XP-MC-CTRL-L2

Only one motor is supported.

Running the application with the Command Line Tools
...................................................

Move to the top level directory of the application (e.g. app_test_pwm), and type

   * xmake clean
   * xmake all

To start the test type

   * xsim --plugin LoopbackPort.dll "-port tile[1] XS1_PORT_1D 1 0 -port tile[1] XS1_PORT_1N 1 0 -port tile[1] XS1_PORT_1E 1 0 -port tile[1] XS1_PORT_1O 1 0 -port tile[1] XS1_PORT_1F 1 0 -port tile[1] XS1_PORT_1P 1 0 -port tile[1] XS1_PORT_1A 1 0 -port tile[1] XS1_PORT_1K 1 0 -port tile[1] XS1_PORT_1B 1 0 -port tile[1] XS1_PORT_1L 1 0 -port tile[1] XS1_PORT_1C 1 0 -port tile[1] XS1_PORT_1M 1 0" bin/app_test_pwm.xe

Test results will be printed to standard-out.
The whole test takes upto 2 minutes to run.

For a explanation of the test results refer to the quickstart guide in doc_quickstart/pwm/index.rst

Trouble-shooting
................

The information in the 'check results' column may disappear.
This and almost any other problem are probably due to NOT setting the port configuration correctly when calling xsim

The printout may pause.
As mentioned above, depending on the speed of your PC (or Mac), there can be upto 1 minute gap between printed lines.
