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

#include <xs1.h>
#include <assert.h>
#include <print.h>

#include "app_global.h"
#include "pwm_common.h"
#include "pwm_convert_width.h"


/** \brief Update the PWM server with three new values
 *
 *  On the next cycle through the PWM, the server will update the PWM
 *  pulse widths with these new values
 *
 *  \param ctrl the client control structure for this PWM server
 *  \param c the control channel for the PWM server
 *  \param value an array of three 24 bit values for the PWM server
 */

void update_pwm_inv( 
	chanend c_pwm, // Channel from run_motor thread
	unsigned pwm_width[], // array of pulse-widths for each phase
	unsigned motor_id, // Motor identifier
	unsigned &cur_buf,	// Indicates which current buffer in use
	unsigned &mem_addr  // Shared memory address (if used)
	);

