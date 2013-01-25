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

#include <assert.h>
#include <print.h>

#include "pwm_cli_common.h"
#include "pwm_common.h"

/******************************************************************************/
unsigned long get_struct_address( // Converts structure reference to address
	ASM_CONTROL_TYP * ctrl_ps // Pointer to PWM control structure
) // Return wrapped offset
{
	return (unsigned long)ctrl_ps; // Return Address
} // get_struct_address

#ifdef MB // Depreciated
/*****************************************************************************/
void pwm_share_control_buffer_address_with_server(
	chanend c, 
	ASM_CONTROL_TYP * asm_ctrl
)
{
  __asm__ volatile ("outct  res[%0], 0x1;"
	  "chkct  res[%0], 0x1;"
	  "out    res[%0], %1;"
	  "outct  res[%0], 0x1;"
	  "chkct  res[%0], 0x1;"  :: "r"(c),"r"(asm_ctrl));
  return;
} // pwm_share_control_buffer_address_with_server
/*****************************************************************************/
void order_pwm(  // Used by INV and NOINV modes
	unsigned * mode, 
	unsigned * chan_id, 
	PWM_OUTDATA_TYP * pwm_out_data
)
{
	unsigned chan_id_tmp;
#ifndef PWM_CLIPPED_RANGE
	unsigned sngle = 0, long_single = 0, dble = 0;
	int e_check = 0;

	for (int i = 0; i < NUM_PWM_PHASES; i++) {
		switch(pwm_out_data[i].typ) {
		case SINGLE:
			sngle++;
			break;
		case DOUBLE:
			dble++;
			break;
		case LONG_SINGLE:
			long_single++;
			break;
		}
	}

	if (sngle == 3) {
		*mode = 1;
		return;
	}

	else if (long_single == 1 && sngle == 2) {
		*mode = 7;
		/* need to find the long single and put it first */
		for (int i = 0; i < NUM_PWM_PHASES; i++)
		{
			if (pwm_out_data[i].typ == LONG_SINGLE)
			{
				chan_id_tmp = chan_id[0];
				chan_id[0] = chan_id[i];
				chan_id[i] = chan_id_tmp;
				return;
			}
		}
		e_check = 1;
		asm("ecallt %0" : "=r"(e_check));
	}

	else if (dble == 1 && sngle == 2) {
		*mode = 2;
		/* need to find the double and put it first */
		for (int i = 1; i < NUM_PWM_PHASES; i++)
		{
			if (pwm_out_data[i].typ == DOUBLE )
			{
				chan_id_tmp = chan_id[0];
				chan_id[0] = chan_id[i];
				chan_id[i] = chan_id_tmp;
				return;
			}
		}
		e_check = 1;
		asm("ecallt %0" : "=r"(e_check));
	}

	else if (dble == 2 && sngle == 1) {
		*mode = 3;

		/* need to find the single and put it last */
		for (int i = 0; i < NUM_PWM_PHASES; i++)
		{
			if (pwm_out_data[i].typ == SINGLE )
			{
				chan_id_tmp = chan_id[NUM_PWM_PHASES-1];
				chan_id[NUM_PWM_PHASES-1] = chan_id[i];
				chan_id[i] = chan_id_tmp;
				break;
			}
		}

		/* now order by length, only go as far as last but one - it is already in the right place */
		for (int i = 0; i < NUM_PWM_PHASES-2; i++) /* start point loop */
		{
			unsigned max_index = i;
			for (int j = i+1; j < NUM_PWM_PHASES-1; j++)
			{
				if (pwm_out_data[j].width > pwm_out_data[max_index].width)
					max_index = j;
			}

			/* swap into the correct place */
			chan_id_tmp = chan_id[i];
			chan_id[i] = chan_id[max_index];
			chan_id[max_index] = chan_id_tmp;
		}
		return;
	}

	else if (dble == 3) {
#endif
		*mode = 4;

#if NUM_PWM_PHASES==3
		if (pwm_out_data[0].width > pwm_out_data[1].width) {
			chan_id_tmp = chan_id[0];
			chan_id[0] = chan_id[1];
			chan_id[1] = chan_id_tmp;
		}
		if (pwm_out_data[1].width > pwm_out_data[2].width) {
			chan_id_tmp = chan_id[1];
			chan_id[1] = chan_id[2];
			chan_id[2] = chan_id_tmp;
		}
		return;
#else
		/* now order by length*/
		for (int i = 0; i < NUM_PWM_PHASES-1; i++) /* start point loop */
		{
			unsigned max_index = i;
			for (int j = i+1; j < NUM_PWM_PHASES; j++)
			{
				if (pwm_out_data[j].width > pwm_out_data[max_index].width)
					max_index = j;
			}

			/* swap, even if it is a swap in place */
			chan_id_tmp = chan_id[i];
			chan_id[i] = chan_id[max_index];
			chan_id[max_index] = chan_id_tmp;
		}
		return;
#endif
#ifndef PWM_CLIPPED_RANGE
	}

	else if (long_single == 1 && dble == 1 && sngle == 1) {
		*mode = 5;

		/* need to find the single and put it last */
		for (int i = 0; i < NUM_PWM_PHASES; i++)
		{
			if (pwm_out_data[i].typ == SINGLE) {
				chan_id_tmp = chan_id[NUM_PWM_PHASES-1];
				chan_id[NUM_PWM_PHASES-1] = chan_id[i];
				chan_id[i] = chan_id_tmp;
				break;
			}
		}

		/* need to find the double and put it in the middle */
		for (int i = 0; i < NUM_PWM_PHASES; i++)
		{
			if (pwm_out_data[i].typ == DOUBLE) {
				chan_id_tmp = chan_id[1];
				chan_id[1] = chan_id[i];
				chan_id[i] = chan_id_tmp;
				break;
			}
		}

		/* long single should be first by definition */
		e_check = (pwm_out_data[0].typ != LONG_SINGLE);
		asm("ecallt %0" : "=r"(e_check));

		return;
	}

	else if (long_single == 1 && dble == 2) {
		*mode = 6;

		/* need to find the long single and put it first */
		for (int i = 0; i < NUM_PWM_PHASES; i++) {
			if (pwm_out_data[i].typ == LONG_SINGLE) {
				chan_id_tmp = chan_id[0];
				chan_id[0] = chan_id[i];
				chan_id[i] = chan_id_tmp;
				break;
			}
		}

		/* need to find the double and put it in the middle */
		for (int i = 0; i < NUM_PWM_PHASES; i++) {
			if (pwm_out_data[i].typ == DOUBLE) {
				chan_id_tmp = chan_id[1];
				chan_id[1] = chan_id[i];
				chan_id[i] = chan_id_tmp;
				break;
			}
		}

		/* long single should be first by definition */
		e_check = (pwm_out_data[0].typ != LONG_SINGLE);
		asm("ecallt %0" : "=r"(e_check));

		return;
	}
#endif
} // order_pwm 
/*****************************************************************************/
void calculate_data_out( 
	unsigned value, 
	PWM_OUTDATA_TYP * outdata_ps 
)
{
	outdata_ps->hi.edges[1].pattern = 0;
	outdata_ps->hi.edges[1].time = 0;
	outdata_ps->lo.edges[1].pattern = 0;
	outdata_ps->lo.edges[1].time = 0;

	// very low values
	if (value <= 31)
	{
		outdata_ps->typ = SINGLE;
		/* outdata_ps..pattern = ((1 << value)-1);  */
		asm("mkmsk %0, %1" : "=r"(outdata_ps->hi.edges[0].pattern) : "r"(value));		// compiler work around, bug 8218

		outdata_ps->hi.edges[0].pattern <<= (value >> 1); // move it to the middle
		outdata_ps->hi.edges[0].time = 16;
		return;
	}

	// close to PWM_MAX_VALUE
	else if (value >= (PWM_MAX_VALUE-31))
	{
		unsigned tmp;
		outdata_ps->typ = LONG_SINGLE;
		tmp = PWM_MAX_VALUE - value; // number of 0's
		tmp = 32 - tmp; // number of 1's

		/* outdata_ps..pattern = ((1 << value)-1);  */
		asm("mkmsk %0, %1" : "=r"(outdata_ps->hi.edges[0].pattern) : "r"(tmp) );		// compiler work around, bug 8218

		outdata_ps->hi.edges[0].pattern <<= (32 - tmp);
		outdata_ps->hi.edges[0].time = (PWM_MAX_VALUE >> 1) + ((PWM_MAX_VALUE - value) >> 1); // MAX + (num 0's / 2)
		return;
	}

	// low mid range
	else if (value < 64)
	{
		unsigned tmp;
		outdata_ps->typ = DOUBLE;

		if (value == 63)
			tmp = 32;
		else
			tmp = value >> 1;

		/* outdata_ps..pattern = ((1 << (value >> 1))-1);  */
		asm("mkmsk %0, %1" : "=r"(outdata_ps->hi.edges[0].pattern) : "r"(tmp) );		// compiler work around, bug 8218

		tmp = value - tmp;

		/* outdata_ps..pattern = ((1 << (value - (value >> 1)))-1);  */
		asm("mkmsk %0, %1" : "=r"(outdata_ps->hi.edges[1].pattern) : "r"(tmp) );		// compiler work around, bug 8218

		outdata_ps->hi.edges[0].time = 32;
		outdata_ps->hi.edges[1].time = 0;
		return;
	}

	// midrange
	outdata_ps->typ = DOUBLE;
	outdata_ps->hi.edges[0].pattern = 0xFFFFFFFF;
	outdata_ps->hi.edges[1].pattern = 0x7FFFFFFF;

	outdata_ps->hi.edges[0].time = (value >> 1);
	outdata_ps->hi.edges[1].time = (value >> 1)-31;
} // calculate_data_out 

#endif //MB~ Depreciated
/*****************************************************************************/
void calculate_data_out_ref( 
	unsigned value, 
	unsigned * ts0, 
	unsigned * out0, 
	unsigned * ts1, 
	unsigned * out1, 
	e_pwm_cat * cat 
)
{
	*out1 = 0;
	*ts1 = 0;

	// very low values
	if (value < 32)
	{
		*cat = SINGLE;
		// compiler work around, bug 8218
		/* pwm_out_data.out0 = ((1 << value)-1);  */
		asm("mkmsk %0, %1"
				: "=r"(*out0)
				: "r"(value));
		*out0 <<= 16-(value >> 1); // move it to the middle
		*ts0 = 16;

		/* DOUBLE mode safe values */
		*out1 = 0;
		*ts1 = 100;

		return;
	}

	// close to PWM_MAX_VALUE
	/* Its pretty impossible to apply dead time to values this high... so update function should clamp the values to
	 * PWM_MAX - (31+PWM_DEAD_TIME)
	 */
	else if (value >= (PWM_MAX_VALUE-31))
	{
		unsigned tmp;
		*cat = LONG_SINGLE;
		tmp = PWM_MAX_VALUE - value; // number of 0's
		tmp = 32 - tmp; // number of 1's

		// compiler work around, bug 8218
		/* pwm_out_data.out0 = ((1 << value)-1);  */
		asm("mkmsk %0, %1"
				: "=r"(*out0)
		  	    : "r"(tmp));

		*out0 <<= (32 - tmp);
		*ts0 = (PWM_MAX_VALUE >> 1) + ((PWM_MAX_VALUE - value) >> 1); // MAX + (num 0's / 2)
		return;
	}

	// low mid range
	else if (value < 64)
	{
		unsigned tmp;
		*cat = DOUBLE;

		if (value == 63)
			tmp = 32;
		else
			tmp = value >> 1;

		// compiler work around, bug 8218
		/* pwm_out_data.out0 = ((1 << (value >> 1))-1);  */
		asm("mkmsk %0, %1"
				: "=r"(*out0)
				: "r"(tmp));

		/* pwm_out_data.out1 = ((1 << (value - (value >> 1)))-1);  */
		// compiler work around, bug 8218
		tmp = value - tmp;
		asm("mkmsk %0, %1"
				: "=r"(*out1)
				: "r"(tmp));

		*ts0 = 32;
		*ts1 = 0;
		return;
	}
	// midrange
	*cat = DOUBLE;
	*out0 = 0xFFFFFFFF;
	*out1 = 0x7FFFFFFF;

	*ts0 = (value >> 1);
	*ts1 = (value >> 1)-31;

} // calculate_data_out_ref
/*****************************************************************************/
void calculate_leg_data_out_ref( 
	PWM_PULSE_TYP * pulsedata_ps, // Pointer to PWM pulse data structure (for one leg of balanced line)
	e_pwm_cat * typ_p, // Pointer to type of pulse to generate
	unsigned inp_wid // PWM pulse-width value
)
{
	unsigned num_zeros; // No of Zero bits in 32-bit unsigned
	unsigned num_ones; // No of One bits in 32-bit unsigned
	unsigned tmp;


	// very low values
	if (inp_wid < 32)
	{
		*typ_p = SINGLE;
		pulsedata_ps->edges[0].pattern = ((1 << inp_wid)-1);
		pulsedata_ps->edges[0].pattern <<= 16 - (inp_wid >> 1); // move it to the middle
		pulsedata_ps->edges[0].time = 16;

		/* DOUBLE mode safe inp_wids */
		pulsedata_ps->edges[1].pattern = 0;
		pulsedata_ps->edges[1].time = 100;

		return;
	} // if (inp_wid < 32)

	// close to PWM_MAX_VALUE
	/* Its pretty impossible to apply dead time to values this high... so update function should clamp the values to
	 * PWM_MAX - (31+PWM_DEAD_TIME)
	 */

	num_zeros = PWM_MAX_VALUE - inp_wid; // No. of 0's
	if (num_zeros < 32)
	{
		*typ_p = LONG_SINGLE;
		num_ones = 32 - num_zeros; // number of 1's

		pulsedata_ps->edges[0].pattern = ((1 << num_ones) - 1); // Generate mask with required 1's in LSB's
		pulsedata_ps->edges[0].pattern <<= num_zeros;           // Move required 1's to MSB's
		pulsedata_ps->edges[0].time = (PWM_MAX_VALUE >> 1) + (num_zeros >> 1); // MAX + (num 0's / 2)

		pulsedata_ps->edges[1].pattern = 0;
		pulsedata_ps->edges[1].time = 0;

		return;
	}	// if (inp_wid >= (PWM_MAX_VALUE-31))

	// low mid range
	if (inp_wid < 64)
	{
		*typ_p = DOUBLE;

		if (inp_wid == 63)
		{
			tmp = 32;
		} // if (inp_wid == 63)
		else
		{
			tmp = inp_wid >> 1;
		} // else !(inp_wid == 63)

		pulsedata_ps->edges[0].pattern = ((1 << tmp)-1);
		pulsedata_ps->edges[0].time = 32;

		tmp = inp_wid - tmp;
		pulsedata_ps->edges[1].pattern = ((1 << tmp)-1);
		pulsedata_ps->edges[1].time = 0;

		return;
	} // if (inp_wid < 64)

	// Default: midrange

	*typ_p = DOUBLE;
	pulsedata_ps->edges[0].pattern = 0xFFFFFFFF;
	pulsedata_ps->edges[0].time = (inp_wid >> 1);

	pulsedata_ps->edges[1].pattern = 0x7FFFFFFF;
	pulsedata_ps->edges[1].time = (inp_wid >> 1) - 31;

} // calculate_leg_data_out_ref
/*****************************************************************************/
void calculate_all_data_out_ref( // Calculate all PWM Pulse data for balanced line
	PWM_OUTDATA_TYP * outdata_ps, // Pointer to PWM output data structure
	unsigned value, // PWM pulse-width value
	unsigned dead_time // PWM dead-time
)
{
	//  WARNING: Both legs of the balanced line must NOT be switched at the same time. Therefore add dead-time to low leg.

	// Calculate PWM Pulse data for high leg (V+) of balanced line
	calculate_leg_data_out_ref( &(outdata_ps->hi) ,&(outdata_ps->typ) ,value );

//WARNING: At present hi-leg 'cat' value is overwritten by lo-leg 'cat' value. MB~

	// Calculate PWM Pulse data for low leg (V+) of balanced line (a short time later)
	calculate_leg_data_out_ref( &(outdata_ps->lo) ,&(outdata_ps->typ) ,(value + dead_time) );
} // calculate_all_data_out_ref
/*****************************************************************************/
void swap_phase_ids( // swap ids of 2 PWM phases
	PWM_PHASE_TYP * phase_p, // Pointer to array of phase data strutures
	int phase_a, // 1st Phase of swap-pair 
	int phase_b // 2nd Phase of swap-pair 
)
{
	unsigned tmp_id;


assert( 0 == 1 ); // MB~ Test Me!
/* Historically this routine was never exercised. If it ever becomes active it needs testing, 
 * and converting to 'Exclusive OR' method 
 */

	tmp_id = phase_p[phase_a].ord_id;
	phase_p[phase_a].ord_id = phase_p[phase_b].ord_id;
	phase_p[phase_b].ord_id = tmp_id;
} // swap_phase_ids 
/*****************************************************************************/
void order_common_mode( // Order common mode
	PWM_BUFFER_TYP * pwm_buf_data_ps, // Pointer to structure containing PWM buffer-data
	PWM_PHASE_TYP * phase_p // Pointer to array of phase data strutures
)
{
	if (phase_p[0].out_data.width > phase_p[1].out_data.width) 
	{
		swap_phase_ids( phase_p ,0 ,1 ); // Swap id's for phase 0 and 1
	} //if (phase_p[0].out_data.width > phase_p[1].out_data.width) 

	if (phase_p[1].out_data.width > phase_p[2].out_data.width) 
	{
		swap_phase_ids( phase_p ,1 ,2 );  // Swap id's for phase 1 and 2
	} // if (phase_p[1].out_data.width > phase_p[2].out_data.width) 

} // order_common_mode
/*****************************************************************************/
void order_new_pwm(  // Used by INV and NOINV modes
	PWM_CONTROL_TYP * pwm_ctrl_ps // Pointer to structure of PWM control data
)
{
	PWM_BUFFER_TYP * pwm_buf_data_ps = &(pwm_ctrl_ps->buf_data[pwm_ctrl_ps->cur_buf]); // Local pointer to current buffer data
	PWM_PHASE_TYP * phase_p = &(pwm_buf_data_ps->phase_data[0]); // Local pointer to array of phase data strutures


	assert( NUM_PWM_PHASES == 3 ); // ERROR: Only 3-phase PWM supported

#ifndef PWM_CLIPPED_RANGE
	int phase_cnt; // PWM phase counter
	unsigned long_off = 4; // Offset for LONG_SINGLE when calculating PWM mode


/* The PWM mode is assigned as follows:-
 *	where S = SINGLE, D = DOUBLE, L = LONG_SINGLE
 *	The possible combinations form a triangle as shown below
 *										      3L = 9
 *					      2L+S = 7         2L+D = 8
 *	      L+2S = 4        L+D+S = 5        L+2D = 6
 *	3S = 0        D+2S = 1         2D+S = 2        3D = 3
 *
 *WARNING: Any assignment changes must be reflected in 'D_PWM_MODE' definitions in pwm_common.h
 */
	pwm_buf_data_ps->cur_mode = 0; // Reset PWM mode to 3xSINGLE

	// Loop through all phases and build PWM mode identifier
	for (phase_cnt = 0; phase_cnt < NUM_PWM_PHASES; phase_cnt++) 
	{
		switch( phase_p[phase_cnt].out_data.typ ) 
		{
			case SINGLE:
				// No action required
			break;

			case DOUBLE:
				pwm_buf_data_ps->cur_mode++; // Update PWM mode for one more DOUBLE
			break;

			case LONG_SINGLE:
				pwm_buf_data_ps->cur_mode += long_off; // Update PWM mode for one more LONG_SINGLE
				long_off--; // Decrement LONG_SINGLE offset as move up combinations triangle
			break;

			default:
				assert( 0 == 1 ); // ERROR: Unsupported PWM Pulse type
			break;
		} // switch( phase_p[phase_cnt].out_data.typ ) 
	}	// for phase_cnt

//MB~ When pwm_op_inv rewritten, the pwm_buf_data_ps->cur_mode will be equivalent to the mode_id 
	// Order pulse-data according to PWM mode
	switch( pwm_buf_data_ps->cur_mode )
	{
		case D_PWM_MODE_3: // 3xDOUBLE (Most common mode)
			order_common_mode( pwm_buf_data_ps ,phase_p );
		break; // case 3

		case D_PWM_MODE_0: // 3xSINGLE
			// Nothing to do
		break; // case D_PWM_MODE_0

		case D_PWM_MODE_1: // 2xSINGLE + DOUBLE
			/* need to find the double and put it first */
			for (phase_cnt = 1; phase_cnt < NUM_PWM_PHASES; phase_cnt++)
			{
				if (phase_p[phase_cnt].out_data.typ == DOUBLE )
				{
					swap_phase_ids( phase_p ,0 ,phase_cnt ); // Swap id's for phase 0 and phase_cnt

					break;
				} // if (phase_p[phase_cnt].out_data.typ == DOUBLE )
			} // for phase_cnt
		break; // case D_PWM_MODE_1

		case D_PWM_MODE_2: // SINGLE + 2xDOUBLE
			/* need to find the single and put it last */
			for (phase_cnt = 0; phase_cnt < (NUM_PWM_PHASES - 1); phase_cnt++)
			{
				if (phase_p[phase_cnt].out_data.typ == SINGLE )
				{
					swap_phase_ids( phase_p ,phase_cnt ,(NUM_PWM_PHASES - 1) ); // Swap id's for phase phase_cnt and (NUM_PWM_PHASES - 1)
	
					break;
				} // if (phase_p[phase_cnt].out_data.typ == SINGLE )
			} // for phase_cnt
	
			/* now order 2 doubles with largest length 1st */
			if (phase_p[1].out_data.width > phase_p[0].out_data.width)
			{
				swap_phase_ids( phase_p ,0 ,1 ); // Swap id's for phase 0 and 1
			} // if (phase_p[1].out_data.width > phase_p[0].out_data.width)
		break; // case D_PWM_MODE_2 
	
		case D_PWM_MODE_4: // 2xSINGLE + LONG_SINGLE
			/* need to find the long single and put it first */
			for (phase_cnt = 1; phase_cnt < NUM_PWM_PHASES; phase_cnt++)
			{
				if (phase_p[phase_cnt].out_data.typ == LONG_SINGLE)
				{
					swap_phase_ids( phase_p ,0 ,phase_cnt ); // Swap id's for phase 0 and phase_cnt
				} // if (phase_p[phase_cnt].out_data.typ == LONG_SINGLE)

				break;
			} // for phase_cnt
		break;  // case D_PWM_MODE_4

		case D_PWM_MODE_5: // SINGLE + DOUBLE + LONG_SINGLE
			/* need to find the single and put it last */
			for (phase_cnt = 0; phase_cnt < (NUM_PWM_PHASES - 1); phase_cnt++)
			{
				if (phase_p[phase_cnt].out_data.typ == SINGLE) 
				{
					swap_phase_ids( phase_p ,phase_cnt ,(NUM_PWM_PHASES - 1) ); // Swap id's for phase phase_cnt and (NUM_PWM_PHASES - 1)
	
					break;
				} // if (phase_p[phase_cnt].out_data.typ == SINGLE) {
			} // for (phase_cnt = 0; phase_cnt < NUM_PWM_PHASES; phase_cnt++)
	
			/* need to put the long-single first */
			if (phase_p[1].out_data.typ == LONG_SINGLE ) 
			{
				swap_phase_ids( phase_p ,0 ,1 ); // Swap id's for phase 0 and 1
			} // if (phase_p[phase_cnt].out_data.typ == DOUBLE) 
		break;  // case D_PWM_MODE_5

		case D_PWM_MODE_6: // 2xDOUBLE + LONG_SINGLE
			/* need to find the long single and put it first */
			for (phase_cnt = 1; phase_cnt < NUM_PWM_PHASES; phase_cnt++) 
			{
				if (phase_p[phase_cnt].out_data.typ == LONG_SINGLE) 
				{
					swap_phase_ids( phase_p ,0 ,phase_cnt ); // Swap id's for phase 0 and phase_cnt
	
					break;
				} // if (phase_p[phase_cnt].out_data.typ == LONG_SINGLE) 
			} // for phase_cnt
	
			/* put the smallest double last */
			if (phase_p[1].out_data.width < phase_p[NUM_PWM_PHASES - 1].out_data.width)
			{
				swap_phase_ids( phase_p ,1 ,(NUM_PWM_PHASES - 1) ); // Swap id's for phase 1 and last
			} // if (phase_p[1].out_data.width < phase_p[NUM_PWM_PHASES - 1].out_data.width)
		break;  // case D_PWM_MODE_6

		case D_PWM_MODE_7: // SINGLE + 2xLONG_SINGLE
			assert( 0 == 1 ); // ERROR: D_PWM_MODE_7 is unsupported Mode-Sum
		break;  // case D_PWM_MODE_7

		case D_PWM_MODE_8: // DOUBLE + 2xLONG_SINGLE
			assert( 0 == 1); // ERROR: D_PWM_MODE_8 is unsupported Mode-Sum
		break;  // case D_PWM_MODE_8

		case D_PWM_MODE_9: // 3xLONG_SINGLE
			assert( 0 == 1); // ERROR: D_PWM_MODE_9 is unsupported Mode-Sum
		break;  // case D_PWM_MODE_9

		default:
			assert( 0 == 1 ); // ERROR: Unreachable Code!
		break; // default
	} // switch( pwm_buf_data_ps->cur_mode )

#else // #ifndef PWM_CLIPPED_RANGE

	order_common_mode( pwm_buf_data_ps ,phase_p ); // Just do common_mode

#endif //  else #ifdef PWM_CLIPPED_RANGE

} // order_new_pwm 
/*****************************************************************************/
// pwm_cli_common.c
