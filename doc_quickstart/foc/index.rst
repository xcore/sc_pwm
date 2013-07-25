Pulse Width Modulation (PWM) Simulator Testbench
================================================

.. _test_pwm_Quickstart:

This application is an xSIM test harness for the pulse width modulation interface using xTIMEcomposer Studio. It tests the PWM functions in the ``Symmetrical Pulse Wave Modulation (PWM) Component for FOC`` xSOFTip component and directs test results to STDOUT.

No hardware is required to run the test harness.

The test application uses a maximum of 6 cores containing the following components:-
   #. A test-vector generator and the PWM Client under test
   #. The PWM Server under test (generates raw PWM data)
   #. 2 PWM-Leg capture cores (captures raw PWM data from either the High-Leg or Low-Leg ports via 'loopback')
   #. A PWM-adc capture core (captures raw PWM data from the pwm-to-adc trigger channel via 'loopback')
   #. The test results checker

<<<<<<< HEAD
The test application uses the following channels:-
   #. c_gen_chk: Transmits test vectors from Generator to Checker core
   #. c_pwm2adc_trig: Transmits synchronisation trigger pulse from PWM server to ADC server
   #. c_gen_pwm: Transmits required pulse-width from PWM client (in Generator core) to PWM server core
   #. c_cap_chk: Channel for sending PWM-to-ADC trigger data from Capture to Checker core
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

=======
>>>>>>> ec7ded3699a5286fcdbfdf25e23f8341f0295ace
Import and Build the Application
--------------------------------

   1. Open xTIMEcomposer and check that it is operating in online mode. Open the edit perspective (Window->Open Perspective->XMOS Edit).
   #. Locate the ``Pulse Width Modulation Test Harness`` item in the xSOFTip pane on the bottom left of the window and drag it into the Project Explorer window in the xTIMEcomposer. This will also cause the modules on which this application depends to be imported as well. These modules are: ``module_pwm_foc``, and ``module_locks``.
   #. Click on the app_test_pwm item in the Explorer pane then click on the build icon (hammer) in xTIMEcomposer. 
   #. Check the console window to verify that the application has built successfully. 

For help in using xTIMEcomposer, try the xTIMEcomposer tutorial, that can be found by selecting Help->Tutorials from the xTIMEcomposer menu.

Note that the Developer Column in the xTIMEcomposer on the right hand side of your screen 
provides information on the xSOFTip components you are using. 
Select the ``module_pwm_foc`` component in the Project Explorer, and you will see its description together with API documentation. 
Having done this, click the ``back`` icon until you return to this quickstart guide within the Developer Column.

Configure And Run The Simulator
-------------------------------

   #. Double click ``app_test_pwm`` in the left hand ``Project Explorer`` window.
   #. Click on the arrow next to the ``Run`` icon (the white arrow in the green circle) in the top menu bar. Select ``Run Configurations``
   #. In ``Run Configurations`` window, double click on ``xCORE Application``.
   #. You should find that the left hand side of the ``Run Configurations`` window, should be populated with details from the ``app_test_pwm`` project. If the details are blank, this is probably because the project was not selected correctly in the first step. If this has happened, and the problem persists, browse to the correct project, and select the executable.
   #. Select the ``run on simulator`` button.
   #. Now setup the loopbacks between the stimulus generator and the
      PWM component.

      #. Select the ``Simulator`` tab.
      #. Select the ``Loopback`` tab.
      #. Click ``Enable pin connections``.
      #. Click ``Add`` and dialogue boxes will appear for Tile, Port, Offset and Width. These should be filled in with the following information and steps shown in the table below. The second time the simulator is run, it is only necessary to click on the ``Run`` icon (the white arrow in the green circle) in the top menu.

                +-------+--------+------------+-------+------+
                | From: |    1   | XS1_PORT_1A|   0   |   1  |
                +-------+--------+------------+-------+------+
                | To:   |    1   | XS1_PORT_1K|   0   |   1  |
                +-------+--------+------------+-------+------+

      #. Click ``Add`` again and then do the below

                +-------+--------+------------+-------+------+
                | From: |    1   | XS1_PORT_1B|   0   |   1  |
                +-------+--------+------------+-------+------+
                | To:   |    1   | XS1_PORT_1L|   0   |   1  |
                +-------+--------+------------+-------+------+

      #. Click ``Add`` again and then do the below

                +-------+--------+------------+-------+------+
                | From: |    1   | XS1_PORT_1C|   0   |   1  |
                +-------+--------+------------+-------+------+
                | To:   |    1   | XS1_PORT_1M|   0   |   1  |
                +-------+--------+------------+-------+------+

      #. Click ``Add`` again and then do the below

                +-------+--------+------------+-------+------+
                | From: |    1   | XS1_PORT_1D|   0   |   1  |
                +-------+--------+------------+-------+------+
                | To:   |    1   | XS1_PORT_1N|   0   |   1  |
                +-------+--------+------------+-------+------+

      #. Click ``Add`` again and then do the below

                +-------+--------+------------+-------+------+
                | From: |    1   | XS1_PORT_1E|   0   |   1  |
                +-------+--------+------------+-------+------+
                | To:   |    1   | XS1_PORT_1O|   0   |   1  |
                +-------+--------+------------+-------+------+

      #. Click ``Add`` again and then do the below

                +-------+--------+------------+-------+------+
                | From: |    1   | XS1_PORT_1F|   0   |   1  |
                +-------+--------+------------+-------+------+
                | To:   |    1   | XS1_PORT_1P|   0   |   1  |
                +-------+--------+------------+-------+------+

      #. Click ``Apply``
      #. Click ``Run``


Test Results 
------------

After a few seconds, output will start to appear in the console window. A dot is printed every time a PWM client request is made. This gives confidence that the test harness is doing something. The test lasts about 2 minutes and should complete with the message "ALL TESTS PASSED". If any tests fail, extra output will be generated giving details on the test(s) that failed.

For background on the PWM component refer to the documentation for ``Symmetrical Pulse Wave Modulation (PWM) Component for FOC`` which can be accessed via the xSOFTip Explorer pane in xTIMEcomposer.

An example of working test output from a working PWM component can be found in a file named ``pwm_results.txt``


Using The ``Value Change Dump`` (VCD) File
------------------------------------------

Having run the testbench once, now re-run it to dump a VCD trace so that the waveform output of the PWM can be visualised. This can require a lot of memory and may slow down the simulator so first ensure enough memory has been requested in the xTIMEcomposer init file. Go to the root directory where the XMOS tools are installed. Then edit file ``xtimecomposer_bin/xtimecomposer.exe.ini`` and ensure the requested memory is at least 4 GBytes (``-Xmx4096m``)

Now launch xTIMEcomposer and switch on VCD tracing as follows

   #. Repeat the actions described above but in the Run Configurations dialog perform the additional steps as follows:
   #. Click ``Apply``
   #. Now select the ``Signal Tracing`` tab.
   #. Tick the ``Enable Signal Tracing`` box
   #. Click the ``Add`` button
   #. Select ``tile[1]``
   #. Tick the ``+details`` box
   #. Click ``Apply``
   #. Click ``Run``

After the simulation has been running for approximately 30 seconds, kill the simulations before testing has finished by clicking on the red square button in the view-bar for the console window. 

When the executable has stopped running, view the VCD file as follows

   #. In the main toolbar select Tools->Waveform_Analyzer->Load_VCD_File
   #. Browse to the application root directory or where the VCD file was created.
   #. Select the VCD file and click the ``OK`` button.
   #. The VCD file will start loading, this may take some time, 
   #. WARNING If an ``out-of-memory`` error occurs, increase the xTIMEcomposer memory (described above) to be larger than the VCD file.
   #. When the VCD file has loaded correctly, a list of ports should appear in the ``Signals`` window.
   #. If not already active, open a ``Waveform`` window as follows:-
   #. In the main toolbar, select Window->Show_View->Waves
   #. Now add some signals to the Waves window as follows:-
<<<<<<< HEAD
   #. In the Signals window, find tile[1]->ports->XS1_PORT_1D, and double-click on it.
=======
   #. In the Signals window, select tile[1]->ports->XS1_PORT_1N, and drag this to the left-hand column of the Waveform window
   #. If this does not work first time, try leaving a few seconds between selecting and dragging
>>>>>>> ec7ded3699a5286fcdbfdf25e23f8341f0295ace
   #. When successful a set of 12 waveforms should appear in the right column of the Waveform window. These are for Phase_A of the High-Leg
   #. Repeat the above process for tile[1]->ports->XS1_PORT_1A, (Phase_A of the Low-Leg), and tile[1]->ports->XS1_PORT_8C, (the PWM-to-ADC trigger) 
   #. To view all the trace click the ``Zoom Fit`` icon (House) at the right of the Waveform window view-bar
<<<<<<< HEAD
   #. It should be possible to see a train of different pulse widths in traces in PORT_M1_HI_A and PORT_M1_LO_A, and a series of spikes in trace XS1_PORT_8C[Waiting]
=======
   #. You should now see a train of different pulse widths in traces in PORT_M2_HI_A and PORT_M2_LO_A, and a series of spikes in trace XS1_PORT_8C[Waiting]
>>>>>>> ec7ded3699a5286fcdbfdf25e23f8341f0295ace

Notice that the pulses in PORT_M1_LO_A are slighlty wider than the pulses in PORT_M1_HI_A. This is because the Low-leg has been extended to prevent the potentially dangerous situation of the High-Leg and Low-leg switching at the same time. The PWM-to-ADC trigger should occur 1/4 of a PWM period before the centre of the pulse.

Using The ``xSCOPE`` (xmt) File
-------------------------------

The values of variables in the program can be inspected using the xSCOPE functionality. This allow time-varying changes in variable values to be plotted in a similar manner to using an oscilloscope for real-signals. In order to use xSCOPE the following actions are required. (For this application they have already been done) :-

   #. In the ``Makefile`` the option ``-fxscope`` needs to be added to the ``XCC`` flags.
   #. In the ``xC`` files that use xSCOPE functions, the header file <xscope.h> needs to be included.
   #. In the ``main.xc`` file, the xSCOPE initialisation function xscope_user_init() needs to be added.
   #. In each ``xC`` file that uses xSCOPE to plot variables, one or more xSCOPE capture functions are required.

The above requirements are discussed in more detail below in the section ``Look at the Code``. Now rebuild the code as follows:-

   #. In the ``Run Configurations`` dialogue box (see above), select the xSCOPE tab
   #. Now select the ``Offline`` button, then click ``Apply``, then click ``Run``

The program will build and start to produce test output in the Console window. When the test has completed, move to the Project explorer window. In the app_test_hall directory there should be a file called ``xscope.xmt``. Double click on this file, and the xSCOPE viewer should launch. On the left-hand side of the viewer, under ``Captured Metrics``, select the arrow next to ``n``. A sub menu will open with 3 signals listed: ``PWM_A``, ``PWM_B``, and ``PWM_C``. Use the boxes to the left of each signal to switch the traces on and off. The tests take about 2.71ms. The tick marks at the bottom of the window show at what time xSCOPE sampled the signals. The signal is only sampled when the test generator writes a new value to the Output-pins. This is currently approximately every 41.us:

   #. First, switch off all traces except the ``PWM_A`` trace. This shows the pulse width being requested of the PWM Server. It starts off at a value of 32 for a narrow width, moves through 256, 2048, 3840 and ending on 3944 for the maximum width.
   #. Traces PWM_B and PWM_C will be empty. Due to timing constraints, only one PWM phase can be tested at a time. The other phases can be tested by selecting them in the test options file ``pwm_tests.txt``.

Note well, to view all the trace click the ``Zoom Fit`` icon (House) at the right of the Waveform window view-bar. To zoom in/out click the 'plus/minus' icons to the left of the ``Zoom Fit`` icon

To learn more about xSCOPE look at the ``How To`` by selecting ``Window --> Show_View --> How_To_Browser``. Then in the search box type ``xscope``. This should find the section titled ``XMOS Examples: Instrumentation and xSCOPE``. In the sub-section ``Event Examples`` you will find more information on capturing events. In the sub-section ``IO Examples`` you will find more information on re-directing I/O using xSCOPE.


Look at the Code
----------------

<<<<<<< HEAD
=======
The steps below are designed to guide an initial understanding of how the testbench is constructed. More detail on the testbench structure can also be found in the section below (``Testbench Structure``).

>>>>>>> ec7ded3699a5286fcdbfdf25e23f8341f0295ace
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
   #. Note in ``app_global.h`` the define PRINT_TST_PWM used to switch on verbose printing. An example of this can be found in file ``pwm_results.txt``.
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

