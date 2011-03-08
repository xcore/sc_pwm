#include <print.h>
#include <stdlib.h>
#include <syscall.h>
#include <xs1.h>
#include <stdio.h>
#include "plugin.h"
#include "pwm_multibit_port.h"

#if PORT_WIDTH == 4
    out buffered port:32 p = XS1_PORT_4A;
    unsigned int value1[PORT_WIDTH] = {1, 2, 3, 4};
    unsigned int value2[PORT_WIDTH] = {1, 2, 3, 4};
    #define RESOLUTION 32

#elif PORT_WIDTH == 8
    out buffered port:32 p = XS1_PORT_8A;
    unsigned int value1[PORT_WIDTH] = {1, 2, 3, 4, 5, 6, 7, 8};
    unsigned int value2[PORT_WIDTH] = {1, 2, 3, 4, 5, 6, 7, 8};
    
    #define RESOLUTION 32

#elif PORT_WIDTH == 16
    out buffered port:32 p = XS1_PORT_16A;
    unsigned int value1[PORT_WIDTH] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
    unsigned int value2[PORT_WIDTH] = {1, 1, 1, 1, 1, 2, 2, 2, 2,  10, 11, 12, 13, 14, 15, 16 };
    #define RESOLUTION 32

#else
#error "PORT_WIDTH must be 4, 8 or 16"
#endif

#define MAX_NUM_CYCLES 5
unsigned int edge=1;
unsigned int PERIOD=(TIMESTEP*32*4);
clock clk = XS1_CLKBLK_1;

void setDutyCycles(chanend c, unsigned int portWidth) {
    timer t;
    int time;
    unsigned int current = 0;
    int period = PERIOD;
    unsigned int numCycles = 0;
    unsigned char done[PORT_WIDTH] = {0};

    //setupPluginWait(done, MAX_NUM_CYCLES);
    //_traceStart();

    t :> time;
    time += period;

    while (numCycles < MAX_NUM_CYCLES) {
        t when timerafter (time) :> void;
        if (current == 0){
            pwmMultiBitPortSetDutyCycle(c, value1, portWidth);
        }
        else
            pwmMultiBitPortSetDutyCycle(c, value2, portWidth);

        current = !current;
        time += period;
        ++numCycles;
    }

    //waitUntilPluginIsFinished(done, PORT_WIDTH);
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

