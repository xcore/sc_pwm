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

//MB~ #include <xs1.h>
//MB~ #include <assert.h>
//MB~ #include <print.h>


#include "app_global.h"
#include "pwm_common.h"

// PWM specific definitions ...

// 1200ns PWM Dead-Time in ReferenceFrequency cycles (See .xn file) WARNING: Safety critical */
#define HALF_DEAD_TIME 150  // 600ns Currently configured for 250 MHz Ref-Freq (4 ns period)
#define PWM_DEAD_TIME (HALF_DEAD_TIME << 1)

// Define the resolution of PWM (affects operational freq. as tied to ref clock)
#define PWM_MAX_VALUE 4096

/******************************************************************************/
/** Converts PWM structure reference to address.
 * \param pwm_ps // Pointer to PWM control structure
 * \return Address
 */
unsigned long get_pwm_struct_address( // Converts PWM structure reference to address
	REFERENCE_PARAM( PWM_CONTROL_TYP ,pwm_ps ) // Pointer to PWM structure
); // Return address
/*****************************************************************************/
void convert_all_pulse_widths( // Convert all PWM pulse widths to pattern/time_offset port data
	REFERENCE_PARAM( PWM_BUFFER_TYP ,pwm_data_sp), // Pointer to Structure containing PWM output data
	unsigned motor_id,	// Indicates which current buffer in use
	unsigned pwm_widths[] // array of PWM widths for each phase
);
/*****************************************************************************/
void convert_widths_in_shared_mem( // Converts PWM Pulse-width to port data in shared memory
	unsigned mem_addr,  // shared memory address (if used)
	unsigned cur_buf,	// Indicates which current buffer in use
	unsigned motor_id,	// Indicates which current buffer in use
	unsigned pwm_widths[] // array of pulse-widths for each phase
);
/*****************************************************************************/

#endif /* _PWM_CLI_COMMON__H_ */
