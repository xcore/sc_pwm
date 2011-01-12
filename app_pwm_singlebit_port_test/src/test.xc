#include <print.h>
#include <stdlib.h>
#include <syscall.h>
#include <xs1.h>
#include "pwm_singlebit_port.h"
#include "plugin.h"

#define NUM_PORTS 4
#define MAX_NUM_CYCLES 10 

clock clk = XS1_CLKBLK_1;
out buffered port:32 ports[NUM_PORTS] = {XS1_PORT_1A, XS1_PORT_1B, XS1_PORT_1C, XS1_PORT_1D};

void setDutyCycles(chanend c) {
    timer t;
    int time;
    unsigned int value1[NUM_PORTS] = {20, 20, 20, 20};
    unsigned int value2[NUM_PORTS] = {200, 200, 200, 200};
    unsigned char done[NUM_PORTS] = {0};
    unsigned int current = 0;
    int period = 10240;
    unsigned int numCycles = 0;

    setupPluginWait(done, MAX_NUM_CYCLES);
    _traceStart();

    t :> time;
    time += period;

    while (numCycles < MAX_NUM_CYCLES) {
        t when timerafter (time) :> void;
        if (current == 0)
            pwmSingleBitPortSetDutyCycle(c, value1, NUM_PORTS);
        else
            pwmSingleBitPortSetDutyCycle(c, value2, NUM_PORTS);

        current = !current;  
        time += period;
        ++numCycles;
    }

    waitUntilPluginIsFinished(done, NUM_PORTS);
    exit(0);
}

int main() {
    chan c;

    par {
        setDutyCycles(c);
        pwmSingleBitPort(c, clk, ports, NUM_PORTS, 256, 10,1);
    }
    return 0;
}

