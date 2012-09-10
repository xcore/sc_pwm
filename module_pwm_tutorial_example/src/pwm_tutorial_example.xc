// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>

#pragma unsafe arrays
void pwm_tutorial_example ( chanend c, port p) {
  unsigned int duty;
  unsigned int period;
  unsigned int now;
  unsigned int edgetime;

  c :> period;
  c :> duty;

  //start with the output off
  p <: 0;

  //get the current port time
  p :> void @ now; 

  while(1) {
    //obtain time of PWM falling edge
    edgetime = now + duty;

    //output falling edge
    p @ edgetime <: 0;

    //obtain time for end of PWM cycle
    now = now + period;

    //output rising edge
    p @now <: 1;

    //select on channelend tests for new data on the channel from the client 
    select {
      //this case is taken if the channel has data
      case c :> duty:
        break;
      //this case is taken otherwise
      default:
        break;
    }
  }
}

