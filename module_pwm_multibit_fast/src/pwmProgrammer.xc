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


#ifdef unsafearrays
#pragma unsafe arrays    
#endif
void pwmControl1(streaming chanend c, chanend toPWM) {
    unsigned pc, indexForOPCandDP;
    unsigned currenttime;
    int first = 1, currentByte = 0;
    timer t;
    int ot, t1, t2,t3,t4;
    int shortOnes = 0;
    int portval = 0;
    struct pwmpoint points[8];
    int multiplierOneTable[4] = {
        0x01010101, 0x01010100, 0x01010000, 0x01000000,
    };
    int multiplierTable[16] = {
        0x00000000, 0x00000001, 0x00000101, 0x00010101,
        0xDEADBEEF, 0xDEADBEEF, 0x00000100, 0x00010100,
        0xDEADBEEF, 0xDEADBEEF, 0xDEADBEEF, 0x00010000,
        0xDEADBEEF, 0xDEADBEEF, 0xDEADBEEF, 0xDEADBEEF,
    };
    unsigned programSpace[256];

    c :> currenttime;
    programSpace[0] = 0;
    programSpace[1] = currenttime;
    indexForOPCandDP = 2;
    pc = 4;

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
        sortPoints(points);
        t :> t3;
        for(int currentpoint = 0; currentpoint != 8; currentpoint++) {
            unsigned nexttime = points[currentpoint].time;
            int diff = (nexttime >> 2) - (currenttime >> 2); // todo: wrap
//            printf("Current %d next %d: whole words diff %d, remnants left %d, remnants to do %d (cur %02x)\n",
//                   currenttime, nexttime, diff, currenttime&3, nexttime&3, currentByte);
            if (diff != 0) {
                diff--;
                portval |= currentByte * multiplierOneTable[currenttime & 3];
                shortOnes++;
                programSpace[pc++] = portval;
//                printf("Whole word: %08x\n", portval);
                if (diff >= 4) {
                    programSpace[pc++] = currentByte * 0x01010101;
                    if (diff >= MAX) {
                        if (diff & 1) {
                            programSpace[pc] = diff-LOOPODDOFFSET;
                            programSpace[pc+1] = loopOdd;
                        } else {
                            programSpace[pc] = diff-LOOPEVENOFFSET;
                            programSpace[pc+1] = loopEven;
                        }
                    } else {
                        programSpace[pc+1] = stableOpcode(diff);
                    }
                    pc += 4;    // leave room for nextPC, nextInstr, stable, loopcount
                    
                    // Now patch into previous instruction
                    programSpace[indexForOPCandDP] = changeOpcode(shortOnes);
                    programSpace[indexForOPCandDP+1] = makeAddress(programSpace, pc) - 256;            
                    indexForOPCandDP = pc - 2;
                    shortOnes = 0;
                } else {
#if 1
                    int theWord;
                    switch(diff) {
                    case 3:
                        theWord = currentByte * 0x01010101;
                        programSpace[pc++] = theWord;
                        programSpace[pc++] = theWord;
                        programSpace[pc++] = theWord;
                        shortOnes+=3;
                        break;
                    case 2:
                        theWord = currentByte * 0x01010101;
                        programSpace[pc++] = theWord;
                        programSpace[pc++] = theWord;
                        shortOnes+=2;
                        break;
                    case 1:
                        programSpace[pc++] = currentByte * 0x01010101;
                        shortOnes++;
                        break;
                    case 0:
                        break;
                    default:
//                        __builtin_unreachable();
                        break;
                    }
#else
                    shortOnes+=diff;
                    while(diff > 0) {
                        programSpace[pc++] = currentByte * 0x01010101;
                        diff--;
                    }
#endif
                }
                portval = currentByte * multiplierTable[(nexttime & 3)];
            } else {
                int x = multiplierTable[(currenttime & 3) << 2 | (nexttime & 3)];
                portval |= currentByte * x;
            }
            currenttime = nexttime;
            currentByte ^= points[currentpoint].value;
        }



        t :> t4;
        first++;
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
