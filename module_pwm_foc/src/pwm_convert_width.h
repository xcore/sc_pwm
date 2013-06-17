/*
 *
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
#ifndef _PWM_CLI_COMMON__H_
#define _PWM_CLI_COMMON__H_

#include <xclib.h> // NB Contains bitrev()
#include <xccompat.h>

#include "app_global.h"
#include "pwm_common.h"
#include "pwm_client.h"

/******************************************************************************/
/** Converts PWM structure reference to address.
 * \param pwm_ps // Pointer to PWM control structure
 * \return Address
 */
unsigned long get_pwm_struct_address( // Converts PWM structure reference to address
	REFERENCE_PARAM( PWM_ARRAY_TYP ,pwm_ps ) // Pointer to PWM structure containing array of buffers
); // Return address
/*****************************************************************************/
void convert_all_pulse_widths( // Convert all PWM pulse widths to pattern/time_offset port data
	REFERENCE_PARAM( PWM_COMMS_TYP ,pwm_comms_ps), // Pointer to structure containing PWM communication data
	REFERENCE_PARAM( PWM_BUFFER_TYP ,pwm_buf_ps) // Pointer to Structure containing buffered PWM output data
);
/*****************************************************************************/
void convert_widths_in_shared_mem( // Converts PWM Pulse-width to port data in shared memory
	REFERENCE_PARAM( PWM_COMMS_TYP ,pwm_comms_ps) // Pointer to structure containing PWM communication data
);
/*****************************************************************************/

#endif /* _PWM_CLI_COMMON__H_ */
