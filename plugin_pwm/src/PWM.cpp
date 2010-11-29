/*
 * Copyright XMOS Limited - 2010
 */

#include <stdio.h>
#include <string.h>
#include "PWM.h"
#include "PwmMonitor.h"
//#include "XmosSyscalls.h"

#define NOTIFY_PLUGINS_START_TRACE 0
#define NOTIFY_PLUGINS_STOP_TRACE  1

#define NOTIFY_PWM_PLUGIN_DONE_ADDRESS 1000
#define NOTIFY_PWM_PLUGIN_MAX_NUM_CYCLES 1001

#define MONITOR(x) ((PwmMonitor *)x)

//using namespace std;

static unsigned int s_numPluginInstances = 0;

XsiStatus pluginCreate(void **instance, XsiCallbacks *xsi, const char *arguments) {
	if (strcmp(arguments, "") == 0) {
		fprintf(stderr, "Error: Incorrect arguments to PWM plugin\n");
		fprintf(stderr, "Usage: xsim --plugin PWM.dll '<pad number>' test.xe\n");
		return XSI_STATUS_INVALID_ARGS;
	}

	*instance = (void *)new PwmMonitor(xsi, s_numPluginInstances, arguments);
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
	case NOTIFY_PLUGINS_START_TRACE:
		MONITOR(instance)->setTracingEnabled(true);
	    break;

    case NOTIFY_PLUGINS_STOP_TRACE:
		MONITOR(instance)->setTracingEnabled(false);
        break;

    case NOTIFY_PWM_PLUGIN_DONE_ADDRESS:
    	MONITOR(instance)->setDoneAddress(arg1);
    	break;

    case NOTIFY_PWM_PLUGIN_MAX_NUM_CYCLES:
    	MONITOR(instance)->setMaxNumCycles(arg1);
    	break;

	default:
	    break;
	}
    return XSI_STATUS_OK;
}
