/*
 * Copyright XMOS Limited - 2010
 */

#ifndef _PWM_H_
#define _PWM_H_

#include "xsiplugin.h"

#ifdef __cplusplus
extern "C" {
#endif

DLL_EXPORT XsiStatus pluginCreate(void **instance, XsiCallbacks *xsi, const char *arguments);
DLL_EXPORT XsiStatus pluginClock(void *instance);
DLL_EXPORT XsiStatus pluginNotify(void *instance, int type, unsigned arg1, unsigned arg2);
DLL_EXPORT XsiStatus pluginTerminate(void *instance);

#ifdef __cplusplus
}
#endif

#endif /* _PWM_H_ */
