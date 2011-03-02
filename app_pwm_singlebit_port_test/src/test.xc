// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <print.h>
#include <stdlib.h>
#include <syscall.h>
#include <xs1.h>
#include <stdio.h>
#include "pwm_singlebit_port.h"
#include "test_pwm.h"


clock clk = XS1_CLKBLK_1;

# if NUM_PORTS == 1
	out buffered port:32 ports[NUM_PORTS] = {XS1_PORT_1A};

# elif NUM_PORTS == 2
	out buffered port:32 ports[NUM_PORTS] = {XS1_PORT_1A, XS1_PORT_1B};

# elif NUM_PORTS == 4
	out buffered port:32 ports[NUM_PORTS] = {XS1_PORT_1A, XS1_PORT_1B, XS1_PORT_1C, XS1_PORT_1D};

# elif NUM_PORTS == 7
	out buffered port:32 ports[NUM_PORTS] = {XS1_PORT_1A, XS1_PORT_1B, XS1_PORT_1C, XS1_PORT_1D, XS1_PORT_1E, XS1_PORT_1F, XS1_PORT_1G};

# elif NUM_PORTS == 8
	out buffered port:32 ports[NUM_PORTS] = {XS1_PORT_1A, XS1_PORT_1B, XS1_PORT_1C, XS1_PORT_1D,XS1_PORT_1E, XS1_PORT_1F, XS1_PORT_1G, XS1_PORT_1H};

# elif NUM_PORTS == 15
	out buffered port:32 ports[NUM_PORTS] = {XS1_PORT_1A, XS1_PORT_1B, XS1_PORT_1C, XS1_PORT_1D,XS1_PORT_1E, XS1_PORT_1F, XS1_PORT_1G, XS1_PORT_1H,XS1_PORT_1I, XS1_PORT_1J, XS1_PORT_1K, XS1_PORT_1L,XS1_PORT_1M, XS1_PORT_1N, XS1_PORT_1O};

# elif NUM_PORTS == 16
	out buffered port:32 ports[NUM_PORTS] = {XS1_PORT_1A, XS1_PORT_1B, XS1_PORT_1C, XS1_PORT_1D,XS1_PORT_1E, XS1_PORT_1F, XS1_PORT_1G, XS1_PORT_1H,XS1_PORT_1I, XS1_PORT_1J, XS1_PORT_1K, XS1_PORT_1L,XS1_PORT_1M, XS1_PORT_1N, XS1_PORT_1O, XS1_PORT_1P};

#endif

#define START_MONITORING 1000
#define STOP_MONITORING  1001
#define REPORT_STATUS    1002

void startPluginMonitoring() {
	_plugins(START_MONITORING, 0, 0);
}

void stopPluginMonitoring() {
	_plugins(STOP_MONITORING, 0, 0);
}

void reportPluginStatus() {
	_plugins(REPORT_STATUS, 0, 0);
}

void delay() {
    timer t;
    int time;
    int period = (TIMESTEP == 0) ? (40 * RESOLUTION) : (40 * TIMESTEP * RESOLUTION);
    t :> time;
    time += period;
	t when timerafter (time) :> void;
}

void setDutyCycles(chanend c) {
    unsigned char done[NUM_PORTS] = {0};
    unsigned int current = 0;
    unsigned int numCycles = 0;
    unsigned int i;
	#ifndef INDEPENDENT
		while (numCycles <= RESOLUTION) {
			pwmSingleBitPortSetDutyCycle(c, value, NUM_PORTS);
			delay();
			startPluginMonitoring();
			delay();
			stopPluginMonitoring();
			reportPluginStatus();
			for(i =0; i < NUM_PORTS; i++){
				value[i]++;
			}
			++numCycles;
		}
	#else
		pwmSingleBitPortSetDutyCycle(c, value, NUM_PORTS);
		delay();
		startPluginMonitoring();
		delay();
		stopPluginMonitoring();
		reportPluginStatus();
	#endif
     delay();
     delay();
     exit(0);
}

int main() {
    chan c;
    par {
        setDutyCycles(c);
        pwmSingleBitPort(c, clk, ports, NUM_PORTS, RESOLUTION, TIMESTEP,mod_type);
    }
    return 0;
}

