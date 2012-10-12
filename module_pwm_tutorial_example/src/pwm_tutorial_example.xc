// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <assert.h>
#include <stdio.h>

#pragma unsafe arrays
void pwm_tutorial_example ( chanend c, out port p, unsigned port_width) {
  unsigned int duty;
  unsigned int period;
  unsigned int val;
  unsigned int now;
  unsigned int edgetime;

  c :> period;
  c :> duty;

  // check input values
  if(duty>period) {
	  printf("ERROR: PWM duty cycle length %d is greater than period %d",duty, period);
	  assert(0);
  }
  if(port_width>32) {
	  printf("ERROR: port_width %d is greater than the maximum 32",port_width);
  }

  val = (1<<port_width)-1; // generate port value

  //start with the output off
  p <: 0;

  //get the current port time
  p <: 0 @ now; 

  while(1) {
	if(period != duty) { // if not always on
	  //obtain time of PWM falling edge
      edgetime = now + duty;

      //output falling edge
      p @ edgetime <: 0;
	};


	if(duty != 0) { // if not always off
	  //obtain time for end of PWM cycle
      now = now + period;

      //output rising edge
      p @now <: val;
	}

    //select on channelend tests for new data on the channel from the client 
    select {
      //this case is taken if the channel has data
      case c :> duty:
    	if(duty>period) { // check value
    	    printf("ERROR: PWM duty cycle length %d is greater than period %d",duty, period);
    		assert(0);
    	}
        break;
      //this case is taken otherwise
      default:
        break;
    }
  }
}

