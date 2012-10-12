// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <platform.h>
#include "pwm_tutorial_example.h"

#define FLASH_PERIOD 100000000

on stdcore[1]: port ledport = XS1_PORT_4A;

void wait(void) {
    timer tmr;
    unsigned t;
    tmr :> t;
    t+=FLASH_PERIOD;
    tmr when timerafter (t) :> void;
}

void client(chanend c) {
    c <: 200; //set period in 10ns clock ticks (200 us)
    c <: 180; //50% duty  

    wait();
    c <: 180;

    wait();
    c <: 160;

    wait();
    c <: 140;

    wait();
    c <: 120;

    wait();
    c <: 100;

    wait();
    c <: 80;

    wait();
    c <: 60;

    wait();
    c <: 40;
       
}

int main() {
    chan c;

    par {
        on stdcore[1] : client(c);
        on stdcore[1] : pwm_tutorial_example(c, ledport, 4);
    }
    return 0;
}
