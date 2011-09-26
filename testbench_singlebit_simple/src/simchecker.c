// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "xsidevice.h"
#include <assert.h>
#include <stdio.h>

void *xsim = 0;

void printword(int time, int word, int dtime) {
    printf("%7d ", time);
    for(int i = 0; i < 16; i++) {
        printf(" %d", (word >> i)&1);
    }
    printf("%7d \n", dtime);
}

int main(int argc, char **argv) {
    int time = 0, clock = 0, cnt = 0, even = 0, oldready = 0, startTime = 0;
    int otheword = -1, otime = 0;
    XsiStatus status = xsi_create(&xsim, argv[1]);
    assert(status == XSI_STATUS_OK);
    while (status != XSI_STATUS_DONE && time < 10000000) {
        int theword, i;
        time++;
        theword = 0;
        xsi_sample_port_pins(xsim, "stdcore[0]", "XS1_PORT_1P", 1, (XsiPortData*)&i); theword = theword << 1 | i;
        xsi_sample_port_pins(xsim, "stdcore[0]", "XS1_PORT_1O", 1, (XsiPortData*)&i); theword = theword << 1 | i;
        xsi_sample_port_pins(xsim, "stdcore[0]", "XS1_PORT_1N", 1, (XsiPortData*)&i); theword = theword << 1 | i;
        xsi_sample_port_pins(xsim, "stdcore[0]", "XS1_PORT_1M", 1, (XsiPortData*)&i); theword = theword << 1 | i;
        xsi_sample_port_pins(xsim, "stdcore[0]", "XS1_PORT_1L", 1, (XsiPortData*)&i); theword = theword << 1 | i;
        xsi_sample_port_pins(xsim, "stdcore[0]", "XS1_PORT_1K", 1, (XsiPortData*)&i); theword = theword << 1 | i;
        xsi_sample_port_pins(xsim, "stdcore[0]", "XS1_PORT_1J", 1, (XsiPortData*)&i); theword = theword << 1 | i;
        xsi_sample_port_pins(xsim, "stdcore[0]", "XS1_PORT_1I", 1, (XsiPortData*)&i); theword = theword << 1 | i;
        xsi_sample_port_pins(xsim, "stdcore[0]", "XS1_PORT_1H", 1, (XsiPortData*)&i); theword = theword << 1 | i;
        xsi_sample_port_pins(xsim, "stdcore[0]", "XS1_PORT_1G", 1, (XsiPortData*)&i); theword = theword << 1 | i;
        xsi_sample_port_pins(xsim, "stdcore[0]", "XS1_PORT_1F", 1, (XsiPortData*)&i); theword = theword << 1 | i;
        xsi_sample_port_pins(xsim, "stdcore[0]", "XS1_PORT_1E", 1, (XsiPortData*)&i); theword = theword << 1 | i;
        xsi_sample_port_pins(xsim, "stdcore[0]", "XS1_PORT_1D", 1, (XsiPortData*)&i); theword = theword << 1 | i;
        xsi_sample_port_pins(xsim, "stdcore[0]", "XS1_PORT_1C", 1, (XsiPortData*)&i); theword = theword << 1 | i;
        xsi_sample_port_pins(xsim, "stdcore[0]", "XS1_PORT_1B", 1, (XsiPortData*)&i); theword = theword << 1 | i;
        xsi_sample_port_pins(xsim, "stdcore[0]", "XS1_PORT_1A", 1, (XsiPortData*)&i); theword = theword << 1 | i;
        if (theword != otheword) {
            if (otheword != -1) {
                printword(time-1, otheword, time - otime);
            }
            printword(time, theword, 0);
            otheword = theword;
            otime = time;
        }
        if(time % 5 == 0 || time % 5 == 2) {
            status = xsi_clock(xsim);
            assert(status == XSI_STATUS_OK || status == XSI_STATUS_DONE );
        }
    }
    status = xsi_terminate(xsim);
    return 0;
}
