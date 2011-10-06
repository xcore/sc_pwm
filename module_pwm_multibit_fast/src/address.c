// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <stdlib.h>
#include "pwmPoint.h"

int makeAddress(unsigned int program[], unsigned int pc) {
    return (int) &program[pc];
}
