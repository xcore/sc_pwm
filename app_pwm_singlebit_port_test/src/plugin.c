// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <syscall.h>
#include "plugin.h"

#define NOTIFY_PWM_PLUGIN_DONE_ADDRESS 1000
#define NOTIFY_PWM_PLUGIN_MAX_NUM_CYCLES 1001

void setupPluginWait(unsigned char buffer[], unsigned int maxNumCycles) {
    // Informs the plugin of the 'done' address which is 
    // uses to signal back to us that the pwm has finished.
    _plugins(NOTIFY_PWM_PLUGIN_DONE_ADDRESS, (unsigned int)buffer, 0);
    _plugins(NOTIFY_PWM_PLUGIN_MAX_NUM_CYCLES, maxNumCycles, 0);
}

void waitUntilPluginIsFinished(unsigned char buffer[], unsigned int numPorts) {
    while(1) {
        unsigned int numFinished = 0;
        for (unsigned int i = 0; i < numPorts; ++i) {
            if (buffer[i] == 0x1)
               ++numFinished; 
        }

        if (numFinished == numPorts)
            break;
    }
}


