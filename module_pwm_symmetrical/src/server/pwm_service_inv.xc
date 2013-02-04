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
 **/                                   

#include <assert.h>

#include <xs1.h>
#include <print.h>

#ifdef __pwm_config_h_exists__
#include "pwm_config.h"
#endif

#include "pwm_service_inv.h"

extern unsigned pwm_op_inv( 
	unsigned buf_id, 
	buffered out port:32 p32_pwm_hi[], 
	buffered out port:32 p32_pwm_lo[], 
	chanend c_pwm, 
	unsigned control, 
	chanend? c_trig, 
	in port? p16_adc_sync 
);

/*****************************************************************************/
static void do_pwm_port_config( 
	buffered out port:32 p32_pwm_hi[], 
	buffered out port:32 p32_pwm_lo[], 
	in port? p16_adc_sync, 
	clock pwm_clk 
)
{
	unsigned i;

	for (i = 0; i < NUM_PWM_PHASES; i++)
	{
		configure_out_port( p32_pwm_hi[i] ,pwm_clk ,0 ); // Set initial value of port to 0 (Switched Off) 
		configure_out_port( p32_pwm_lo[i] ,pwm_clk ,0 ); // Set initial value of port to 0 (Switched Off)  
		set_port_inv( p32_pwm_lo[i] );
	}

#if LOCK_ADC_TO_PWM
	configure_in_port( p16_adc_sync ,pwm_clk );	// Dummy port used to send ADC synchronisation pulse
#endif  // #if LOCK_ADC_TO_PWM

	start_clock( pwm_clk );
} // do_pwm_port_config_inv_adc_trig
#ifdef MB
/*****************************************************************************/
void do_pwm_inv_triggered( 
	chanend c_pwm, 
	buffered out port:32 p32_pwm_hi[], 
	buffered out port:32 p32_pwm_lo[], 
	chanend? c_adc_trig, 
	in port? p16_adc_sync, 
	clock pwm_clk
)
{
	unsigned buf_id; // Double-buffer identifier [0,1]
	unsigned mem_addr; // Shared memory address


	c_pwm :> mem_addr;	// First read the shared memory buffer address from the client

	do_pwm_port_config( p32_pwm_hi ,p32_pwm_lo ,p16_adc_sync ,pwm_clk ); // configure the ports

	c_pwm :> buf_id; // Wait for initial buffer id

	// Loop forever
	while (1)
	{
#if LOCK_ADC_TO_PWM
		buf_id = pwm_op_inv( buf_id, p32_pwm_hi, p32_pwm_lo, c_pwm, mem_addr, c_adc_trig, p16_adc_sync ); // Never exits
#else //if LOCK_ADC_TO_PWM
		buf_id = pwm_op_inv( buf_id ,p32_pwm_hi ,p32_pwm_lo ,c_pwm ,mem_addr ,null ,null ); // Never Exits
#endif  //else !LOCK_ADC_TO_PWM
		assert( 0 == 1); // ERROR: Unreachable code
	} // while(1)

} // do_pwm_inv_triggered 
#endif //MB~
/*****************************************************************************/
void load_pwm_edge_onto_port( // Load one set of edge data for current port
	PWM_EDGE_TYP &edge_data_s, // Reference to structure containing PWM output data for current edge
	buffered out port:32 p32_pwm_leg, // 32-bit buffered output port for current leg
	unsigned ref_time // Reference time-stamp
)
{
	// Calculate absolute time to load pattern on port
	p32_pwm_leg @ (ref_time + edge_data_s.time_off) <: edge_data_s.pattern;
} // load_pwm_edge_onto_port
/*****************************************************************************/
void load_pwm_phase( // Load all data ports for current phase/edge
	PWM_PHASE_TYP &phase_data_s, // Reference to structure containing PWM output data for current phase
	buffered out port:32 p32_pwm_hi, // 32-bit buffered output port for High-Leg pulse
	buffered out port:32 p32_pwm_lo, // 32-bit buffered output port for High-Leg pulse
	unsigned edge_id, // Identifier for current edge
	unsigned ref_time // Reference time-stamp
)
{
	load_pwm_edge_onto_port( phase_data_s.hi.edges[edge_id] ,p32_pwm_hi ,ref_time );
	load_pwm_edge_onto_port( phase_data_s.lo.edges[edge_id] ,p32_pwm_lo ,ref_time );
} // load_pwm_phase
/*****************************************************************************/
void load_pwm_edge_for_all_ports( // Load all data ports for current edge
	PWM_BUFFER_TYP pwm_data_s, // Structure containing PWM output data
	buffered out port:32 p32_pwm_hi[], // 32-bit buffered output port for High-Leg pulse
	buffered out port:32 p32_pwm_lo[], // 32-bit buffered output port for High-Leg pulse
	unsigned edge_id, // Identifier for current edge
	unsigned ref_time // Reference time-stamp
)
{
	int phase_cnt; // Phase counter

	for (phase_cnt=0; phase_cnt<NUM_PWM_PHASES; phase_cnt++)
	{
		load_pwm_phase( pwm_data_s.phase_data[phase_cnt] ,p32_pwm_hi[phase_cnt] ,p32_pwm_lo[phase_cnt] ,edge_id ,ref_time );
	} // for phase_cnt

} // load_pwm_edge_for_all_ports
/*****************************************************************************/
void do_pwm_inv_triggered( 
	chanend c_pwm, 
	buffered out port:32 p32_pwm_hi[], 
	buffered out port:32 p32_pwm_lo[], 
	chanend? c_adc_trig, 
	in port? p16_adc_sync, 
	clock pwm_clk
)
{
	PWM_BUFFER_TYP pwm_data_s; // Structure containing PWM output data
	unsigned buf_id; // Double-buffer identifier [0,1]
	unsigned mem_addr; // Shared memory address
	unsigned ref_time; // Reference Time incremented every PWM period, all other time are measured relative to this value
	unsigned pattern; // Bit-pattern on port
	int data_ready; //Data ready flag


	c_pwm :> mem_addr;	// First read the shared memory buffer address from the client

	do_pwm_port_config( p32_pwm_hi ,p32_pwm_lo ,p16_adc_sync ,pwm_clk ); // configure the ports

	// Find out value of time clock on an output port, WITHOUT changing port value
	pattern = peek( p32_pwm_hi[0] ); // Find out value on 1-bit port. NB Only LS-bit is relevant
	ref_time = partout_timestamped( p32_pwm_hi[0] ,1 ,pattern ); // Re-load output port with same bit-value

	c_pwm :> buf_id; // Wait for initial buffer id
	data_ready = 1; // signal new data ready

	// Loop forever
	while (1)
	{
		// Check if new data ready
		if (data_ready)
		{
			read_pwm_data_from_mem( pwm_data_s ,mem_addr ,buf_id ); // Read data from new buffer in shared memory

			if (pwm_data_s.cur_mode != D_PWM_MODE_3) break; // Check for valid mode
		} // if (data_ready)

		ref_time += INIT_SYNC_INCREMENT; // Update reference time to next PWM period

		// WARNING: Load port events in correct time order
		load_pwm_edge_for_all_ports( pwm_data_s ,p32_pwm_hi ,p32_pwm_lo ,0 ,ref_time ); // Load all ports with data for 1st edge
		load_pwm_edge_for_all_ports( pwm_data_s ,p32_pwm_hi ,p32_pwm_lo ,1 ,ref_time ); // Load all ports with data for 2nd edge

#if LOCK_ADC_TO_PWM
		// Calculate time to read in dummy value from adc port
		p16_adc_sync @ (ref_time + HALF_DEAD_TIME) :> void; // NB Blocking wait
		outct( c_adc_trig ,XS1_CT_END ); // Send synchronisation token to ADC
#endif // LOCK_ADC_TO_PWM

		// Check if new data is ready
		select
		{
			case c_pwm :> buf_id : // Is new buf_id ready?
				data_ready = 1; // signal new data ready
			break; // c_pwm :> buf_id;

			default :
				data_ready = 0; // signal data NOT ready
			break; // default
		} // select
	} // while(1)

} // do_pwm_inv_triggered
/*****************************************************************************/
// pwm_service_inv
