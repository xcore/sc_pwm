#include <stdlib.h>
#include "pwmPoint.h"

int makeAddress(unsigned int program[], unsigned int pc) {
    return (int) &program[pc];
}

static int compare(const void *p1, const void *p2) {
    return ((struct pwmpoint*)p1)->time - ((struct pwmpoint*)p2)->time;
}

void mysort(struct pwmpoint points[]) {
    qsort(points, 8, sizeof(struct pwmpoint), compare);
}
