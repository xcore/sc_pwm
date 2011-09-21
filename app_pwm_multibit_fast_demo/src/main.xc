// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "pwmWide.h"

#include <xs1.h>

clock clk = XS1_CLKBLK_2;
buffered out port:32 pwmPort = XS1_PORT_8A;
in port syncPort = XS1_PORT_16A;

#pragma unsafe arrays
void signalgenerator(streaming chanend c) {
    int differences[48] = {7, 1, 1, 1, 1, 1, 1, 1,
                           4, 3, 3, 3, 3, 3, 3, 3,
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
//        master  {
            for(int i = 0; i < 8; i++) {
                t += differences[i + j*8];
                c <: t; 
            }
            now += pwmCycle;
            c <: now;
//        }
        }
    }
}

void burn(void) {
#if 1
    set_thread_fast_mode_on();
    while(1);
#endif
}

void pwmRunner(streaming chanend c) {
    unsigned clockCount;
    stop_clock(clk);
    configure_out_port_no_ready(pwmPort, clk, 0);
    configure_in_port_no_ready(syncPort, clk);
    start_clock(clk);
    syncPort :> void @ clockCount;
    c <: clockCount;
    pwmWide1(pwmPort, syncPort, c);
}

int main (void) {
    streaming chan c;
    par {
        burn();
        burn();
        burn();
        burn();
        burn();
        signalgenerator(c);
        pwmRunner(c);
    }
    return 0;
}
