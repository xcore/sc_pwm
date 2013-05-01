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
void foc_pwm_put_parameters( // Send PWM parameters from Client to Server
	PWM_COMMS_TYP &pwm_comms_s, // Reference to structure containing PWM communication data
	chanend c_pwm 				// Channel between Client and Server
)
{
	// Check if shared memory used to transfer data from Client to Server 
	if (1 == PWM_SHARED_MEM)
	{
		// Call 'C' interface to allow use of pointers
		convert_widths_in_shared_mem( pwm_comms_s ); // Write port data to shared memory
	} // if (1 == PWM_SHARED_MEM)

	c_pwm <: pwm_comms_s.buf; // Signal PWM server that PWM data is ready to read.
	pwm_comms_s.buf = 1 - pwm_comms_s.buf; // Toggle buffer identifier ready for next iteration

	// Check if shared memory used to transfer data from Client to Server 
	if (0 == PWM_SHARED_MEM)
	{	// NOT using shared memory model: Pass Pulse widths down channel for server to calculate port data
		c_pwm <: pwm_comms_s.params; // Send PWM parameters to Server
	} // if (0 == PWM_SHARED_MEM)

} // foc_pwm_put_data
/*****************************************************************************/
