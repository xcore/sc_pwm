/*
 * The copyrights, all other intellectual and industrial
 * property rights are retained by XMOS and/or its licensors.
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2010
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the
 * copyright notice above.
 *
 **/

#ifndef _PWM_CLIENT_H_
#define _PWM_CLIENT_H_

#include <xs1.h>
#include <assert.h>
#include <print.h>
#include <xccompat.h>

#include "app_global.h"
#include "pwm_common.h"
#include "pwm_convert_width.h"

/*****************************************************************************/
/** \brief Send PWM parameters from Client to Server
 *
 *  On the next cycle through the PWM, the server will update the PWM
 *  pulse widths with these new parameters
 *
 *  \param pwm_comms_s  Reference to structure containing PWM communication data
 *  \param c_pwm  Channel between Client and Server
 */
void foc_pwm_put_parameters( // Send PWM parameters from Client to Server
	REFERENCE_PARAM( PWM_COMMS_TYP ,pwm_data_sp ), // Reference/Pointer to structure containing PWM communication data
	chanend c_pwm 				// Channel between Client and Server
);
/*****************************************************************************/

#endif // _PWM_CLIENT_H_
