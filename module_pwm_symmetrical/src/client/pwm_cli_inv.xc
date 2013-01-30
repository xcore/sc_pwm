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

extern inline void calculate_data_out_quick( unsigned value, REFERENCE_PARAM( PWM_OUTDATA_TYP ,pwm_out_data ) );

/*****************************************************************************/
void write_output_data( // MB~ Until Assembler is rewritten, need to write to memory structure maintained by assembler
	PWM_OUTDATA_TYP & pwm_data, // New PWM output data structure
	ASM_OUTDATA_TYP & asm_data // Assembler compatible output data structure
)
{
	asm_data.hi_ts0 = pwm_data.hi.edges[0].time;
	asm_data.hi_out0 = pwm_data.hi.edges[0].pattern;
	asm_data.hi_ts1 = pwm_data.hi.edges[1].time;
	asm_data.hi_out1 = pwm_data.hi.edges[1].pattern;

	asm_data.lo_ts0 = pwm_data.lo.edges[0].time;
	asm_data.lo_out0 = pwm_data.lo.edges[0].pattern;
	asm_data.lo_ts1 = pwm_data.lo.edges[1].time;
	asm_data.lo_out1 = pwm_data.lo.edges[1].pattern;

	asm_data.cat = pwm_data.typ;
	asm_data.value = pwm_data.width;
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
			asm_ctrl.chan_id_buf[buf_cnt][phase_cnt] = pwm_ctrl.buf_data[buf_cnt].phase_data[phase_cnt].ord_id;

			write_output_data( pwm_ctrl.buf_data[buf_cnt].phase_data[phase_cnt].out_data ,asm_ctrl.pwm_out_data_buf[buf_cnt][phase_cnt] );
		} // for phase_cnt
	} // for buf_cnt
} // write_pwm_data_to_mem
/*****************************************************************************/
#pragma unsafe arrays
void update_pwm_inv( 
	ASM_CONTROL_TYP & asm_ctrl, 
	PWM_CONTROL_TYP & pwm_ctrl,
	int xscope[],
	chanend c_pwm, 
	unsigned pwm_width[]
)
{
//MB~Depreciated	unsigned minus_one = 1; // NB remains set if all PWM values are -1


 	pwm_ctrl.cur_buf = 1 - pwm_ctrl.cur_buf; // Toggle double-buffer ready for next calculation

	/* calculate the required outputs */
#pragma loop unroll
	for (int phase_cnt = 0; phase_cnt < NUM_PWM_PHASES; phase_cnt++) 
	{
		pwm_ctrl.buf_data[pwm_ctrl.cur_buf].phase_data[phase_cnt].ord_id = phase_cnt; // Reset default phase order

#ifdef PWM_CLIPPED_RANGE
		calculate_data_out_quick( pwm_width[phase_cnt] ,pwm_ctrl.buf_data[pwm_ctrl.cur_buf].phase_data[phase_cnt].out_data );
#else
		/* clamp to avoid issues with LONG_SINGLE */
		if (pwm_width[phase_cnt] > PWM_LIM_VALUE) 
		{
			assert( 0 == 1); // MB~ Dbg: Don't think this happens any more
			pwm_width[phase_cnt] = PWM_LIM_VALUE;
		} // if (pwm_width[phase_cnt] > PWM_LIM_VALUE)

		calculate_all_data_out_ref( pwm_ctrl.buf_data[pwm_ctrl.cur_buf].phase_data[phase_cnt].out_data 
			,pwm_width[phase_cnt] ,PWM_DEAD_TIME );
#endif

//MB~Depreciated		if (pwm_width[phase_cnt] != -1) minus_one = 0; // Clear minus_one flag
	} // for phase_cnt

	calculate_pwm_mode( pwm_ctrl );		// now order them and work out the mode

#ifdef MB // Depreciated
	// Check if minus_one flag still set. //MB~ Not sure what this is doing yet.
	if (minus_one)
	{
		pwm_ctrl.buf_data[pwm_ctrl.cur_buf].cur_mode = -1;
	} // if (minus_one)
	else 
	{
		calculate_pwm_mode( pwm_ctrl ); // now order them and work out the mode
	} // else !(minus_one)
#endif //MB~ Depreciated

	write_pwm_data_to_mem( pwm_ctrl ,asm_ctrl ); // Write PWM data to shared memory (read by assembler)
{ //MB~ Dbg
	xscope[0] = asm_ctrl.pwm_out_data_buf[pwm_ctrl.cur_buf][0].hi_ts0;
	xscope[1] = asm_ctrl.pwm_out_data_buf[pwm_ctrl.cur_buf][0].lo_ts0;
	xscope[2] = asm_ctrl.pwm_out_data_buf[pwm_ctrl.cur_buf][0].hi_ts1;
	xscope[3] = asm_ctrl.pwm_out_data_buf[pwm_ctrl.cur_buf][0].lo_ts1;
} //MB~ Dbg

	c_pwm <: pwm_ctrl.cur_buf; // Signal PWM server that PWM data is ready to read
} // update_pwm_inv 
/*****************************************************************************/
// pwm_cli_inv
