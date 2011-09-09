#include "pwmWide.h"

#include <xs1.h>

buffered out port:32 p8a = XS1_PORT_8A;

void signalgenerator(chanend c) {
    int differences[16] = {17, 1, 2, 3, 1, 1, 17, 18,
                          8000, 15, 2, 19, 30, 40, 50, 60};
    int now = 0;
    master {
        for(int i = 0; i < 8; i++) {
            now += differences[i];
            c <: now; 
        }
    }
}

int main (void) {
    chan c;
    par {
        signalgenerator(c);
        pwmWide1(p8a, c);
    }
    return 0;
}
