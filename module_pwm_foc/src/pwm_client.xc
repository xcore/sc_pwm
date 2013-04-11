/*
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
 */

#include "pwm_client.h"

/*****************************************************************************/
void update_pwm_inv( 
	chanend c_pwm, // Channel from run_motor thread
	unsigned pwm_widths[], // array of pulse-widths for each phase
	unsigned motor_id, // Motor identifier
	unsigned &cur_buf,	// Indicates which current buffer in use
	unsigned &mem_addr  // Reference to shared memory address (if used)
)
{
	// Check if shared memory used to transfer data from Client to Server 
	if (1 == PWM_SHARED_MEM)
	{
		// Call 'C' interface to allow use of pointers
		convert_widths_in_shared_mem( mem_addr ,cur_buf ,motor_id ,pwm_widths ); // Write port data to shared memory
	} // if (1 == PWM_SHARED_MEM)

	c_pwm <: cur_buf; // Signal PWM server that PWM data is ready to read.
	cur_buf = 1 - cur_buf; // Toggle buffer identifier ready for next iteration

	// Check if shared memory used to transfer data from Client to Server 
	if (0 == PWM_SHARED_MEM)
	{	// NOT using shared memory model: Pass Pulse widths down channel for server to calculate port data
		for (int phase_cnt = 0; phase_cnt < NUM_PWM_PHASES; phase_cnt++) 
		{
			c_pwm <: pwm_widths[phase_cnt]; // Send PWM pulse-width for current phase
		} // for phase_cnt
	} // if (0 == PWM_SHARED_MEM)

} // update_pwm_inv 
/*****************************************************************************/
