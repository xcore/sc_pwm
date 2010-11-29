#include <print.h>
#include <stdlib.h>
#include <syscall.h>
#include <xs1.h>
#include "plugin.h"
#include "pwm_multibit_port.h"

#if PORT_WIDTH == 4
    out buffered port:32 p = XS1_PORT_4A;
    unsigned int value1[PORT_WIDTH] = {1, 5, 13, 22};
    unsigned int value2[PORT_WIDTH] = {31,  29,  27,  25};
    #define PERIOD 1280
    #define RESOLUTION 32

#elif PORT_WIDTH == 8
    out buffered port:32 p = XS1_PORT_8A;
    unsigned int value1[PORT_WIDTH] = {1, 3, 5, 7, 9, 11, 13, 15};
    unsigned int value2[PORT_WIDTH] = {31,  29,  27,  25,  23,  21,  19,  17};
    #define PERIOD 6400
    #define RESOLUTION 32

#elif PORT_WIDTH == 16
    out buffered port:32 p = XS1_PORT_16A;
    unsigned int value1[PORT_WIDTH] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16};
    unsigned int value2[PORT_WIDTH] = {31,  30,  29,  28,  27,  26,  25,  24,  23,  22,  21,  20,  19,  18,  17,  16};
    #define PERIOD 12800
    #define RESOLUTION 32

#else
#error "PORT_WIDTH must be 4, 8 or 16"
#endif

#define MAX_NUM_CYCLES 10 

clock clk = XS1_CLKBLK_1;

void setDutyCycles(chanend c, unsigned int portWidth) {
    timer t;
    int time;
    unsigned int current = 0;
    int period = PERIOD;
    unsigned int numCycles = 0;
    unsigned char done[PORT_WIDTH] = {0};

    setupPluginWait(done, MAX_NUM_CYCLES);
    _traceStart();

    t :> time;
    time += period;

    while (numCycles < MAX_NUM_CYCLES) {
        t when timerafter (time) :> void;
        if (current == 0)
            pwmMultiBitPortSetDutyCycle(c, value1, portWidth);
        else
            pwmMultiBitPortSetDutyCycle(c, value2, portWidth);

        current = !current;  
        time += period;
        ++numCycles;
    }

    waitUntilPluginIsFinished(done, PORT_WIDTH);
    exit(0);
}

int main() {
    chan c;

    par {
        setDutyCycles(c, PORT_WIDTH);
        pwmMultiBitPort(c, clk, p, PORT_WIDTH, RESOLUTION, TIMESTEP);
    }
    return 0;
}

