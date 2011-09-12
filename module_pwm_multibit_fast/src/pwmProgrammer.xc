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

#define MAX 8
#define LOOPOFFSET 6


#ifdef unsafearrays
#pragma unsafe arrays    
#endif
{unsigned,unsigned,unsigned}
static inline buildprogram(struct pwmpoint words[16], unsigned program[], unsigned int currenttime, int indexForOPCandDP, unsigned pc, int numwords) {
    int currentword = 0;
    static int shortOnes = 0;
    static int currentval;
    while(currentword < numwords) {
        int newtime = words[currentword].time;
        int timeDiff = (int)(newtime - currenttime) >> 2;
        if (timeDiff > 4) {
            program[pc++] = currentval;
            if (timeDiff > MAX) {
                if (timeDiff & 1) {
                    program[pc] = timeDiff-1-LOOPOFFSET;
                    program[pc+1] = loopOdd;
                } else {
                    program[pc] = timeDiff-LOOPOFFSET;
                    program[pc+1] = loopEven;
                }
            } else {
                program[pc+1] = stableOpcode(timeDiff);
            }
            pc += 4;                // leave room for nextPC, nextInstr, stable, loopcount
            
            // Now patch into previous instruction
            program[indexForOPCandDP] = changeOpcode(shortOnes);
            program[indexForOPCandDP+1] = makeAddress(program, pc) - 256;            
            indexForOPCandDP = pc - 2;
            shortOnes = 0;
        } else {
            while(timeDiff > 0) {
                shortOnes++;
                program[pc++] = currentval;
                timeDiff--;
            }
        }
        currenttime = newtime;
        currentval = words[currentword].value;
        currentword++;
    }
    return {currenttime, indexForOPCandDP, pc};
}
    
#ifdef unsafearrays
#pragma unsafe arrays    
#endif
{unsigned,unsigned}
static inline buildWords(struct pwmpoint points[8], struct pwmpoint words[16], int currenttime, int currentval) {
    int currentpoint = 0;
    int portval = 0;
    unsigned int nexttime;
    int wordCount = 0;
    int bitcount = 0;
//        printf("Point %d\n", currentpoint);
    currenttime = points[0].time & ~3;
    while(currentpoint != 8) {
        nexttime = points[currentpoint].time;
        if ((currenttime >> 2) != (nexttime >> 2)) {
            while (bitcount < 32) {
                portval |= currentval << bitcount;
                bitcount += 8;
            }
            words[wordCount].time = currenttime&~3;
            words[wordCount].value = portval;
            wordCount++;
            if ((nexttime >> 2) != (currenttime >> 2)+1) {
                words[wordCount].time = (currenttime&~3)+4;
                portval = currentval << 8 | currentval;
                portval |= portval << 16;
                words[wordCount].value = portval;
                wordCount++;
            }
            bitcount = 0;
            portval = 0;
            currenttime = nexttime&~3;
        }
        while (currenttime != nexttime) {
            portval |= currentval << bitcount;
            bitcount += 8;
            currenttime++;
        }

        currentval = points[currentpoint].value;
        currentpoint++;
    }
    while (bitcount < 32) {
        portval |= currentval << bitcount;
        bitcount += 8;
    }
    words[wordCount].time = currenttime&~3;
    words[wordCount].value = portval;
    wordCount++;
    return {wordCount, currentval};
}

#ifdef unsafearrays
#pragma unsafe arrays    
#endif
void pwmControl1(chanend c, chanend toPWM) {
    struct pwmpoint points[8], words[16];
    int currentval = 0, newval;
    unsigned programspace[256];
    unsigned pc = 0, indexForOPCandDP;
    unsigned currenttime = 0xdeadbeef;
    int first = 1, numwords, currentByte = 0;
    timer t;
    int ot, t1, t2,t3,t4,t5;

    first = 1;
    while(1) {
        ot = t1;
        t :> t1;
//        printf("%d: in (%d) sort (%d) build (%d) prog (%d)\n", t1-ot, t2-ot, t3-t2, t4-t3, t5-t4);
        t :> t1;
        slave {
            for(int i = 0; i < 8; i++) {
                c :> points[i].time;
            }
        }
        t :> t2;
        mysort2(points);      // Can be optimised by using two-stage heapsort.
        t :> t3;
        newval = currentval;
        for(int i = 0; i < 8; i++) {
            newval ^= 1 << points[i].value;
            points[i].value = newval;
        }
        if (first == 1) {
            currenttime = points[0].time-10;
            currentval = 0;
            programspace[0] = currentval;
            programspace[1] = currenttime;
            indexForOPCandDP = 2;
            pc += 4;
        }
        {numwords,currentByte} = buildWords(points, words, currenttime, currentByte);
        t :> t4;
//        for(int i =0; i < numwords; i++) {
//            printf("%8d %08x\n", words[i].time, words[i].value);
//        }
        {currenttime, indexForOPCandDP, pc} = buildprogram(words, programspace, currenttime, indexForOPCandDP, pc, numwords);
        t :> t5;
        currentval = newval;
        first++;
        if (first == 3) {
#if 0
            for(int i = 0; i < pc; i++) {
                explain(makeAddress(programspace, i), programspace[i]);
            }
#endif
            toPWM <: makeAddress(programspace, 0) - 240;
            first = 0;
        }
    }
}

extern void doPWM8(buffered out port:32 p8, chanend toPWM);

void pwmWide1(buffered out port:32 p8, chanend c) {
    chan toPWM;
    par {
        doPWM8(p8, toPWM);
        pwmControl1(c, toPWM);
    }
}
