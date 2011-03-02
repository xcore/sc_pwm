// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <assert.h>
#include <print.h>
#include <stdlib.h>
#include <xs1.h>
#include "pwm_multibit_port.h"

#define MAX_PORT_WIDTH 16

static void setUp(
    unsigned int portWidth, unsigned int &clocksPerPeriod, 
    unsigned int &clocksPerPeriodMask, unsigned int lookup[]);

#pragma unsafe arrays
void pwmMultiBitPort(
    chanend c, clock clk,
    out buffered port:32 p,
    unsigned int portWidth,
    unsigned int resolution, 
    unsigned int timeStep) {

    timer t;
    unsigned int time;
    unsigned int portIndex;
    unsigned int portValue;
    unsigned int nextDutyCycle[MAX_PORT_WIDTH] = {0};
    unsigned int dutyCycle[MAX_PORT_WIDTH] = {0};
    unsigned int clocksPerPeriod;
    unsigned int clocksPerPeriodMask;
    unsigned int lookup[MAX_PORT_WIDTH] = {0};
    unsigned int period;
    unsigned int numTicks = resolution;

    // Sets up some initial values based on the given port width.
    setUp(portWidth, clocksPerPeriod, clocksPerPeriodMask, lookup);

    // Calculates the timer period
    period = (timeStep == 0) ? clocksPerPeriod : clocksPerPeriod * (timeStep * 2);

    // Configures the port clocks.
    set_clock_div(clk, timeStep);
    set_port_clock(p, clk);
    start_clock(clk);

    // Gets the initial time. 
    t :> time;
    time += period;

    while (1) {
        select {
        // A new set of duty cycle values are avaliable.
        #pragma xta endpoint "updateDutyCycle"
        case slave { 
            int i = 0;
            do { 
                c :> nextDutyCycle[i];  
                ++i; 
            } while (i < portWidth);}:
            break;

        // Handles the pwm output.
        #pragma xta endpoint "handlePwm"
        case t when timerafter (time) :> void:

            // Updates the current value of the duty cycles.
            if (numTicks == resolution) {
                for (unsigned int i = 0; i < portWidth; ++i) {
                    #pragma xta label "nextDutyCycleLoop"
                    dutyCycle[i] = nextDutyCycle[i];
                }
                numTicks = 0;
            }
           
            // Calculates the value to be output on the port.
            portValue = 0; 
            for (unsigned int i = 0; i < portWidth; ++i) {
                #pragma xta label "calculatePortValueLoop"
                unsigned int value = dutyCycle[i];

                if (value < numTicks) {
                    // Do Nothing..

                } else if (value < (numTicks + clocksPerPeriod)) {                 
                    portValue |= (lookup[value & clocksPerPeriodMask] >> i);
 
                } else {
                    portValue |= (lookup[clocksPerPeriod] >> i);
                }
            }

            // Output the port value.
            p <: portValue;

            numTicks += clocksPerPeriod;
            time += period;
            break;
        }
    }
}

void pwmMultiBitPortSetDutyCycle(
    chanend c, 
    unsigned int dutyCycle[], 
    unsigned int portWidth) {

    master {
        for (unsigned int i = 0; i < portWidth; ++i) {
            c <: dutyCycle[i];
        }
    }
}

static void setUp(
    unsigned int portWidth, unsigned int &clocksPerPeriod, 
    unsigned int &clocksPerPeriodMask, unsigned int lookup[]) {

    switch (portWidth) {
    case 4:
        clocksPerPeriod = 8;
        clocksPerPeriodMask = 0x7;
        lookup[0] = 0x00000000;
        lookup[1] = 0x00000008;
        lookup[2] = 0x00000088;
        lookup[3] = 0x00000888;
        lookup[4] = 0x00008888;
        lookup[5] = 0x00088888;
        lookup[6] = 0x00888888;
        lookup[7] = 0x08888888;
        lookup[8] = 0x88888888;
        break;

    case 8:
        clocksPerPeriod = 4;
        clocksPerPeriodMask = 0x3;
        lookup[0] = 0x00000000;
        lookup[1] = 0x00000080;
        lookup[2] = 0x00008080;
        lookup[3] = 0x00808080;
        lookup[4] = 0x80808080;
        break;

    case 16:
        clocksPerPeriod = 2;
        clocksPerPeriodMask = 0x1;
        lookup[0] = 0x00000000;
        lookup[1] = 0x00008000;
        lookup[2] = 0x80008000;
        break;
   
    default:
        assert(0);
        break;
    }
}
