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

static inline int before(unsigned int t1, unsigned int t2) {
    return ((int)(t1-t2)) < 0;
}

static inline int insertByte(unsigned portval, unsigned byte) {
    return (portval >> 8) | (byte << 24);
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
dispatchShorts(unsigned program[], unsigned previousPC, unsigned pc, unsigned shortones, unsigned shortlist[], int timeDiff, int currentval) {
    program[previousPC] = makeAddress(program, pc);
    program[previousPC+1] = changeOpcode(shortones);
    previousPC = pc;
    pc += 3;                // leave room for nextPC, nextInstr, stable
    program[pc++] = currentval;
    for(int i = 0; i < shortones; i++) {
        program[pc+shortones - i-1] = shortlist[i];
    }
    pc += shortones;
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
    int shortones = 0;
    unsigned shortlist[64];
    while(currentword < numwords) {
        int newtime = words[currentword].time;
        int timeDiff = (newtime - currenttime) >> 2;
        if (timeDiff > 4) {
            {previousPC, pc} = dispatchShorts(program, previousPC, pc, shortones, shortlist, timeDiff, currentval);
            shortones = 0;
        } else {
            while(timeDiff > 0) {
                shortlist[shortones++] = currentval;
                timeDiff--;
            }
        }
        currenttime = newtime;
        currentval = words[currentword].value;
        currentword++;
    }
    if (shortones > 0) {
        {previousPC, pc} = dispatchShorts(program, previousPC, pc, shortones, shortlist, 1000, currentval);
    }
    return {currenttime, previousPC, pc};
}
    
#ifdef unsafearrays
#pragma unsafe arrays    
#endif
unsigned
buildWords(struct pwmpoint points[8], struct pwmpoint words[16], int currenttime, int currentval) {
    int currentpoint = 0;
    int inChange = 0;
    int shortones = 0;
    unsigned shortlist[64];
    int portval = 0;
    unsigned int nexttime;
    int currentword = 0;

    while(currentpoint < 8) {
        int timeDiff;
        int bitcount = 0;
//        printf("Point %d\n", currentpoint);
        portval = 0;
        for(int i = 0; i < (currenttime&3); i++) {
            portval |= currentval << bitcount;
            bitcount += 8;
        }
        currentval = points[currentpoint].value;
        currentpoint++;
        if (currentpoint < 8) {
            nexttime = points[currentpoint].time;
            while (currentpoint < 8 && (currenttime >> 2) == (nexttime >> 2)) {
                while (currenttime != nexttime) {
                    portval |= currentval << bitcount;
                    bitcount += 8;
                    currenttime++;
                }
                currentval = points[currentpoint].value;
                currentpoint++;
                if (currentpoint < 8) {
                    nexttime = points[currentpoint].time;
                }
            }
        }
        while (bitcount < 32) {
            portval |= currentval << bitcount;
            bitcount += 8;
        }
        words[currentword].time = currenttime&~3;
        words[currentword].value = portval;
        currentword++;
        if ((nexttime >> 2) != (currenttime >> 2)+1) {
            words[currentword].time = (currenttime&~3)+4;
            portval = currentval << 8 | currentval;
            portval |= portval << 16;
            words[currentword].value = portval;
            currentword++;
        }
        currenttime = nexttime;
    }
//    for(int i =0; i < currentword; i++) {
//        printf("%8d %08x\n", words[i].time, words[i].value);
//    }
    return currentword;
}

#ifdef unsafearrays
#pragma unsafe arrays    
#endif
void pwmControl1(chanend c, chanend toPWM) {
    struct pwmpoint points[8], words[16];
    int currentval = 0, newval;
    unsigned programspace[128];
    unsigned pc = 0, previousPC;
    unsigned portval = 0;
    unsigned currenttime = 30000;
    int first = 1, numwords;
    timer t;
    int t1, t2, t3, t4, t5, t6;

    previousPC = pc;
    pc += 2;
    programspace[pc++] = currenttime;
    programspace[pc++] = portval;
    first = 1;
    while(1) {
        t :> t1;
        slave {
            for(int i = 0; i < 8; i++) {
                c :> points[i].time;
                points[i].time += currenttime ; // @@@@@@@@@@TEMP@@@@@@@@@@@
//                c :> points[i].value;
                points[i].value = i;
            }
        }
//        t :> t2;
        mysort(points);      // Can be optimised by using two-stage heapsort.
//        t :> t3;
        newval = currentval;
        for(int i = 0; i < 8; i++) {
            newval ^= 1 << points[i].value;
            points[i].value = newval;
        }
//        t :> t4;
        numwords = buildWords(points, words, currenttime, currentval);
//        t :> t5;
        {currenttime, previousPC, pc} = buildprogram(words, programspace, currenttime,currentval, previousPC, pc, numwords);
        currentval = newval;
        if (first) {
//            for(int i = 0; i < pc; i++) {
//                printf("%08x\n", programspace[i]);
//            }
            toPWM <: makeAddress(programspace, 0);
            first = 0;
        }
        t :> t6;
/*        printf("%d for 8\n", t2-t1);
        printf("%d for 8\n", t3-t1);
        printf("%d for 8\n", t4-t1);
        printf("%d for 8\n", t5-t1);*/
        printf("%d for all 8\n", t6-t1);
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
