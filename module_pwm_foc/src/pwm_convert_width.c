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
 **/

#include "pwm_convert_width.h"

/******************************************************************************/
unsigned long get_pwm_struct_address( // Converts PWM structure reference to address
	PWM_CONTROL_TYP * pwm_ps // Pointer to PWM control structure
) // Return wrapped offset
{
	return (unsigned long)pwm_ps; // Return Address
} // get_pwm_struct_address
/*****************************************************************************/
void convert_pulse_width( // convert pulse width to a 32-bit pattern and a time-offset
	PWM_PORT_TYP * rise_port_data_ps, // Pointer to port data structure (for one leg of balanced line for rising edge )
	PWM_PORT_TYP * fall_port_data_ps, // Pointer to port data structure (for one leg of balanced line for falling edge)
	unsigned inp_wid // PWM pulse-width value
)
/* The time offset is measured from a time datum (e.g. the Centre of the pulse) 
 * Therefore the earlier edge (rising edge) has a negative offset
 * and the later edge (falling edge) has a positive offset
 * The absolute time is calculated in pwm_op_inv.S, as (Time_Centre + Time_Offset)
 *
 * NB When the PWM pattern is transmiited from an XMOS 32-bit bufferred port,
 * The Least Significant Bit is the earliest in time, i.e. the LSB is sent 1st.
 */
{
	unsigned num_zeros; // No of Zero bits in 32-bit unsigned
	unsigned tmp;


	// Check for short pulse 
	if (inp_wid < 32)
	{ // Short Pulse:

		// earlier edge ( zeros transmitted 1st)
		rise_port_data_ps->time_off = -32;
		tmp = (inp_wid + 1) >> 1; // Range [0..16]
		tmp = ((1 << tmp)-1); // Range 0x0000_0000 .. 0x0000_FFFF
		rise_port_data_ps->pattern = bitrev( tmp ); // Range 0x0000_0000 .. 0xFFFF_0000

		// later edge ( zeros transmitted last): 
		// NB Need MSB to be zero, as this lasts for long low section of pulse
		fall_port_data_ps->time_off = 0;
		tmp = (inp_wid >> 1); // Range [0..15]
		fall_port_data_ps->pattern = ((1 << tmp)-1); // Range 0x0000_0000 .. 0x7FFF_0000

	} // if (inp_wid < 32)
	else
	{ // NOT a short pulse
		num_zeros = PWM_MAX_VALUE - inp_wid; // Calculate No. of 0's
	
		// Check for mid-range pulse
		if (num_zeros > 31)
		{ // Mid-range Pulse

			// earlier edge ( zeros transmitted 1st)
			rise_port_data_ps->pattern = 0xFFFF0000;
			rise_port_data_ps->time_off = -((inp_wid + 33) >> 1);
	
			// later edge ( zeros transmitted last)
			fall_port_data_ps->pattern = 0x0000FFFF;
			fall_port_data_ps->time_off = ((inp_wid - 32) >> 1);
		} // if (num_zeros > 31)
		else
		{ // Long pulse

			// earlier edge ( zeros transmitted 1st)
			// NB Need MSB to be 1, as this lasts for long high section of pulse
			rise_port_data_ps->time_off = -(PWM_MAX_VALUE >> 1);
			tmp = (num_zeros >> 1); // Range [15..0]
			tmp = ((1 << tmp)-1); // Range 0x0000_7FFF .. 0x0000_0000
			rise_port_data_ps->pattern = ~tmp; // Invert Pattern: Range 0xFFFF_8000 .. 0xFFFF_FFFF
	
			// later edge ( zeros transmitted last): 
			fall_port_data_ps->time_off = (PWM_MAX_VALUE >> 1) - 32;
			tmp = ((num_zeros + 1) >> 1); // Range [16..0]
			tmp = ((1 << tmp)-1); // Range 0x0000_FFFF .. 0x0000_0000
			tmp = ~tmp; // Invert Pattern: Range 0xFFFF_0000 .. 0xFFFF_FFFF
			fall_port_data_ps->pattern = bitrev( tmp ); // Invert Pattern: Range 0x0000_FFFF .. 0xFFFF_FFFF

		} // else !(num_zeros > 31)
	} // else !(inp_wid < 32)

	return;
} // convert_pulse_width
/*****************************************************************************/
void convert_phase_pulse_widths(  // Convert PWM pulse widths for current phase to pattern/time_offset port data
	PWM_PHASE_TYP * rise_phase_data_ps, // Pointer to PWM output data structure for rising edge of current phase
	PWM_PHASE_TYP * fall_phase_data_ps, // Pointer to PWM output data structure for falling edge of current phase
	unsigned wid_val // PWM pulse-width value
)
{
	//  WARNING: Both legs of the balanced line must NOT be switched at the same time. Therefore add dead-time to low leg.

	// Calculate PWM Pulse data for high leg (V+) of balanced line
	convert_pulse_width( &(rise_phase_data_ps->hi) ,&(fall_phase_data_ps->hi) ,wid_val );

	// NB In do_pwm_period() (pwm_service_inv.xc) ADC Sync occurs at (ref_time + HALF_DEAD_TIME)

	// Calculate PWM Pulse data for low leg (V+) of balanced line (a short time later)
	convert_pulse_width( &(rise_phase_data_ps->lo) ,&(fall_phase_data_ps->lo) ,(wid_val + PWM_DEAD_TIME) );
} // convert_phase_pulse_widths
/*****************************************************************************/
void convert_all_pulse_widths( // Convert all PWM pulse widths to pattern/time_offset port data
	PWM_BUFFER_TYP * pwm_data_ps, // Pointer to Structure containing PWM output data
	unsigned motor_id,	// Indicates which current buffer in use
	unsigned pwm_widths[] // array of PWM widths for each phase
)
{
	for (int phase_cnt = 0; phase_cnt < NUM_PWM_PHASES; phase_cnt++) 
	{
		convert_phase_pulse_widths( &(pwm_data_ps->rise_edg.phase_data[phase_cnt]) 
			,&(pwm_data_ps->fall_edg.phase_data[phase_cnt]) ,pwm_widths[phase_cnt] );
	} // for phase_cnt

	pwm_data_ps->cur_mode = D_PWM_MODE_3; // PWM mode for 3xDOUBLE (Historic)
} // convert_all_pulse_widths
/*****************************************************************************/
void convert_widths_in_shared_mem( // Converts PWM Pulse-width to port data in shared memory area
	unsigned mem_addr,  // Pointer to shared memory address (if used)
	unsigned cur_buf,	// Indicates which current buffer in use
	unsigned motor_id,	// Indicates which current buffer in use
	unsigned pwm_widths[] // array of pulse-widths for each phase
)
{	// Cast shared memory address pointer to PWM double-buffered data structure 
	PWM_CONTROL_TYP * pwm_ctrl_ps = (PWM_CONTROL_TYP *)mem_addr;

	// Convert widths and write to current PWM buffer
	convert_all_pulse_widths( &(pwm_ctrl_ps->buf_data[cur_buf]) ,motor_id ,pwm_widths );

} // convert_widths_in_shared_mem
/*****************************************************************************/
// pwm_cli_common.c
