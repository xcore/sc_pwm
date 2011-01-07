=============================================
PWM Component Specification
=============================================
:Version: 1.0
:authors: Kristen Jacobs

.. sectnum::

Introduction
============

The PWM (pulse width modulation) components provide the ability 
to produce pulse width modulated signals on single-bit and multi-bit 
ports. There will be two components avaliable:

  * PWM Single Bit - Produces a pwm signal on a configurable number of 1-bit ports
  * PWM Multi Bit - Produces a pwm signal on a each pin of a 4, 8 or 16 bit port

These will be available as seperate components in Arkanoid.
These components are not composable thus each require a complete thread.

Functional Specification
========================

.. feature:: PWM_SINGLE_BIT

    The PWM_SINGLE_BIT component will allow the client to produce a configurable
    number of pwm signals using 1-bit ports. It is not composable, thus
    requires a thread on its own in order to function correctly. 
    Communication with the client is done via client side functions which
    interact with the PWM_SINGLE_BIT server via a channel. 

.. feature:: PWM_MULTI_BIT

    The PWM_MULTI_BIT component will allow the client to produce a pwm signal
    on each pin of a 4, 8 or 16-bit port. It is not composable, thus
    requires a thread on its own in order to function correctly. 
    Communication with the client is done via client side functions which
    interact with the PWM_MULTI_BIT server via a channel. 

.. feature:: PWM_MULITPLE_PORTS
   :parents: PWM_SINGLE_BIT

   The PWM_SINGLE_BIT component is configured with an array of ports, thus can produce 
   multiple sychronised pwm signals on multiple 1-bit ports. The number of ports
   is passed as a run-time parameter to the PWM_SINGLE_BIT server function.

.. feature:: PWM_PORT_WIDTH
   :parents: PWM_MULTI_BIT

   The PWM_MULTI_BIT component is configured with a 4, 8 or 16-bit port, and will produce 
   multiple sychronised pwm signals on each pin of the given port. The port width
   is passed as a run-time parameter to the PWM_MULTI_BIT server function.

.. feature:: PWM_RESOLUTION
   :parents: PWM_SINGLE_BIT, PWM_MULTI_BIT

     The resolution of each of the components is configurable. For example, setting the 
     resolution to 1024 will provide 1024 (10-bit) distinct levels.
     This is passed as a run-time parameter to the relevent server function.

.. feature:: PWM_TIMESTEP
   :parents: PWM_SINGLE_BIT, PWM_MULTI_BIT

     The time-step width of each of the components is configurable. For example, setting the
     timestep parameter to 0 will provide a 10 ns minimum time-step.
     This is passed as a run-time parameter to the relevent server function.

.. feature:: PWM_MODULATION_TYPE
   :parents: PWM_SINGLE_BIT, PWM_MULTI_BIT

     The edge of the components is configured with value 1, 2 or 3 depending on the required pulse-width modulation type
     value 1 configures the component as lead edge pwm
     2 configures the component as tail edge pwm
     3 configures the component as Centred variation pwm.

Limitations
===========

The component has the following limitations:

   * Certain configurations of input parameters can result in a component that
     does not meet timing, thus this component must be used in conjuction with 
     the XMOS timing analysis tools
   * The resolution must be multiple of 32
   * The component assumes a 100MHz reference clock speed

API
===

This section describes the API of the two PWM components.

PWM Single Bit Component
------------------------

.. feature:: PWM_SINGLE_BIT_COMPONENT_API
   :parents: PWM_SINGLE_BIT

   The component will run in a par with the following
   function which does not terminate.

     * void pwm(chanend c, clock clk,
                out buffered port:32 p[], 
                unsigned int numPorts, 
                unsigned int resolution, 
                unsigned int timeStep
                unsigned int edge);

   This function starts the pwm server and configures it with the a channel
   with which it will communicate with the client, a clock block required for the
   clocking of the required ports, an array of ports on which the pwm signals will
   be emmitted, and the number of ports in the array. The resolution specifes the
   number of levels permitted in the pwm, thus a resolution of 100 will provide
   100 distinct levels, and a resolution of 1024 will provide 1024 distinct levels
   (i.e. equivilent to 10-bits resolution). Also, the resolution must be a
   multiple of 32.  The timestep configures how long each level lasts for.  For
   example: 0 -> 10ns, 1 -> 20ns, 2 -> 40ns, 3 -> 60ns, 4 -> 80ns, etc, up to a
   maximum of 256.  Therefore, the resulting period of the pwm (in ns) is given by
   the following expression: 
   (10 * resolution) [if timestep = 0] or (timestep * 20 * resolution) [if timestep > 0]
   The edge configures the PWM edge variations
   1 --> Lead Edge, 2 -- > Tail Edge, 3 --> Centred variations

.. feature:: PWM_SINGLE_BIT_CLIENT_API
   :parents: PWM_SINGLE_BIT
   
     * void setDutyCycle(chanend c, unsigned int dutyCycle[], unsigned int numPorts);

   The client uses this function to give the pwm server a new set of duty cycles, one for 
   each of the ports in use. The server will then continue to output at that value until
   this function is called again. If this function is called multiple times during a single
   pwm cycle, then the next duty cycle to be issued will take the value from the last call
   to this function. This function can block if the server is not ready to handle this request.
   However, it is gauranteed to be handled at least once for every pwm cycle.
   This function is not selectable.
  
PWM Multi Bit Component
------------------------

.. feature:: PWM_MULTI_BIT_COMPONENT_API
   :parents: PWM_MULTI_BIT

   The component will run in a par with the following
   function which does not terminate.

     * void pwm(chanend c, clock clk,
                out buffered port:32 p, 
                unsigned int portWidth, 
                unsigned int resolution, 
                unsigned int timeStep
                unsigned int edge);


   This function starts the pwm server and configures it with the a channel
   with which it will communicate with the client, a clock block required for the
   clocking of the port, a 4, 8 or 16-bit port on which the pwm signals will
   be emmitted, and the width of the given port. The resolution timestep and edge
   parameters are treated in the same way as in the PWM_SINGLE_BIT component.

.. feature:: PWM_MULTI_BIT_CLIENT_API
   :parents: PWM_MULTI_BIT
   
     * void setDutyCycle(chanend c, unsigned int dutyCycle[], unsigned int portWidth);

   This function behaves in a similar way to the same function in the PWM_SINGLE_BIT component.
 
Expected Resource Usage
=======================

Threads
-------

The PWM components will each utilise a single thread.

Ports
-----

The PWM_SINGLE_BIT component will use N 1-bit ports, where N is user specified, up
to a maximum of 16. 

The PWM_MULTI_BIT component will use a single 4, 8 or 16-bit port.

Memory
------

Main memory resource usage will be mostly due to code size.

Timers
-------------

The components will each use one timer.

Clocks
-------------

The components will each use one clock block.

Meta Information Summary
========================

The component composer will have the following parameter(s):

PWM Single Bit Component
------------------------

   * Number of Ports (see `PWM_MULITPLE_PORTS`_)
   * Resolution (see `PWM_RESOLUTION`_)
   * Timestep (see `PWM_TIMESTEP`_)

PWM Multi Bit Component
------------------------

   * Number of Ports (see `PWM_PORT_WIDTH`_)
   * Resolution (see `PWM_RESOLUTION`_)
   * Timestep (see `PWM_TIMESTEP`_)

Demo Applications
=================

In order to demonstrate the PWM functionality the components will have
the following demo programs developed.

.. feature:: PWM_SINGLE_BIT_DEMO

   This application will highlight the PWM functionality using the leds on
   a XC-1A development kit.
 
.. feature:: PWM_MULTI_BIT_DEMO

   This application will highlight the PWM functionality using the leds on
   a XC-1A development kit.

Documentation
=============

Standard Arkanoid component documentation will be delivered:

.. feature:: SUMMARY_PARAGRAPH
   :parents: PWM_SINGLE_BIT, PWM_MULTI_BIT

   A summary paragraph of the main features of the component 
   for inclusion in the datasheet.

.. feature:: MANUAL
   :parents: PWM_SINGLE_BIT, PWM_MULTI_BIT

   The pdf manual is a stand-alone document describing how to use the
   component to a programmer. It includes the API description.

Related Documents
=================
* http://en.wikipedia.org/wiki/Pulse-width_modulation
