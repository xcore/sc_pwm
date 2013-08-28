Pulse Width Modulation (PWM) Simulator Testbench
================================================

.. _test_pwm_Quickstart:

This application is an xSIM test harness for the pulse width modulation interface using xTIMEcomposer Studio. It tests the PWM functions in the ``Symmetrical Pulse Wave Modulation (PWM) Component for FOC`` xSOFTip component and directs test results to STDOUT.

No hardware is required to run the test harness.

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

Having run the testbench once, now re-run it to dump a VCD trace so that the waveform output of the PWM can be visualised. This can require a lot of memory and may slow down the simulator so first ensure enough memory has been requested in the xTIMEcomposer init file. Go to the root directory where the XMOS tools are installed. Then edit file ``xtimecomposer_bin/xtimecomposer.exe.ini`` and ensure the requested memory is at least 2 GBytes (``-Xmx2048m``)

Now launch xTIMEcomposer and switch on VCD tracing as follows

   #. Repeat the actions described above but in the Run Configurations dialog perform the additional steps as follows:
   #. Click ``Apply``
   #. Now select the ``Signal Tracing`` tab.
   #. Tick the ``Enable Signal Tracing`` box
   #. Click the ``Add`` button
   #. Select ``tile[1]``
   #. Tick the ``ports`` box
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
   #. In the Signals window, expand the signal tree as far as tile[1]->ports->XS1_PORT_1D, now double click on the signal PORT_M1_HI_A
   #. A waveform should appear in the right column of the Waveform window. This is for Phase_A of the High-Leg.
   #. Repeat the above process for tile[1]->ports->XS1_PORT_1A->PORT_M1_LO_A, Phase_A of the Low-Leg. 
   #. Finally, repeat the above process for tile[1]->ports->XS1_PORT_8C->tWaiting, the PWM-to-ADC trigger. 
   #. To view all the trace click the ``Zoom Fit`` icon (House) at the right of the Waveform window view-bar
   #. You should now see a train of different pulse widths in traces in PORT_M1_HI_A and PORT_M1_LO_A, and a series of spikes in trace tWaiting

Notice that the pulses in PORT_M1_LO_A are slighlty wider than the pulses in PORT_M1_HI_A. This is because the Low-leg has been extended to prevent the potentially dangerous situation of the High-Leg and Low-leg switching at the same time. The PWM-to-ADC trigger should occur 1/4 of a PWM period before the centre of the pulse.

.. figure:: vcd_pwm.*
   :width: 100%
   :align: center
   :alt: Example VCD Waveform

   VCD Waveform

Using The ``xSCOPE`` (xmt) File
-------------------------------

The values of variables in the program can be inspected using the xSCOPE functionality. This allows time-varying changes in variable values to be plotted in a similar manner to using an oscilloscope for real-signals. 

Now rebuild the code as follows:-

   #. In the ``Run Configurations`` dialogue box (see above), select the xSCOPE tab
   #. Now select the ``Offline`` button, then click ``Apply``, then click ``Run``

The program will compile and build with the warning ``Constraints checks PASSED WITH CAVEATS``. This is because xSCOPE introduces an unspecified number of chan-ends. Test output will start to appear in the Console window. When the test has completed, move to the Project explorer window. In the app_test_hall directory there should be a file called ``xscope.xmt``. Double click on this file, and the xSCOPE viewer should launch. On the left-hand side of the viewer, under ``Captured Metrics``, select the arrow next to ``n``. A sub menu will open with 3 signals listed: ``PWM_A``, ``PWM_B``, and ``PWM_C``. Use the boxes to the left of each signal to switch the traces on and off. The tests take about 2.71ms. The tick marks at the bottom of the window show at what time xSCOPE sampled the signals. The signal is only sampled when the test generator writes a new value to the Output-pins. This is currently approximately every 41.us:

   #. First, switch off all traces except the ``PWM_A`` trace. This shows the pulse width being requested of the PWM Server. It starts off at a value of 32 for a narrow width, moves through 256, 2048, 3840 and ending on 3944 for the maximum width.
   #. Traces PWM_B and PWM_C will be empty. Due to timing constraints, only one PWM phase can be tested at a time. The other phases can be tested by selecting them in the test options file ``pwm_tests.txt``.

Note well, to view all the trace click the ``Zoom Fit`` icon (House) at the right of the Waveform window view-bar. To zoom in/out click the 'plus/minus' icons to the left of the ``Zoom Fit`` icon

.. figure:: xscope_pwm.*
   :align: center
   :width: 100%
   :alt: Example xSCOPE trace

   xSCOPE Trace

To learn more about xSCOPE look at the ``How To`` by selecting ``Window --> Show_View --> How_To_Browser``. Then in the search box type ``xscope``. This should find the section titled ``XMOS Examples: Instrumentation and xSCOPE``. In the sub-section ``Event Examples`` you will find more information on capturing events. In the sub-section ``IO Examples`` you will find more information on re-directing I/O using xSCOPE.
