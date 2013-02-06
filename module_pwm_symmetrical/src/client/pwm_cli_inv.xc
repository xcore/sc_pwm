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

#ifdef MB
extern inline void calculate_data_out_quick( unsigned value, REFERENCE_PARAM( PWM_PHASE_TYP ,pwm_phase_data ) );


/*****************************************************************************/
void write_output_data( // MB~ Until Assembler is rewritten, need to write to memory structure maintained by assembler
	PWM_PHASE_TYP & rise_phase_data, // Reference to data structure containing current phase data (for rising edge)
	PWM_PHASE_TYP & fall_phase_data, // Reference to data structure containing current phase data (for falling edge)
	ASM_OUTDATA_TYP & asm_data // Assembler compatible output data structure
)
{
	asm_data.hi_ts0 = rise_phase_data.hi.time_off;
	asm_data.hi_out0 = rise_phase_data.hi.pattern;
	asm_data.hi_ts1 = fall_phase_data.hi.time_off;
	asm_data.hi_out1 = fall_phase_data.hi.pattern;

	asm_data.lo_ts0 = rise_phase_data.lo.time_off;
	asm_data.lo_out0 = rise_phase_data.lo.pattern;
	asm_data.lo_ts1 = fall_phase_data.lo.time_off;
	asm_data.lo_out1 = fall_phase_data.lo.pattern;

	asm_data.cat = DOUBLE;  // MB~ Redundant
	asm_data.value = 0; // MB~ Depreciated
} // write_output_data
/*****************************************************************************/
void write_pwm_data_to_mem( // MB~ Until Assembler is rewritten, need to write to memory structure maintained by assembler
	PWM_CONTROL_TYP & pwm_ctrl, // New PWM control data structure
	ASM_CONTROL_TYP & asm_ctrl // Assembler compatible PWM data structure
)
{
	int buf_cnt; // counter for double-buffer
	int phase_cnt; // counter for PWM phases


	asm_ctrl.pwm_cur_buf = pwm_ctrl.cur_buf; // transfer current buffer id

	for (buf_cnt=0; buf_cnt<NUM_PWM_BUFS; buf_cnt++)
	{ 
		asm_ctrl.mode_buf[buf_cnt] = pwm_ctrl.buf_data[buf_cnt].cur_mode; // transfer current mode

		for (phase_cnt=0; phase_cnt<NUM_PWM_PHASES; phase_cnt++)
		{
		 	// transfer phase-data
			asm_ctrl.chan_id_buf[buf_cnt][phase_cnt] = 0; // MB~ Depreciated

			write_output_data( pwm_ctrl.buf_data[buf_cnt].rise_edg.phase_data[phase_cnt] 
				,pwm_ctrl.buf_data[buf_cnt].fall_edg.phase_data[phase_cnt] ,asm_ctrl.pwm_out_data_buf[buf_cnt][phase_cnt] );
		} // for phase_cnt
	} // for buf_cnt
} // write_pwm_data_to_mem
/*****************************************************************************/
#pragma unsafe arrays
void convert_cli_pulse_widths_ref( // Convert all PWM pulse widths to pattern/time_offset port data
	PWM_BUFFER_TYP & pwm_buf_data, // Data structure for one PWM buffer
	unsigned pwm_width[] // array of PWM widths for each phase
)
{
	for (int phase_cnt = 0; phase_cnt < NUM_PWM_PHASES; phase_cnt++) 
	{
		calculate_all_data_out_ref( pwm_buf_data.rise_edg.phase_data[phase_cnt] ,pwm_buf_data.fall_edg.phase_data[phase_cnt] ,pwm_width[phase_cnt] );
	} // for phase_cnt

	pwm_buf_data.cur_mode = D_PWM_MODE_3; // PWM mode for 3xDOUBLE (Historic)
} // convert_cli_pulse_widths_ref
#endif //MB~ Depreciated
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

#ifdef USE_XSCOPE
	if (motor_id)
	{
//		xscope_probe_data(0 ,pwm_widths[0] );
	} // if (motor_id)
#endif // ifdef USE_XSCOPE

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
