#ifndef _PWM_MULTIBIT_PORT_H_
#define _PWM_MULTIBIT_PORT_H_

void pwmMultiBitPort(
    chanend c, clock clk,
    out buffered port:32 p, 
    unsigned int portWidth,
    unsigned int resolution, 
    unsigned int timeStep);

void pwmMultiBitPortSetDutyCycle(
    chanend c, 
    unsigned int dutyCycle[], 
    unsigned int portWidth);

#endif /* PWM_H_ */

