// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "pwmWide.h"

#include <xs1.h>

buffered out port:32 p8a = XS1_PORT_8A;

void signalgenerator(chanend c) {
    int differences[24] = {17, 1, 2, 3, 1, 1, 17, 18,
                           8004, 15, 2, 19, 30, 40, 50, 60,
                           8001, 1000, 2000, 1000, 1000, 2000, 2000, 1000};
    int now = 0;
    c <: 5;
    for(int j = 0; j < 3; j++) {
        master {
            for(int i = 0; i < 8; i++) {
                now += differences[i + j*8];
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
        signalgenerator(c);
        pwmWide1(p8a, c);
    }
    return 0;
}
