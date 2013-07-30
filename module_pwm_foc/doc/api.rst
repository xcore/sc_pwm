.. _sec_api:

API
===

.. _sec_conf_defines:

Configuration Defines
---------------------
.. doxygendefine:: PWM_SHARED_MEM
.. doxygendefine:: PLATFORM_REFERENCE_HZ

Functions
---------

Data Types
++++++++++
.. doxygentypedef:: PORT_TIME_TYP

Data Structures
+++++++++++++++
.. doxygenstruct:: PWM_PARAM_TAG
.. doxygenstruct:: PWM_COMMS_TAG

Configuration Functions
+++++++++++++++++++++++

Receive Functions
+++++++++++++++++
.. doxygenfunction:: foc_pwm_do_triggered

Transmit Functions
++++++++++++++++++
.. doxygenfunction:: foc_pwm_put_parameters

