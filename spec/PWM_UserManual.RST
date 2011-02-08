Overview 
========

The Pulse Width Modulation(PWM) components generates a number PWM signals using either one multibit port or a group of 1-bit ports. 
The component can be configured for Leading edge, Trailing edge and Center edge variations.

[DW: add a little info about client api here, client server model ]

Components 
----------

PWM single bit component
++++++++++++++++++++++++

This variation generates the PWM signals on upto 16 1-bit ports from a single thread. The number of ports, resolution, edge variation and the timestep are configurable.
 
PWM multi bit component
+++++++++++++++++++++++
This component generates the PWM signals on a single 4, 8 or 16 bit port. The port width, resolution, edge variation and timestep are configrable.

Hardware Platform:
=================
The PWM components are supported by all the hardware platforms from XMOS having suitable IO such as XC-1,XC-1A,XC-2,XK-1,etc and can be run on any XS1-L or XS1-G series devices.
 
The following modules are provided in this package, these can be used in your applications:

Demo applications :
------------------

The PWM functionality is demonstrated using following demo applications. The applications run on XC-1 board and  XDE 10.4.2 or later versions.

app_pwm_singlebit_demo : 
+++++++++++++++++++++++    

   This demo is for PWM single bit port and the duty cycle is changed once in every second starting from 0 to 32 and the PWM functionality is highlighted using leds on the development board.
  
app_pwm_multibit_demo : 
+++++++++++++++++++++

   This demo is for PWM multi bit port and the duty cycle is changed once in every second starting from 0 to 32 and the PWM functionality is highlighted using leds on the development board.


System Description :
===================

   The pwm component runs in its own threads. The component acts as a server, connected with the client api through a channel on using which client can configure the PWM  component by changing its resolution, Timestep and Edge variation. The number and assignment of of ports for PWM single bit component, or the port width and assignment for PWM multibit component can also be configured.

   The client application uses pwmSingleBitPortSetDutyCycle function to give the new dutycycle for the server for each port .The server continues to output at this value and until the the function pwmSingleBitPortSetDutyCycle  called again.


Programming Guide :
=================
 
API (Application Programming Interface) :
---------------------------------------

PWM Single Bit Component API : 
++++++++++++++++++++++++++++++   

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

[DW: are these values 1,2,3  #defines, e.g. #define LEAD_EDGE 1 ?? ]

void setDutyCycle(chanend c, unsigned int dutyCycle[], unsigned int numPorts);

The client uses this function to give the pwm server a new set of duty cycles, one for  each of the ports in use. The server will then continue to output at that value until this function is called again.

[DW; why is num_ports passed to this function?]

PWM Multi Bit Component :
+++++++++++++++++++++++++
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

[DW: why is portwidth passed ?]

Resource Usage :
==============

[DW: please put the below into a table as in the uart document]

Memory Usage
------------
Out of available memory , following is the distribution of Usage  for app_pwm_singlebit_port application :      
Stack memory : 685 bytes (1.05%)
data memory :   838 bytes (1.28)
program memory : 6442 bytes (9.83%) 

Other remaining 57571 bytes (87.85 % ) is available 

Out of available memory , following is the distribution of Usage  for app_pwm_multibit_port application :      
Stack memory : 449 bytes (0.69%)
data memory :   486 bytes (0.74)
program memory : 5858 bytes (8.94%) 

Other remaining 58743 bytes (89.63 % ) is available 

 
Port :
-----
  
[DW; please describe the below as constraints, and place in a table]

pwm single bit port can configured starting from one 1 single bit port to 16 single bit port
Maximum of 16 single bit ports are can be used for pwm single bit component if the timestep is 20
Maximum of 13 single bit ports are can be used for pwm single bit component if time step is 10

Pwm multi bit component can be configured as 4bit output port, 8 bit output port and 16 bit output port
4bit port can be used for pwm multibit port if time step is more than equal to 10
8bit port can be used if timestep is greater than or equal to 40
16 bit port can be used if timestep is greater than or equal to 120. 





Validation :
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

