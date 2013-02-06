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

#include <xs1.h>
#include <xccompat.h>

#include "pwm_common.h"

#ifdef MB // Depreciated

/** \brief Share the control buffer address with the server
 *
 *  The PWM client and server share a common block of memory.  The client passes a reference
 *  to this block through to the server at initalization time.
 *
 *  \param c The PWM control channel
 *  \param ctrl The shared PWM control data structure reference
 */
void pwm_share_control_buffer_address_with_server(chanend c, REFERENCE_PARAM( ASM_CONTROL_TYP ,asm_ctrl) );

// Calculate required ordering of operation
void order_pwm( REFERENCE_PARAM(unsigned,mode), unsigned chan_id[], PWM_PHASE_TYP pwm_phase_data[]);

#ifdef __XC__
inline void calculate_data_out_quick( unsigned value, REFERENCE_PARAM( PWM_PHASE_TYP ,pwm_out_data ) )
{
	pwm_out_data.typ = DOUBLE;

	pwm_out_data.hi.edges[0].pattern = 0xFFFFFFFF;
	pwm_out_data.hi.edges[1].pattern = 0x7FFFFFFF;
	pwm_out_data.hi.edges[0].time_off = (value >> 1);
	pwm_out_data.hi.edges[1].time_off = (value >> 1)-31;

	pwm_out_data.lo.edges[0].pattern = 0xFFFFFFFF;
	pwm_out_data.lo.edges[1].pattern = 0x7FFFFFFF;
	pwm_out_data.lo.edges[0].time_off = ((value+PWM_DEAD_TIME) >> 1);
	pwm_out_data.lo.edges[1].time_off = ((value+PWM_DEAD_TIME) >> 1) - 31;
}
#endif
/******************************************************************************/
// Calculate timings for PWM output
void calculate_data_out( unsigned value, REFERENCE_PARAM(PWM_PHASE_TYP ,pwm_out_data) );

void calculate_data_out_ref( unsigned value,
		REFERENCE_PARAM(unsigned,ts0),
		REFERENCE_PARAM(unsigned,out0),
		REFERENCE_PARAM(unsigned,ts1),
		REFERENCE_PARAM(unsigned,out1),
		REFERENCE_PARAM(e_pwm_cat,cat));
/*****************************************************************************/
void calculate_all_data_out_ref( // Calculate all PWM Pulse data for balanced line
	REFERENCE_PARAM( PWM_PHASE_TYP ,rise_phase_data_ps), // Pointer to PWM output data structure for rising edge of current phase
	REFERENCE_PARAM( PWM_PHASE_TYP ,fall_phase_data_ps), // Pointer to PWM output data structure for falling edge of current phase
	unsigned wid_val // PWM pulse-width value
	);
/*****************************************************************************/
// Calculate required ordering of operation
void calculate_pwm_mode( REFERENCE_PARAM( PWM_CONTROL_TYP ,pwm_ctrl ) );
/*****************************************************************************/

#endif //MB~ Depreciated

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
