#include <platform.h>
#include <print.h>
#include <stdlib.h>
#include <syscall.h>
#include <xs1.h>
#include "pwm_singlebit_port.h"

on stdcore[0] : out buffered port:32 rgPorts[] = { PORT_CLOCKLED_SELR, PORT_CLOCKLED_SELG };
on stdcore[0] : clock clk = XS1_CLKBLK_1;

on stdcore[0] : port clockLed0 = PORT_CLOCKLED_0;
on stdcore[1] : port clockLed1 = PORT_CLOCKLED_1;
on stdcore[2] : port clockLed2 = PORT_CLOCKLED_2;
on stdcore[3] : port clockLed3 = PORT_CLOCKLED_3;

#define MILLISECONDS 100000
#define PERIOD 100 * MILLISECONDS

#define NUM_PORTS 2
#define RESOLUTION 32
#define TIMESTEP 10

enum { COUNTUP, COUNTDOWN };

void enableClockLeds(port clockLed) {
	clockLed <: 0x70;
}

void updateValues(unsigned int values[], unsigned int direction[]) {
	for (unsigned int i = 0; i < NUM_PORTS; ++i) {
		switch (direction[i]) {
		case COUNTUP:
			if (values[i] == RESOLUTION) {
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

    unsigned int values[NUM_PORTS] = {0, RESOLUTION};
    unsigned int direction[NUM_PORTS] = {COUNTUP, COUNTDOWN};

    t :> time;
    time += PERIOD;

    while (1) {
        t when timerafter (time) :> void;
        updateValues(values, direction);
        pwmSingleBitPortSetDutyCycle(c, values, NUM_PORTS);
        time += PERIOD;
    }
}

int main() {
    chan c;

    par {
        on stdcore[0] : enableClockLeds(clockLed0);
        on stdcore[1] : enableClockLeds(clockLed1);
        on stdcore[2] : enableClockLeds(clockLed2);
        on stdcore[3] : enableClockLeds(clockLed3);

        on stdcore[0] : client(c);
        on stdcore[0] : pwmSingleBitPort(c, clk, rgPorts, NUM_PORTS, RESOLUTION, TIMESTEP,1);

    }
    return 0;
}

