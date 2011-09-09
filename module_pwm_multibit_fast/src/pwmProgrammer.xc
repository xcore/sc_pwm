#include "stdio.h"
#include "pwmPoint.h"
#include "pwmWide.h"

//#define unsafearrays

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

#ifdef unsafearrays
#pragma unsafe arrays    
#endif
void
patchLoopIntoChange(unsigned program[], unsigned int previousPC, unsigned pc, int opcode, int time) {
    program[previousPC+2] = opcode;
    program[previousPC+3] = time;
}

#ifdef unsafearrays
#pragma unsafe arrays    
#endif
void
patchStableIntoChange(unsigned program[], unsigned int previousPC, unsigned pc, int time) {
    program[previousPC+2] = stableOpcode(time);
}

#define MAX 8

#ifdef unsafearrays
#pragma unsafe arrays    
#endif
{unsigned, unsigned}
dispatchShorts(unsigned program[], unsigned previousPC, unsigned pc, unsigned shortOnes, unsigned shortlist[], int timeDiff, int currentval) {
    program[previousPC] = makeAddress(program, pc);
    program[previousPC+1] = changeOpcode(shortOnes);
    previousPC = pc;
    pc += 3;                // leave room for nextPC, nextInstr, stable
    program[pc++] = currentval;
    for(int i = 0; i < shortOnes; i++) {
        printf("Short %08x\n", shortlist[i]);
        program[pc+shortOnes - i-1] = shortlist[i];
    }
    pc += shortOnes;
    if (timeDiff > MAX) {
        if (timeDiff & 1) {
            patchLoopIntoChange(program, previousPC, pc, loopOdd, timeDiff);
        } else {
            patchLoopIntoChange(program, previousPC, pc, loopEven, timeDiff);
        }
    } else {
        patchStableIntoChange(program, previousPC, pc, timeDiff);
    }
    return {previousPC, pc};
}

#ifdef unsafearrays
#pragma unsafe arrays    
#endif
{unsigned,unsigned,unsigned}
buildprogram(struct pwmpoint words[16], unsigned program[], unsigned int currenttime, unsigned int currentval, int previousPC, unsigned pc, int numwords) {
    int currentword = 0;
    int shortOnes = 0;
    unsigned shortlist[64];
    while(currentword < numwords) {
        int newtime = words[currentword].time;
        int timeDiff = (int)(newtime - currenttime) >> 2;
        printf("Current %d new %d Timediff %d shortOnes %d\n", currenttime, newtime, timeDiff, shortOnes);
        if (timeDiff > 4) {
            {previousPC, pc} = dispatchShorts(program, previousPC, pc, shortOnes, shortlist, timeDiff, currentval);
            shortOnes = 0;
        } else {
            while(timeDiff > 0) {
                shortlist[shortOnes++] = currentval;
                timeDiff--;
            }
        }
        currenttime = newtime;
        currentval = words[currentword].value;
        currentword++;
    }
    if (shortOnes > 0) {
        {previousPC, pc} = dispatchShorts(program, previousPC, pc, shortOnes, shortlist, 1000, currentval);
    }
    return {currenttime, previousPC, pc};
}
    
#ifdef unsafearrays
#pragma unsafe arrays    
#endif
{unsigned,unsigned}
buildWords(struct pwmpoint points[8], struct pwmpoint words[16], int currenttime, int currentval) {
    int currentpoint = 0;
    int portval = 0;
    unsigned int nexttime;
    int wordCount = 0;
    int timeDiff;
    int bitcount = 0;
//        printf("Point %d\n", currentpoint);
    currenttime = points[0].time & ~3;
    while(1) {
        nexttime = points[currentpoint].time;
        if ((currenttime >> 2) == (nexttime >> 2)) {
            while (currenttime != nexttime) {
                portval |= currentval << bitcount;
                bitcount += 8;
                currenttime++;
            }
        } else {
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
            currenttime = nexttime;
        }

        currentval = points[currentpoint].value;
        currentpoint++;
        if (currentpoint == 8) {
            if (bitcount != 0) {
                while (bitcount < 32) {
                    portval |= currentval << bitcount;
                    bitcount += 8;
                }
                words[wordCount].time = currenttime&~3;
                words[wordCount].value = portval;
                wordCount++;
            }
            return {wordCount, currentval};
        }
    }
}

#ifdef unsafearrays
#pragma unsafe arrays    
#endif
void pwmControl1(chanend c, chanend toPWM) {
    struct pwmpoint points[8], words[16];
    int currentval = 0, newval;
    unsigned programspace[128];
    unsigned pc = 0, previousPC;
    unsigned currenttime = 30000;
    int first = 1, numwords, currentByte = 0;

    first = 1;
    while(1) {
        slave {
            for(int i = 0; i < 8; i++) {
                c :> points[i].time;
                points[i].value = i;
            }
        }
        mysort(points);      // Can be optimised by using two-stage heapsort.
        newval = currentval;
        for(int i = 0; i < 8; i++) {
            newval ^= 1 << points[i].value;
            points[i].value = newval;
        }
        if (first == 1) {
            currenttime = points[0].time-10;
            currentval = 0;
            previousPC = pc;
            pc += 2;
            programspace[pc++] = currenttime;
            programspace[pc++] = currentval;
        }
        {numwords,currentByte} = buildWords(points, words, currenttime, currentByte);
        for(int i =0; i < numwords; i++) {
            printf("%8d %08x\n", words[i].time, words[i].value);
        }
        {currenttime, previousPC, pc} = buildprogram(words, programspace, currenttime,currentval, previousPC, pc, numwords);
        currentval = newval;
        first++;
        if (first == 3) {
            for(int i = 0; i < pc; i++) {
                explain(makeAddress(programspace, i), programspace[i]);
            }
            toPWM <: makeAddress(programspace, 0);
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
