// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef _PLUGIN_H_
#define _PLUGIN_H_

void setupPluginWait(unsigned char buffer[], unsigned int maxNumCycles);
void waitUntilPluginIsFinished(unsigned char buffer[], unsigned int numPorts);

#endif
