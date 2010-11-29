#ifndef _PWM_SINGLEBIT_PORT_H_
#define _PWM_SINGLEBIT_PORT_H_

void pwmSingleBitPort(
    chanend c, clock clk,
    out buffered port:32 p[], 
    unsigned int numPorts, 
    unsigned int resolution, 
    unsigned int timeStep);

void pwmSingleBitPortSetDutyCycle(
    chanend c, 
    unsigned int dutyCycle[], 
    unsigned int numPorts);

#endif /* PWM_H_ */

