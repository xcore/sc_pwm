// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "stdio.h"
#include "pwmPoint.h"
#include "pwmWide.h"

#define unsafearrays

extern int changeZero;
extern int stableZero;
extern int loopEven;
extern int loopOdd;


static inline int stableOpcode(int K) {
    return stableZero - (K << 1);
}

static inline int changeOpcode(int K) {
    return changeZero - (K << 2);
}

#if 0
static void explain(unsigned addr, unsigned w) {
    printf("%08x  %08x ", addr, w);
    if (w > stableZero - 20 && w <= stableZero) {
        printf("  Stable%d", (stableZero-w)>>1);
    } 
    if (w > changeZero - 80 && w <= changeZero) {
        printf("  Change%d", (changeZero-w)>>2);
    } 
    if (w == loopEven) {
        printf("  Loop Even");
    }
    if (w == loopOdd) {
        printf("  Loop Odd");
    }
    printf("\n");
}
#endif

#define MAX 8
#define LOOPODDOFFSET  5
#define LOOPEVENOFFSET 6

const int multiplierOneTable[4] = {
    0x01010101, 0x01010100, 0x01010000, 0x01000000,
};
const int multiplierTable[16] = {
    0x00000000, 0x00000001, 0x00000101, 0x00010101,
    0xDEADBEEF, 0x00000000, 0x00000100, 0x00010100,
    0xDEADBEEF, 0xDEADBEEF, 0x00000000, 0x00010000,
    0xDEADBEEF, 0xDEADBEEF, 0xDEADBEEF, 0x00000000,
};

#ifdef unsafearrays
#pragma unsafe arrays    
#endif
void pwmControl1(streaming chanend c, chanend toPWM) {
    unsigned pc;
    unsigned currenttime;
    unsigned  first = 1, currentByte = 0;
    timer t;
    int ot, t1, t2,t3,t4;
    unsigned int portval = 0;
    struct pwmpoint points[8];
    unsigned programSpace[256];
    unsigned startPC;
    unsigned int ct3;

    int addressOffset = makeAddress(programSpace, 0) - 256;

    c :> currenttime;
    programSpace[0] = 0;
    programSpace[1] = currenttime;
    pc = 4;
    startPC = pc;
    ct3 = 0;

    while(1) {
        ot = t1;
        t :> t1;
        printf("%d: in (%d) sort (%d) build (%d)\n", t1-ot, t2-ot, t3-t2, t4-t3);
        t :> t1;
//        slave {
            for(int i = 0; i < 8; i++) {
                c :> points[i].time;
            }
//        }
        t :> t2;
        first++;
        sortPoints(points);
        t :> t3;
        for(int currentpoint = 0; currentpoint != 8; currentpoint++) {
            unsigned nexttime = points[currentpoint].time;
            unsigned nt3 = nexttime & 3;
            unsigned diff;
            nexttime -= nt3;                    // nexttime is guaranteed a multiple of 4.
            diff = nexttime - currenttime;      // diff is guaranteed a multiple of 4.
            if (diff != 0) {
                diff = (diff >> 2) - 1;
                portval |= currentByte * multiplierOneTable[ct3];
                programSpace[pc++] = portval;
                if (diff >= MAX) {
                    int nWords = pc - startPC;
                    programSpace[pc] = currentByte * 0x01010101;
                    if (diff & 1) {                 // todo: move this to pwm.S
                        programSpace[pc+1] = diff-LOOPODDOFFSET;
                        programSpace[pc+2] = loopOdd;
                    } else {
                        programSpace[pc+1] = diff-LOOPEVENOFFSET;
                        programSpace[pc+2] = loopEven;
                    }
                    pc += 5;    // leave room for nextPC, nextInstr, stable, loopcount
                    
                    // Now patch into previous instruction
                    programSpace[startPC-2] = changeOpcode(nWords);
                    programSpace[startPC-1] = pc*4 + addressOffset;
                    startPC = pc;
                } else if (diff >= 4) {
                    int nWords = pc - startPC;
                    programSpace[pc] = currentByte * 0x01010101;
                    programSpace[pc+2] = stableOpcode(diff);
                    pc += 5;    // leave room for nextPC, nextInstr, stable, loopcount
                    
                    // Now patch into previous instruction
                    programSpace[startPC-2] = changeOpcode(nWords);
                    programSpace[startPC-1] = pc*4 + addressOffset;
                    startPC = pc;
                } else {
                    switch(diff) {
                    case 3:
                        portval = currentByte * 0x01010101;
                        programSpace[pc++] = portval;
                        programSpace[pc++] = portval;
                        programSpace[pc++] = portval;
                        break;
                    case 2:
                        portval = currentByte * 0x01010101;
                        programSpace[pc++] = portval;
                        programSpace[pc++] = portval;
                        break;
                    case 1:
                        portval = currentByte * 0x01010101;
                        programSpace[pc++] = portval;
                        break;
                    case 0:
                        break;
                    default:
//                        __builtin_unreachable();
                        break;
                    }
                }
                portval = currentByte * multiplierTable[nt3];
            } else {
                int x = multiplierTable[ct3 << 2 | nt3];
                portval |= currentByte * x;
            }
            currenttime = nexttime;
            ct3 = nt3;
            currentByte ^= points[currentpoint].value;
        }



        t :> t4;
        if (first == 3) {
#if 0
            for(int i = 0; i < pc; i++) {
                explain(makeAddress(programSpace, i), programSpace[i]);
            }
#endif
            toPWM <: makeAddress(programSpace, 0) - 240;
            first = 0;
        }
    }
}

extern void doPWM8(buffered out port:32 p8, chanend toPWM);

void pwmWide1(buffered out port:32 p8, streaming chanend c) {
    chan toPWM;
    par {
        doPWM8(p8, toPWM);
        pwmControl1(c, toPWM);
    }
}
