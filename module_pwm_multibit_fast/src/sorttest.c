// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "pwmPoint.h"

#define unsafearrays

#define DOMIDDLE(o, t0, t1, v0, v1) \
                    if (t0 < t1) { \
                        o[1].time = t0; o[1].value = v0; \
                        o[2].time = t1; o[2].value = v1; \                     
                    } else { \
                        o[2].time = t0; o[2].value = v0; \
                        o[1].time = t1; o[1].value = v1; \
                    }

#ifdef unsafearrays
#pragma unsafe arrays    
#endif
void halfsort(int t0, int t1, int t2, int t3, struct pwmpoint o[]) {
    if (t0 < t1) {
        if (t2 < t3) {
            if (t0 < t2) {           // t0 smallest
                o[0].time = t0; o[0].value = 0;
                if (t1 > t3) {           // t1 biggest
                    o[3].time = t1; o[3].value = 1;
                    DOMIDDLE(o, t2, t3, 2, 3);
                } else {                 // t3 biggest
                    o[3].time = t3; o[3].value = 3;
                    DOMIDDLE(o, t2, t1, 2, 1);
                }
            } else {                 // t2 smallest
                o[0].time = t2; o[0].value = 2;
                if (t1 > t3) {           // t1 biggest
                    o[3].time = t1; o[3].value = 1;
                    DOMIDDLE(o, t0, t3, 0, 3);
                } else {                 // t3 biggest
                    o[3].time = t3; o[3].value = 3;
                    DOMIDDLE(o, t0, t1, 0, 1);
                }
            }
        } else {
            if (t0 < t3) {           // t0 smallest
                o[0].time = t0; o[0].value = 0;
                if (t1 > t2) {           // t1 biggest
                    o[3].time = t1; o[3].value = 1;
                    DOMIDDLE(o, t2, t3, 2, 3);
                } else {                 // t2 biggest
                    o[3].time = t2; o[3].value = 3;
                    DOMIDDLE(o, t1, t3, 1, 3);
                }
            } else {                 // t3 smallest
                o[0].time = t3; o[0].value = 3;
                if (t1 > t2) {           // t1 biggest
                    o[3].time = t1; o[3].value = 1;
                    DOMIDDLE(o, t0, t2, 0, 2);
                } else {                 // t2 biggest
                    o[3].time = t2; o[3].value = 2;
                    DOMIDDLE(o, t0, t1, 0, 1);
                }
            }
        }
    } else {
        if (t0 < t3) {
            if (t2 < t0) {           // t2 smallest
                o[0].time = t2; o[0].value = 2;
                if (t1 > t3) {           // t1 biggest
                    o[3].time = t1; o[3].value = 1;
                    DOMIDDLE(o, t0, t3, 0, 3);
                } else {                 // t3 biggest
                    o[3].time = t3; o[3].value = 3;
                    DOMIDDLE(o, t0, t1, 0, 1);
                }
            } else {                 // t0 smallest
                o[0].time = t0; o[0].value = 0;
                if (t1 > t3) {           // t1 biggest
                    o[3].time = t1; o[3].value = 1;
                    DOMIDDLE(o, t2, t3, 2, 3);
                } else {                 // t3 biggest
                    o[3].time = t3; o[3].value = 3;
                    DOMIDDLE(o, t2, t1, 2, 1);
                }
            }
        } else {
            if (t2 < t3) {           // t2 smallest
                o[0].time = t2; o[0].value = 2;
                if (t1 > t0) {           // t1 biggest
                    o[3].time = t1; o[3].value = 1;
                    DOMIDDLE(o, t0, t3, 0, 3);
                } else {                 // t0 biggest
                    o[3].time = t0; o[3].value = 0;
                    DOMIDDLE(o, t1, t3, 1, 3);
                }
            } else {                 // t3 smallest
                o[0].time = t3; o[0].value = 3;
                if (t1 > t0) {           // t1 biggest
                    o[3].time = t1; o[3].value = 1;
                    DOMIDDLE(o, t2, t0, 2, 0);
                } else {                 // t0 biggest
                    o[3].time = t0; o[3].value = 0;
                    DOMIDDLE(o, t2, t1, 2, 1);
                }
            }
        }
    }
}

#ifdef unsafearrays
#pragma unsafe arrays    
#endif
void mysort2(struct pwmpoint x[8]) {
    struct pwmpoint yl[5];
    struct pwmpoint yr[5];
    int l = 0, r = 0;
    halfsort(x[0].time, x[1].time, x[2].time, x[3].time, yl);
    halfsort(x[4].time, x[5].time, x[6].time, x[7].time, yr);
    yl[4].time = yr[3].time+1;
    yr[4].time = yl[3].time+1;
    for(int w = 0; w < 8; w++) {
        if (yl[l].time < yr[r].time) {
            x[w].time = yl[l].time;
            x[w].value = yl[l].value;
            l++;
        } else {
            x[w].time = yr[r].time;
            x[w].value = yr[r].value+4;
            r++;
        }
    }
}
