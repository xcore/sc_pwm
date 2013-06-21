.. _sec_api:

API
===

.. _sec_conf_defines:

Configuration Defines
---------------------
.. doxygendefine:: NUMBER_OF_MOTORS 
.. doxygendefine:: NUM_POLE_PAIRS 
.. doxygendefine:: HALL_PER_POLE 
.. doxygendefine:: MAX_SPEC_RPM 
.. doxygendefine:: HALL_FILTER 
.. doxygendefine:: PLATFORM_REFERENCE_HZ  

Functions
---------

Data Types
++++++++++

Data Structures
+++++++++++++++
.. doxygenstruct:: HALL_PARAM_TAG

Configuration Functions
+++++++++++++++++++++++

Receive Functions
+++++++++++++++++
.. doxygenfunction:: foc_hall_get_parameters

Transmit Functions
++++++++++++++++++
.. doxygenfunction:: foc_hall_do_multiple
