Overview 
========

The Pulse Width Modulation(PWM) components generates a number PWM signals using either one multibit port or a group of 1-bit ports. 
The component can be configured for Leading edge, Trailing edge and Center edge variations.
The client application uses SetDutyCycle function to give the new dutycycle for the server for each port. The server continues to 
output the pwm signal with given duty cycle and changes the dutycyle when the function SetDutyCycle is called with another dutycycle.

Components 
----------

PWM single bit component
++++++++++++++++++++++++

This variation generates the PWM signals on upto 16 1-bit ports from a single thread. The number of ports, resolution, edge variation and the timestep are configurable.
 
PWM multi bit component
+++++++++++++++++++++++

This component generates the PWM signals on a single 4, 8 or 16 bit port. The port width, resolution, edge variation and timestep are configrable.

Hardware Platform
=================

The PWM components are supported by all the hardware platforms from XMOS having suitable IO such as XC-1,XC-1A,XC-2,XK-1,etc and can be run on any XS1-L or XS1-G series devices.
 
The following modules are provided in this package, these can be used in your applications:

Demo applications 
-----------------

The PWM functionality is demonstrated using following demo applications. The applications run on XC-1 board and  XDE 10.4.2 or later versions.

app_pwm_singlebit_demo 
++++++++++++++++++++++   

   This demo is for PWM single bit port and the duty cycle is changed once in every second starting from 0 to 32 and the PWM functionality is highlighted using leds on the development board.
  
app_pwm_multibit_demo 
+++++++++++++++++++++

   This demo is for PWM multi bit port and the duty cycle is changed once in every second starting from 0 to 32 and the PWM functionality is highlighted using leds on the development board.


System Description
==================

   The pwm component runs in its own threads. The component acts as a server, connected with the client api through a channel on using which client can configure the PWM  component by changing its resolution, Timestep and Edge variation. The number and assignment of of ports for PWM single bit component, or the port width and assignment for PWM multibit component can also be configured.

   The client application uses pwmSingleBitPortSetDutyCycle function to give the new dutycycle for the server for each port .The server continues to output at this value and until the the function pwmSingleBitPortSetDutyCycle  called again.


Programming Guide 
=================
 
API (Application Programming Interface)
---------------------------------------

PWM Single Bit Component API
++++++++++++++++++++++++++++  

The component will run in a par with the following function which does not terminate.

void pwmSingleBitPort(chanend c, clock clk,
                      out buffered port:32 p[], 
                      unsigned int numPorts, 
                      unsigned int resolution, 
                      unsigned int timeStep
                      unsigned int mod_type);

This function starts the pwm server and passes it a channel with 
which it will communicate with the client, a clock block required for the clocking of the required ports, an array of ports on which the pwm signals will be generated, and the number of ports in the array. 

The resolution specifes the number of levels permitted in the pwm, thus a resolution  of 100 will provide 100 distinct levels, and a resolution of 1024 will provide 1024 distinct levels (i.e. equivilent to 10-bits resolution). Also, the resolution must be a multiple of 32.  

The timestep configures how long each level lasts for.  For example: 0 -> 10ns, 1 -> 20ns, 2 -> 40ns, 3 -> 60ns, 4 -> 80ns, etc, up to a maximum of 256.  Therefore, the resulting period of the pwm (in ns) is given by the following expression: 

(10 * resolution) [if timestep = 0] or (timestep * 20 * resolution) [if timestep > 0]

The mod_type configures the PWM edge variations
1 --> Lead Edge, 2 -- > Tail Edge, 3 --> Centred variations

void setDutyCycle(chanend c, unsigned int dutyCycle[], unsigned int numPorts);

The client uses this function to give the pwm server a new set of duty cycles, one for  each of the ports in use. The server will then continue to output at that value until this function is called again.


PWM Multi Bit Component
+++++++++++++++++++++++
The component will run in a par with the following function which does not terminate.

void pwmMultiBitPort(chanend c, clock clk,
                     out buffered port:32 p, 
                     unsigned int portWidth, 
                     unsigned int resolution, 
                     unsigned int timeStep
                     unsigned int mod_type);


This function starts the pwm server and configures it with the a channel with which it will communicate with the client, a clock block required for the
clocking of the port, a 4, 8 or 16-bit port on which the pwm signals will be generated, and the width of the given port. The resolution timestep and mod_type
parameters are treated in the same way as in the PWM_SINGLE_BIT component.

   
void setDutyCycle(chanend c, unsigned int dutyCycle[], unsigned int portWidth);
This function is same as described in pwm single bit component.

Resource Usage
==============

The following table details the resource usage of each
component of the reference design software.

For app_pwm_singlebit_port application       

 +----------------+---------------+----------------+
 |   Memory       |  Size(KB)     | percentage(%)  |
 +================+===============+================+
 | Stack Memory   |     0.685     |    1.05        |
 +----------------+---------------+----------------+			
 | Data Memory    |     0.838     |    1.28        |
 +----------------+---------------+----------------+
 |Program Memory  |     6.442     |    9.83        | 
 +----------------+---------------+----------------+ 
 |Free(available) |     57.571    |    87.85       |                      
 +----------------+---------------+----------------+

For app_pwm_multibit_port application :      

 +----------------+---------------+----------------+
 |   Memory       |  Size(KB)     | percentage(%)  |
 +================+===============+================+
 | Stack Memory   |     0.449     |    0.69        |
 +----------------+---------------+----------------+			
 | Data Memory    |     0.486     |    0.74        |
 +----------------+---------------+----------------+
 |Program Memory  |     5.858     |    8.94        | 
 +----------------+---------------+----------------+ 
 |Free(available) |     58.743    |    89.63       |                      
 +----------------+---------------+----------------+


Timing Constraints 
==================


The following table gives the details of the constraint for the number of ports in pwm singlebit component

 +------------------+----------------------------+
 | Number of port   | Minimum Timestep required  |
 +==================+============================+
 |     16 to 14     |        20                  |
 +------------------+----------------------------+			
 |      13 to 1     |        10                  |
 +------------------+----------------------------+

The following table details the constraint for the number of ports in pwm multibit component

 +------------------+----------------------------+
 |    port width    | Minimum Timestep required  |
 +==================+============================+
 |     4            |        150                  |
 +------------------+----------------------------+			
 |     8            |        150                  |
 +------------------+----------------------------+
 


Validation 
==========
   
Test bench provided for validation of the pwm single bit component take different set of parameters for resolution, timestep, mod_type and number of ports.
similarly test bench provided for validation of the pwm multi bit component take different set of parameters for resolution, timestep, mod_type and port width.

Python sciprt is provoided for regression testing and can be used to run the individual tests also. Script generates different combination of parameters and updates pwm_test.h file.
The component is simulated using the generated set of parameters and the duty cycle is varied in testbench starting from 0 to the maximum resolution.
In independent tests different dutycycle is given for the all the ports at a time and tested. The output of the test is logged into a text file and the expected result generated by the script is compared
with the output.

The final result of the regression is logged in PWM_Error_Log.txt file. The result file contains the testcase name and the reslut of the test and the command to run the test individually if required.
The command to run regression is c:\Python24\python.exe regression_script.py and the script should be ran in the app_single_bit_test folder for pwm single bit comonent and in app_multibit_test for 
pwm multi bit component.

following commands are examples to run the individual tests for pwm single bit component.
1. c:\Python24\python.exe regression_script.py -ind 0 -resolution 32 -timestep 10 -num_of_ports 1 -mod_type 1 (for noraml tests)
2. c:\Python24\python.exe regression_script.py -ind 1 -ind_test_num 2 for independent test (for independent tests)

-ind           - 0 for normal test and 1 for independent test
-resolution    - Resloution should be multiple of 32
-timestep      - Timestep can be greater than equal to 10
-num_of_ports  - The number of ports can be 1 to 16 bits
-mod_type      - 1 for leading edge , 2 for trailing edge and 3 for centered variation
-ind_test_num  - It can take value from 0 to 15. Each value indicates different set of dutycycle which are applied to 16 bit ports at a time.

