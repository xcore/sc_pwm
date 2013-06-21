Programming Guide
=================

Key Files
---------

   * ``hall_client.xc``: Contains the XC implementation of the Hall Client API
   * ``hall_server.xc``: Contains the XC implementation of the Hall Server task

Usage
-----

The following 2 functions are designed to be called from an XC file.

   * ``foc_hall_get_parameters()`` Client function designed to be called from an XC file each time a new set of Hall parameters are required.
   * ``foc_hall_do_multiple()``, Server function designed to be called from an XC file. It runs on its own core, and receives data from all Hall motor ports.

The following Hall definitions are required. These are set in ``hall_common.h`` or ``app_global.h``

   * HALL_PER_REV  // No of Hall positions per Revolution
   * HALL_PHASE_MASK // Bit Mask for [C B A] phase info.
   * HALL_NERR_MASK // Bit Mask for error status bit (1 == No Errors)
   * PLATFORM_REFERENCE_HZ // Platform Reference Frequency
   * HALL_FILTER // Hall filter switch (0 == Off)
   * MAX_SPEC_RPM // Maximium specified motor speed

Test Applications
=================

Hall Sensor Interface (HALL) Xcore Simulator
--------------------------------------------------

To get started with this application, run through the instructions in the quickstart guide.
The application is in app_test_hall
The quickstart guide is in doc_quickstart/hall/index.rst

This application uses module_foc_hall to process simulated Hall input test data.
The Hall input data is received on a 4-bit port.
The Hall outputs (phase-values and error-status) are transmitted in a Hall data structure.

Makefile
........

The Makefile is found in the top level directory of the application (e.g. app_test_hall)

The application is for the simulator. 
However the platform being simulated is a Motor control board.
The Makefile TARGET variable needs to be set to Motor control board being used.
E.g. If the platform configuration file is XP-MC-CTRL-L2.xn, then
TARGET = XP-MC-CTRL-L2

The maximum number of motors supported in currently 2, this is set in app_global.h: e.g.
#define NUMBER_OF_MOTORS 2

Running the application with the Command Line Tools
...................................................

Move to the top level directory of the application (e.g. app_test_hall), and type

   * xmake clean
   * xmake all

To start the test type

   * xsim --plugin LoopbackPort.dll "-port tile[1] XS1_PORT_4B 4 0 -port tile[1] XS1_PORT_4F 4 0 -port tile[1] XS1_PORT_4A 4 0 -port tile[1] XS1_PORT_4E 4 0" bin/app_test_hall.xe

Test results will be printed to standard-out.
Remember this is a simulator, and is very slow.
There may be gaps of upto 1 minute between each printed line.
The whole test takes upto 10 minutes to run.

For a explanation of the test results refer to the quickstart guide in doc_quickstart/hall/index.rst

Trouble-shooting
................

The information in the 'check results' column may disappear.
This and almost any other problem are probably due to NOT setting the port configuration correctly when calling xsim

The printout may stop.
As mentioned above, depending on the speed of your PC (or Mac), there can be upto 1 minute gap between printed lines.
