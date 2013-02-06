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
 */

#include <assert.h>

#include <print.h>

#ifdef __pwm_config_h_exists__
#include "pwm_config.h"
#endif
#include "pwm_cli_inv.h"

#ifdef USE_XSCOPE
#include <xscope.h>
#endif

/*****************************************************************************/
#pragma unsafe arrays
void update_pwm_inv( 
	chanend c_pwm, // Channel from run_motor thread
	unsigned pwm_widths[], // array of pulse-widths for each phase
	unsigned motor_id, // Motor identifier
	unsigned &cur_buf,	// Indicates which current buffer in use
	unsigned &mem_addr  // Reference to shared memory address (if used)
)
{
#ifdef SHARED_MEM
	// Call 'C' interface to allow use of pointers
	convert_widths_in_shared_mem( mem_addr ,cur_buf ,motor_id ,pwm_widths ); // Write port data to shared memory
#endif // ifdef SHARED_MEM

	c_pwm <: cur_buf; // Signal PWM server that PWM data is ready to read.
	cur_buf = 1 - cur_buf; // Toggle buffer identifier ready for next iteration

#ifndef SHARED_MEM 
	// If NOT using shared memory model: Pulse widths are passed down channel for server to calculate port data

	for (int phase_cnt = 0; phase_cnt < NUM_PWM_PHASES; phase_cnt++) 
	{
		c_pwm <: pwm_widths[phase_cnt]; // Send PWM pulse-width for current phase
	} // for phase_cnt
#endif // ifndef SHARED_MEM

} // update_pwm_inv 
/*****************************************************************************/
// pwm_cli_inv
