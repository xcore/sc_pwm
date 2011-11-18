// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef _PWM_SINGLEBIT_PORT_H_
#define _PWM_SINGLEBIT_PORT_H_

void pwmSingleBitPort(
    chanend c, clock clk,
    out buffered port:32 p[], 
    unsigned int numPorts, 
    unsigned int resolution, 
    unsigned int timeStep,
    unsigned int edge);

void pwmSingleBitPortTrigger(
    chanend c_adc_trig, chanend c, clock clk,
    out buffered port:32 p[],
    unsigned int numPorts,
    unsigned int resolution,
    unsigned int timeStep,
    unsigned int edge);

void pwmSingleBitPortSetDutyCycle(
    chanend c, 
    unsigned int dutyCycle[], 
    unsigned int numPorts);

#endif /* PWM_H_ */

