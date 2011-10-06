// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <platform.h>
#include <print.h>
#include <stdlib.h>
#include <syscall.h>
#include <xs1.h>
#include "pwm_multibit_port.h"

on stdcore[0] : port rPort = PORT_CLOCKLED_SELR;
on stdcore[0] : port gPort = PORT_CLOCKLED_SELG;

on stdcore[0] : clock clk0 = XS1_CLKBLK_1;
on stdcore[1] : clock clk1 = XS1_CLKBLK_1;
on stdcore[2] : clock clk2 = XS1_CLKBLK_1;
on stdcore[3] : clock clk3 = XS1_CLKBLK_1;

on stdcore[0] : out buffered port:32 clockLed0 = PORT_CLOCKLED_0;
on stdcore[1] : out buffered port:32 clockLed1 = PORT_CLOCKLED_1;
on stdcore[2] : out buffered port:32 clockLed2 = PORT_CLOCKLED_2;
on stdcore[3] : out buffered port:32 clockLed3 = PORT_CLOCKLED_3;

#define MILLISECONDS 100000
#define PERIOD 100 * MILLISECONDS

#define PORT_WIDTH 8
#define RESOLUTION 32
#define TIMESTEP 50

enum { COUNTUP, COUNTDOWN };

void setLedColourRed() {
    rPort <: 1;
    gPort <: 1;
}

void updateValues(unsigned int values[], unsigned int direction[]) {
	for (unsigned int i = 0; i < PORT_WIDTH; ++i) {
		switch (direction[i]) {
		case COUNTUP:
			if (values[i] == 10) {
				direction[i] = COUNTDOWN;
				--values[i];
			} else {
				++values[i];
			}
			break;

		case COUNTDOWN:
			if (values[i] == 0) {
				direction[i] = COUNTUP;
				++values[i];
			} else {
				--values[i];
			}
			break;
		}
	}
}

void client(chanend c) {
    timer t;
    int time;

    unsigned int values[PORT_WIDTH] = {0, 0, 0, 0, 0, 0, 0, 0};
	unsigned int direction[PORT_WIDTH] = {
			COUNTUP, COUNTUP, COUNTUP, COUNTUP,
			COUNTUP, COUNTUP, COUNTUP, COUNTUP};

    t :> time;
    time += PERIOD;

    while (1) {
        t when timerafter (time) :> void;
        updateValues(values, direction);
            pwmMultiBitPortSetDutyCycle(c, values, PORT_WIDTH);
        time += PERIOD;
    }
}

int main() {
    chan c[4];

    par {
    	on stdcore[0] : setLedColourRed();

        on stdcore[0] : client(c[0]);
            on stdcore[0] : pwmMultiBitPort(c[0], clk0, clockLed0, PORT_WIDTH, RESOLUTION, TIMESTEP, 1);

        on stdcore[1] : client(c[1]);
            on stdcore[1] : pwmMultiBitPort(c[1], clk1, clockLed1, PORT_WIDTH, RESOLUTION, TIMESTEP, 1);

        on stdcore[2] : client(c[2]);
            on stdcore[2] : pwmMultiBitPort(c[2], clk2, clockLed2, PORT_WIDTH, RESOLUTION, TIMESTEP, 1);

        on stdcore[3] : client(c[3]);
            on stdcore[3] : pwmMultiBitPort(c[3], clk3, clockLed3, PORT_WIDTH, RESOLUTION, TIMESTEP, 1);
    }
    return 0;
}

