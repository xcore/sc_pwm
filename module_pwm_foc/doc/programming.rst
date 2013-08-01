Programming Guide
=================

For each motor, the main Motor Control loop, test harness, or other supervisory function, calculates the required pulse-width for the 3 motor phases. This information is then passed by calling the PWM Client function. The PWM Server runs in its own logical core and receives pulse-width input data from the PWM Client. Each pulse-width is converted into a bit-stream that is timed to rise (to one) and fall (to zero) at a defined time in order to create a PWM wave-train with the required mark/space ratio. This bit stream is driven onto 6 sets of output pins. High-leg and Low-leg (of a balanced-line) for each of the 3 motor-phases.

The pulse-width information is transmitted from the PWM Client to the PWM Server, either down a channel, or via shared memory. If a channel is used, the PWM server evaluates the bit-pattern and time-stamp information. Conversly, if shared memory is used, the PWM Client evaluates this information. By default the information is passed over a channel. If memory is plentiful, but timing on the PWM server core can NOT be met, then the shared memory option should be tried.

The PWM resolution determines how many different voltages may be applied to the motor coils. For example, a resolution of 12 bits will allow a PWM wave with a period of 4096 bits. Assuming this period starts low (at zero) and finishes high (at one), then there are 4095 points inbetween at which the pulse can rise. If the pulse rises early, the majority of the pulse will consist of ones, this will create a large voltage in the motor, and a fast speed. Conversly a pulse which rises late will consist mainly of zeros, this will create a small voltage in the motor, and a slow speed. If the patterns of all-ones and all-zeros (no voltage) are included, 4096 different voltages are possible. Due to symmetry constraints, there should be an even number of ones in a pulse. This reduces the PWM resolution from 4096 to 2048 possible voltages.

The PWM to ADC trigger is used to signal to the ADC module when it should sample the motor current, in order to estimate the back EMF in the motor coils. The trigger is required because the sampling should be done in the middle of a high portion of the PWM pulse. That is, when the PWM bitstream is held at one.

Key Files
---------

   * ``pwm_client.xc``: Contains the XC implementation of the PWM Client API
   * ``pwm_server.xc``: Contains the XC implementation of the PWM Server task

Usage
-----

The following 2 functions are designed to be called from an XC file.

   * ``foc_pwm_put_parameters()`` Client function designed to be called from an XC file each time a new set of PWM parameters is required.
   * ``foc_pwm_do_triggered()``, Server function designed to be called from an XC file. It continually runs in its own core, and receives data from the PWM Client.

The following PWM definitions are required. These are set in ``pwm_common.h`` or ``app_global.h``

   * PWM_RES_BITS 12 // Number of bits used to define number of different PWM pulse-widths
   * LOCK_ADC_TO_PWM 1 // Define sync. mode for ADC sampling. Default 1 is 'ADC synchronised to PWM'
   * PWM_SHARED_MEM 0 // 0: Use c_pwm channel for pwm data transfer
   * NUM_PWM_BUFS 2  // Double-buffered
   * PORT_RES_BITS 5 // PWM port width resolution (e.g. 5 for 32-bits) 
   * PWM_DEAD_TIME ((12 * MICRO_SEC + 5) / 10) // 1200ns PWM Dead-Time WARNING: Safety critical
   * PLATFORM_REFERENCE_HZ // Platform Reference Frequency
   * MAX_SPEC_RPM // Maximium specified motor speed

Test Applications
=================

Pulse-Width-Modulation Interface (PWM) xCORE Simulator
------------------------------------------------------

To get started with this application, run through the instructions in the Quickstart Guide, accessible via the ``Pulse Width Modulation (PWM) For FOC Test Harness`` item in the xSOFTip explorer pane within xTIMEcomposer.

This application uses module_pwm_foc to process simulated PWM input test data. The PWM output data is transmitted on a 6 ports: High-leg and Low-leg of a balanced-line for each of the 3 motor phases. Each port is 1-bit wide with a 32-bit buffer.
The PWM inputs (pulse-widths) are received in a PWM data structure.

Makefile
........

The Makefile is found in the top level directory of the application (e.g. app_test_pwm)

The application is for the simulator. 
However the platform being simulated is a Motor control board.
The Makefile TARGET variable needs to be set to the Motor control board being used.
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
The whole test takes up to 2 minutes to run.

For an explanation of the test results refer to the quickstart guide ``Pulse Width Modulation (PWM) Simulator Testbench``.

Trouble-shooting
................

The information in the 'check results' column may disappear.
This and almost any other problem are probably due to NOT setting the port configuration correctly when calling xsim

The printout may pause.
As mentioned above, depending on the speed of your PC (or Mac), there can be up to 1 minute gap between printed lines.

Example Usage In A Motor Control Loop
-------------------------------------

The PWM component can be used in conjunction with the ADC component. For more detail on the ADC component refer to the quick-start guide ``Analogue to Digital Conversion (ADC) Simulator Test-bench``. The code example below demonstrates how to use the PWM-to-ADC trigger to synchronise the ADC sampling to the PWM pulse. It shows part of a main.xc file. In here a set of ``par`` statements are used to run the PWM server and the ADC Server in parallel with a function called ``run_motor``, which contains all the code for a motor control loop.

::

  // PWM ports
  on tile[MOTOR_TILE]: buffered out port:32 pb32_pwm_hi[NUMBER_OF_MOTORS][NUM_PWM_PHASES] 
    = {  {PORT_M1_HI_A, PORT_M1_HI_B, PORT_M1_HI_C} ,{PORT_M2_HI_A, PORT_M2_HI_B, PORT_M2_HI_C} };
  on tile[MOTOR_TILE]: buffered out port:32 pb32_pwm_lo[NUMBER_OF_MOTORS][NUM_PWM_PHASES] 
    = {  {PORT_M1_LO_A, PORT_M1_LO_B, PORT_M1_LO_C} ,{PORT_M2_LO_A, PORT_M2_LO_B, PORT_M2_LO_C} };
  on tile[MOTOR_TILE]: clock pwm_clk[NUMBER_OF_MOTORS] = { XS1_CLKBLK_5 ,XS1_CLKBLK_4 };
  on tile[MOTOR_TILE]: in port p16_adc_sync[NUMBER_OF_MOTORS] = { XS1_PORT_16A ,XS1_PORT_16B }; // NB Dummy port
  
  // ADC ports
  on tile[MOTOR_TILE]: buffered in port:32 pb32_adc_data[NUM_ADC_DATA_PORTS] 
    = { PORT_ADC_MISOA ,PORT_ADC_MISOB }; 
  on tile[MOTOR_TILE]: out port p1_adc_sclk = PORT_ADC_CLK; // 1-bit port connecting to external ADC serial clock
  on tile[MOTOR_TILE]: port p1_ready = PORT_ADC_CONV; // 1-bit port used to as ready signal for pb32_adc_data ports and ADC chip
  on tile[MOTOR_TILE]: out port p4_adc_mux = PORT_ADC_MUX; // 4-bit port used to control multiplexor on ADC chip
  on tile[MOTOR_TILE]: clock adc_xclk = XS1_CLKBLK_2; // Internal XMOS clock
  
  int main ( void ) // Program Entry Point
  {
    chan c_pwm2adc_trig[NUMBER_OF_MOTORS];
    chan c_pwm[NUMBER_OF_MOTORS];
    streaming chan c_adc_cntrl[NUMBER_OF_MOTORS];
  
    par
    {
      // Loop through all motors
      par (int motor_cnt=0; motor_cnt<NUMBER_OF_MOTORS; motor_cnt++)
      {
        on tile[MOTOR_TILE] : run_motor( motor_cnt ,c_pwm[motor_cnt] ,c_adc_cntrl[motor_cnt] );
  
        on tile[MOTOR_TILE] : foc_pwm_do_triggered( motor_cnt ,c_pwm[motor_cnt] 
          ,pb32_pwm_hi[motor_cnt] ,pb32_pwm_lo[motor_cnt] ,c_pwm2adc_trig[motor_cnt] 
          ,p16_adc_sync[motor_cnt] ,pwm_clk[motor_cnt] );
      }
  
      on tile[MOTOR_TILE] : foc_adc_7265_triggered( c_adc_cntrl ,c_pwm2adc_trig 
        ,pb32_adc_data ,adc_xclk ,p1_adc_sclk ,p1_ready ,p4_adc_mux );
    } // par
  
    return 0;
  } // main
