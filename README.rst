XCORE.com Multi Channel PWM SOFTWARE COMPONENT
..............................................

:Latest release: 1.0.0rc0
:Maintainer: djpwilk
:Description: Various PWM driver components for single bit and multi bit ports


:Maintainer:  Gopal Lakshmanagowda (github: nlgk2001)

The Pulse Width Modulation(PWM) components generates a number PWM signals using either one multibit port or a group of 1-bit ports. 

Key Features
============

  * The components can be configured for Leading edge, Trailing edge and Center edge variations
  * configurable timestep, resolution
  * PWM single bit component generates PWM signals on upto 16 1-bit ports from a single thread.
  * PWM multi bit component generates the PWM signals on a single 4, 8 or 16 bit port.

Firmware Overview
=================

The components will run in a par with the following function which does not terminate. A single function starts the pwm server and passes it a channel with 
which it will communicate with the client, a clock block required for the clocking of the required ports, an array of ports on which the pwm signals will be generated, and the number of ports in the array. 

Known Issues
============

none

Support
=======

Issues may be submitted via the Issues tab in this github repo. Response to any issues submitted as at the discretion of the manitainer for this line.

Required software (dependencies)
================================

  * None

