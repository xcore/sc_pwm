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
void foc_pwm_put_data( // Send PWM widths from Client to Server
	PWM_PARAM_TYP &pwm_param_s, // Reference to structure containing PWM parameters 
	chanend c_pwm 				// Channel between Client and Server
)
{
	// Check if shared memory used to transfer data from Client to Server 
	if (1 == PWM_SHARED_MEM)
	{
		// Call 'C' interface to allow use of pointers
		convert_widths_in_shared_mem( pwm_param_s ); // Write port data to shared memory
	} // if (1 == PWM_SHARED_MEM)

	c_pwm <: pwm_param_s.buf; // Signal PWM server that PWM data is ready to read.
	pwm_param_s.buf = 1 - pwm_param_s.buf; // Toggle buffer identifier ready for next iteration

	// Check if shared memory used to transfer data from Client to Server 
	if (0 == PWM_SHARED_MEM)
	{	// NOT using shared memory model: Pass Pulse widths down channel for server to calculate port data
		for (int phase_cnt = 0; phase_cnt < NUM_PWM_PHASES; phase_cnt++) 
		{
			c_pwm <: pwm_param_s.widths[phase_cnt]; // Send PWM pulse-width for current phase
		} // for phase_cnt
	} // if (0 == PWM_SHARED_MEM)

} // foc_pwm_put_data
/*****************************************************************************/
