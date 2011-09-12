// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>


struct pwmpoint {
    int time, value;
};

extern void mysort(struct pwmpoint points[]);
extern void mysort2(struct pwmpoint points[]);
extern int makeAddress(unsigned int program[], unsigned int pc);
