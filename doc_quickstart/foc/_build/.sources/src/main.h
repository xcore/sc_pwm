/**
 * The copyrights, all other intellectual and industrial
 * property rights are retained by XMOS and/or its licensors.
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2013
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the
 * copyright notice above.
 **/

#ifndef _MAIN_H_
#define _MAIN_H_

#include <xs1.h>
#include <assert.h>
#include <print.h>
#include <platform.h>

#include "use_locks.h"
#include "app_global.h"
#include "pwm_server.h"
#include "capture_pwm_data.h"
#include "check_pwm_tests.h"
#include "generate_pwm_tests.h"

// Define where everything is

/** Define Interface Tile */
#define INTERFACE_TILE 0

/** Define Motor Tile */
#define MOTOR_TILE 1

#endif /* _MAIN_H_ */
