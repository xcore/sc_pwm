#include <assert.h>
#include <print.h>
#include <stdlib.h>
#include <stdio.h>
#include <xs1.h>
#include "pwm_multibit_port.h"

#define MAX_PORT_WIDTH 16

static void setUp(
    unsigned int portWidth, unsigned int &clocksPerPeriod);

#pragma unsafe arrays
void pwmMultiBitPort(
    chanend c, clock clk,
    out buffered port:32 p,
    unsigned int portWidth,
    unsigned int resolution, 
    unsigned int timeStep,
    unsigned int edge) {

    timer t;
    unsigned int time,time_div;
    unsigned int portIndex;
    unsigned int port_val[16],port_value;
    unsigned int k,i;
    unsigned int portValue,port_bit[32];
    unsigned int nextDutyCycle[MAX_PORT_WIDTH] = {0};
    unsigned int dutyCycle[MAX_PORT_WIDTH] = {0};
    unsigned int clocksPerPeriod;
    unsigned int clocksPerPeriodMask;
    unsigned int period,period_32;
    unsigned int numTicks = resolution;
    unsigned int no_bits;
    unsigned int i1,m,j;
    unsigned int value_te;
    unsigned int value_le;

    // Sets up some initial values based on the given port width.
    setUp(portWidth, clocksPerPeriod);

    // Calculates the timer period
    period = (timeStep == 0) ? clocksPerPeriod : clocksPerPeriod * (timeStep * 2);
    period_32 = (timeStep == 0) ? 32 : 32 * (timeStep * 2);

    // Configures the port clocks.
    set_clock_div(clk, timeStep);
    set_port_clock(p, clk);
    start_clock(clk);

    // Gets the initial time. 

    t :> time;
    time += period;
    time_div = time;
    while (1) {
        select {
        // A new set of duty cycle values are avaliable.
        #pragma xta endpoint "updateDutyCycle"
        case slave { 
            int i = 0;
            do { 
                c :> nextDutyCycle[i];  
                ++i; 
            } while (i < portWidth);}:
            break;

        // Handles the pwm output.
        #pragma xta endpoint "handlePwm"
        case t when timerafter (time) :> void:
            // Updates the current value of the duty cycles.
            if (numTicks == resolution) {
                for (unsigned int i = 0; i < portWidth; ++i) {
                    #pragma xta label "nextDutyCycleLoop"
                    dutyCycle[i] = nextDutyCycle[i];
                }
                numTicks = 0;
            }
           
            // Calculates the value to be output on the port.
            portValue = 0; 
            for (unsigned int i = 0; i < portWidth; ++i) {
                #pragma xta label "calculatePortValueLoop"
                unsigned int value = dutyCycle[i];
                //Leading edge
                if(edge == 1){
					if(value <= numTicks){
						port_val[i] = 0x0;
					} else if(value >= (numTicks + 32)){
						port_val[i] = 0xffffffff;
					} else {
						port_val[i] = ((1 << (value & 0x1f)) - 1);
					}
                } else if(edge == 2){ // Trailing Edge
                	value_te = resolution - value;
                	if(value_te >= (numTicks + 32)){
                		port_val[i] = 0x0;
                	} else if(value_te <= numTicks){
                		port_val[i] = 0xffffffff;
                	} else {
                		port_val[i] = (0xffffffff << (value_te & 0x1f));
                	}
                } else if(edge ==3){ //Center Edge
                	value_le = (resolution + value)>>1;
                	value_te = (resolution - value)>>1;

                	if ( (value <= 32) && ((resolution>>5) & 0x1)){
                	     if (((resolution>>1) > numTicks) && ((resolution>>1) < (numTicks + 32))) {
                	          if(value == 0){
                	        	  port_val[i] = 0x0;
                	          } else {
                	        	  port_val[i] = ((0xffffffff >> ((32-value) & 0x1f))<<(16 - (value>>1)));
                	          }
                	     } else {
                	    	 port_val[i] = 0x0;
                	     }
                	} else {
                		if(value_te >= (numTicks + 32)){
                			port_val[i] = 0x0;
                		} else if((value_te > numTicks) && (value_te < (numTicks + 32))){
                			port_val[i] = (0xffffffff << (value_te & 0x1f));
                		} else if (value_le <= numTicks){
                			port_val[i] = 0x0;
                		} else if((value_le > numTicks) && (value_le < (numTicks + 32))){
                			port_val[i] = (0xffffffff >> ((numTicks + 32) - value_le));
                		}else {
                			port_val[i] = 0xffffffff;
                		}
                	}
                }
            }
            no_bits = (32/portWidth);

            for(i1=0; i1 < portWidth; i1++){
            	m=0;
            	for(i=0; i < portWidth; i++){
            		k = 1;
            		//m = 0;
            		for(j=0; j < no_bits; j++){
            			port_bit[m] = port_val[i] & k;
                		k = k << 1;
                		m++;
            		}
            		port_val[i] = port_val[i] >> no_bits;

            	}
               	port_value = 0;
               	k=0;
               	for(i=0; i < no_bits; i++){
                   	for(j=0; j < 32; j+=no_bits){
                   		port_value = port_value + (port_bit[i+j] << (k-i));
                   		k++;
                   	}
               	}
               	p <: port_value;
            	time_div = time_div + period;
            	if(i1 < (portWidth-1))
            		t when timerafter (time_div) :> void;
            }
            numTicks += 32;
            time += period_32;
            break;
        }
    }
}

void pwmMultiBitPortSetDutyCycle(
    chanend c, 
    unsigned int dutyCycle[], 
    unsigned int portWidth) {

    master {
        for (unsigned int i = 0; i < portWidth; ++i) {
            c <: dutyCycle[i];
        }
    }
}

static void setUp(
    unsigned int portWidth, unsigned int &clocksPerPeriod) {

    switch (portWidth) {
    case 4:
        clocksPerPeriod = 8;
        break;

    case 8:
        clocksPerPeriod = 4;
        break;

    case 16:
        clocksPerPeriod = 2;
        break;
   
    default:
        assert(0);
        break;
    }
}
