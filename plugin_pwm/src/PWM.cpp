// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>


#include <stdio.h>
#include <string.h>
#include "PWM.h"
#include "PwmMonitor.h"
//#include "XmosSyscalls.h"

#define START_MONITORING 1000
#define STOP_MONITORING  1001
#define REPORT_STATUS    1002

#define MONITOR(x) ((PwmMonitor *)x)

static unsigned int s_numPluginInstances = 0;

XsiStatus pluginCreate(void **instance, XsiCallbacks *xsi, const char *arguments) {
	if (strcmp(arguments, "") == 0) {
		fprintf(stderr, "Error: Incorrect arguments to PWM plugin\n");
		fprintf(stderr, "Usage: xsim --plugin PWM.dll '<pad number>' test.xe\n");
		return XSI_STATUS_INVALID_ARGS;
	}

	*instance = (void *)new PwmMonitor(xsi, arguments);
	++s_numPluginInstances;
    return XSI_STATUS_OK;
}

XsiStatus pluginTerminate(void *instance) {
	delete MONITOR(instance);
    return XSI_STATUS_OK;
}

XsiStatus pluginClock(void *instance) {
	MONITOR(instance)->clock();
    return XSI_STATUS_OK;
}

XsiStatus pluginNotify(void *instance, int type, unsigned arg1, unsigned arg2) {
    switch (type) {
	case START_MONITORING:
		MONITOR(instance)->setMonitoring(true);
	    break;

    case STOP_MONITORING:
		MONITOR(instance)->setMonitoring(false);
        break;

    case REPORT_STATUS:
    	MONITOR(instance)->reportStatus();
    	break;

	default:
	    break;
	}
    return XSI_STATUS_OK;
}
