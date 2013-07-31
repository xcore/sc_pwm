
Evaluation Platforms
====================

.. _sec_hardware_platforms:

.. xCORESimulator:

Recommended Hardware
--------------------

Motor Control Boards
++++++++++++++++++++

This module may be evaluated using the Motor Control Development Platform. 
Minimum Required board SKUs are:

   * XP-MC-CNTL-L2 (Motor Control Board) plus XA-MC-PWR-DLV (Motor Power Board) plus 
   * XA-SK-XTAG2 (Slicekit XTAG adaptor) 

Demonstration Applications
--------------------------

Test Harness
++++++++++++

This application runs on the xCORE Simulator. Example stand alone usage of this module can be found within the xSOFTip suite as follows:

   * Package: sw_foc_motor_control
   * Application: app_test_pwm

FOC Motor Control Demo
++++++++++++++++++++++

This application requires the Motor Control boards. This module is used in the app_foc_demo example application which shows how the module is deployed within the context of a more complex motor control application. 

   * Package: sw_foc_motor_control
   * Application: app_foc_demo 
