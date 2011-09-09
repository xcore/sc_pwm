// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "xsidevice.h"
#include <assert.h>
#include <stdio.h>

void *xsim = 0;

void printbyte(int time, int byte, int dtime) {
    printf("%7d ", time);
    for(int i = 0; i < 8; i++) {
        printf(" %d", (byte >> i)&1);
    }
    printf("%7d \n", dtime);
}

int main(int argc, char **argv) {
    int time = 0, clock = 0, cnt = 0, even = 0, oldready = 0, startTime = 0;
    int othebyte = -1, otime = 0;
    XsiStatus status = xsi_create(&xsim, argv[1]);
    assert(status == XSI_STATUS_OK);
    while (status != XSI_STATUS_DONE && time < 10000000) {
        int thebyte;
        time++;
        xsi_sample_port_pins(xsim, "stdcore[0]", "XS1_PORT_8A", 0xff, (XsiPortData*)&thebyte);
        if (thebyte != othebyte) {
            if (othebyte != -1) {
                printbyte(time-1, othebyte, time - otime);
            }
            printbyte(time, thebyte, 0);
            othebyte = thebyte;
            otime = time;
        }
        if(time % 2 == 0) {
            status = xsi_clock(xsim);
            assert(status == XSI_STATUS_OK || status == XSI_STATUS_DONE );
        }
    }
    status = xsi_terminate(xsim);
    return 0;
}
