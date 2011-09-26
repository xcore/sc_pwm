// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef _PWM_MULTIBIT_PORT_H_
#define _PWM_MULTIBIT_PORT_H_

void pwmMultiBitPort(
    chanend c, clock clk,
    out buffered port:32 p, 
    unsigned int portWidth,
    unsigned int resolution, 
    unsigned int timeStep,
    unsigned int edge);

void pwmMultiBitPortSetDutyCycle(
    chanend c, 
    unsigned int dutyCycle[], 
    unsigned int portWidth);

#endif /* PWM_H_ */

