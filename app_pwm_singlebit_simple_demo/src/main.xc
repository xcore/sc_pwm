// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "pwmSingle.h"

#include <xs1.h>

port ports[8] = {
    XS1_PORT_1A,
    XS1_PORT_1B,
    XS1_PORT_1C,
    XS1_PORT_1D,
    XS1_PORT_1E,
    XS1_PORT_1F,
    XS1_PORT_1G,
    XS1_PORT_1H,
};

#pragma unsafe arrays
void signalgenerator( chanend c) {
    int differences[48] = {7, 1, 1, 1, 1, 1, 1, 1,
                           4, 3, 3, 3, 3, 3, 3, 3,
                           0, 0, 0, 0, 0, 0, 0, 0,
                           4, 64, 64, 64, 64, 64, 64, 64,
                           4, 24, 24, 24, 24, 24, 24, 24,
                           1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000,
                           1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000,
    };
    int now;
    int pwmCycle = 8000;
    c :> now;
    now += 20000;
    c <: 0x00;     // Initial value
    c <: now;    // Initial time.
    while(1) {
        for(int j = 0; j < 6; j++) {
            int t = now;
            slave  {
                c :> int _;
                for(int i = 0; i < 8; i++) {
                    t += differences[i + j*8];
                    c <: t; 
                }
                now += pwmCycle;
                c <: now;
            }
        }
    }
}

void burn(void) {
#if 1
    set_thread_fast_mode_on();
    while(1);
#endif
}

int main (void) {
    chan c;
    par {
        burn();
        burn();
        burn();
        burn();
        burn();
        burn();
        signalgenerator(c);
        pwmSingle(c, ports, 8);
    }
    return 0;
}
