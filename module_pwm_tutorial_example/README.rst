Tutorial Example LED PWM Driver Component
=========================================

:scope: Example
:description: Simple PWM driver component designed for xTimeComposer Tutorial
:keywords: PWM, tutorial, LED
:boards: XA-SK-GPIO

This is an example xSOFTip component created for use with the
xTimeComposer tutorials. The xTimeComposer tutorials are available in the 'Help' menu.

Overview
++++++++
This component implements a PWM driver, using a port to drive an LED. 
The code uses the 100MHz reference clock using timed outputs on the port to control
the length of the low and high periods of the PWM signal. This provides 10ns resolution 
for the PWM phase and duty cycle.

Details
+++++++
The PWM component uses 1 Core, with a channel interface to the rest of the application. 
The client application sends two values over the channel to configure the PWM driver:
   #. The PWM period length
   #. The PWM duty cycle length 
All times are measured with the 100mHz reference clock. 
For example, a value of 100 is 100 x 10ns = 1us.

The client can update the setting of PWM duty cycle length at any time using the channel.
The PWM component uses a select statement to optionally receive data from the client over the channel. 
The select statement tests if the client has sent any data over the channel, and will then receive the data. 
If no data has been sent, the default case is executed.

To safeguard against invalid or unintended use of the PWM component, an assertion check fires if the duty_cycle value is greater than 
the period.



