// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include "stdio.h"
#include "pwmPoint.h"
#include "pwmWide.h"

#define unsafearrays

extern int changeZero;
extern int stableZero;
extern int loopEven;
extern int loopOdd;
extern int loopAround;


static inline int stableOpcode(int K) {
    return stableZero - (K << 1);
}

static inline int changeOpcode(int K) {
    return changeZero - (K << 2);
}

#if 0
static void explain(int i, unsigned addr, unsigned w, int pc) {
    printf("%3d  %08x  %08x ", i, addr, w);
    if (w > stableZero - 20 && w <= stableZero) {
        printf("  Stable%d", (stableZero-w)>>1);
    } 
    if (w > changeZero - 80 && w <= changeZero) {
        printf("  Change%d", (changeZero-w)>>2);
    } 
    if (w == loopAround) {
        printf("  Loop Around");
    }
    if (i ==pc) printf(" ***\n");
    printf("\n");
}

static void explainAll(unsigned programSpace[], int n, int pc) {
    for(int i = 0; i < n; i++) {
        explain(i, makeAddress(programSpace, i), programSpace[i], pc);
    }
}

#endif

#define MAX 16

const int multiplierOneTable[4] = {
    0x01010101, 0x01010100, 0x01010000, 0x01000000,
};
const int multiplierTable[16] = {
    0x00000000, 0x00000001, 0x00000101, 0x00010101,
    0xDEADBEEF, 0x00000000, 0x00000100, 0x00010100,
    0xDEADBEEF, 0xDEADBEEF, 0x00000000, 0x00010000,
    0xDEADBEEF, 0xDEADBEEF, 0xDEADBEEF, 0x00000000,
};

#define MAXHALFCYCLE 40
#define PROGRAMSPACESIZE (256+MAXHALFCYCLE)

#ifdef unsafearrays
#pragma unsafe arrays    
#endif
void pwmControl1(in port syncport, streaming chanend c, streaming chanend toPWM) {
    unsigned pc;
    unsigned currenttime;
    unsigned int portval = 0;
    unsigned startPC;
    unsigned int ct3;
    unsigned int synctime, newsynctime, oldsynctime;
    unsigned currentByte;
    int addressOffset;
//    int first = 0;

    int numWords = 0;
    int t1, t2;
    timer t;
    struct pwmpoint points[8];
    unsigned programSpace[PROGRAMSPACESIZE];

    addressOffset = makeAddress(programSpace, 0) - 256;

    c :> currentByte;
    c :> currenttime;
    programSpace[0] = currentByte * 0x01010101;
    programSpace[1] = currenttime;
    pc = 4;
    startPC = pc;
    ct3 = 0;

    schkct(toPWM, 0);                             // Wait for PWM thread to be ready.
    toPWM <: makeAddress(programSpace, 0) - 240;  // Set PWM thread going

    oldsynctime = currenttime - 8000;
    synctime = currenttime;

    while(1) {
        t :> t1;
//        slave {
            for(int i = 0; i < 8; i++) {
                c :> points[i].time;
            }
            c :> newsynctime ;
//        }
        sortPoints(points);
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
                    programSpace[pc] = currentByte * 0x01010101;
                    programSpace[pc+1] = diff;
                    programSpace[pc+2] = loopAround;
                    pc += 5;    // leave room for nextPC, nextInstr, stable, loopcount
                    
                    // Now patch into previous instruction
                    programSpace[startPC-2] = changeOpcode(numWords+1);
                    programSpace[startPC-1] = pc*4 + addressOffset;
                    startPC = pc;
                    numWords = 0;
                    if (pc >= PROGRAMSPACESIZE - MAXHALFCYCLE) {
                        pc = 0;
                    }
                } else if (diff >= 4) {
                    programSpace[pc] = currentByte * 0x01010101;
                    programSpace[pc+2] = stableOpcode(diff);
                    pc += 5;    // leave room for nextPC, nextInstr, stable, loopcount
                    
                    // Now patch into previous instruction
                    programSpace[startPC-2] = changeOpcode(numWords+1);
                    programSpace[startPC-1] = pc*4 + addressOffset;
                    numWords = 0;
                    startPC = pc;
                } else {
                    switch(diff) {
                    case 3:
                        portval = currentByte * 0x01010101;
                        programSpace[pc++] = portval;
                        programSpace[pc++] = portval;
                        programSpace[pc++] = portval;
                        numWords += 4;
                        break;
                    case 2:
                        portval = currentByte * 0x01010101;
                        programSpace[pc++] = portval;
                        programSpace[pc++] = portval;
                        numWords += 3;
                        break;
                    case 1:
                        portval = currentByte * 0x01010101;
                        programSpace[pc++] = portval;
                        numWords += 2;
                        break;
                    case 0:
                        numWords += 1;
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
        t :> t2;
        printf("%d\n", t2-t1);
#pragma xta endpoint "loop"
        syncport @ oldsynctime :> void;
        oldsynctime = synctime;
        synctime = newsynctime;
#if 0
        if (first++ == 9) {
            explainAll(programSpace, PROGRAMSPACESIZE, pc);
        }
#endif
    }
}

extern void doPWM8(buffered out port:32 p8, streaming chanend toPWM);

void pwmWide1(buffered out port:32 p8, in port syncport, streaming chanend c) {
    streaming chan toPWM;
    par {
        doPWM8(p8, toPWM);
        pwmControl1(syncport, c, toPWM);
    }
}
