#include <print.h>
#include <stdlib.h>
#include <syscall.h>
#include <xs1.h>
#include <stdio.h>
#include "plugin.h"
#include "pwm_multibit_port.h"
#include "test_pwm_multibit.h"

#if PORT_WIDTH == 4
    out buffered port:32 p = XS1_PORT_4A;

#elif PORT_WIDTH == 8
    out buffered port:32 p = XS1_PORT_8A;

#elif PORT_WIDTH == 16
    out buffered port:32 p = XS1_PORT_16A;

#else
#error "PORT_WIDTH must be 4, 8 or 16"
#endif

#define MAX_NUM_CYCLES 5
unsigned int period=(TIMESTEP*32*4);
unsigned int i;
clock clk = XS1_CLKBLK_1;

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
void setDutyCycles(chanend c, unsigned int portWidth) {

    unsigned int numCycles = 0;

    while (numCycles <= RESOLUTION) {
    	pwmMultiBitPortSetDutyCycle(c, value, portWidth);
       	delay();
       	startPluginMonitoring();
       	delay();
       	stopPluginMonitoring();
       	reportPluginStatus();
       	for(i =0; i < PORT_WIDTH; i++){
       		value[i]++;
       	}
       	++numCycles;
    }

    //waitUntilPluginIsFinished(done, PORT_WIDTH);
    delay();
    exit(0);
}

int main() {
    chan c;

    par {
        setDutyCycles(c, PORT_WIDTH);
        pwmMultiBitPort(c, clk, p, PORT_WIDTH, RESOLUTION, TIMESTEP,edge);
    }
    return 0;
}

