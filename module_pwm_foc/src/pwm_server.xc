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
 *
 **/                                   

#include "pwm_server.h"

/*****************************************************************************/
static void init_pwm_params( // Initialise structure containing PWM parameters (from Client)
	PWM_PARAM_TYP &pwm_param_s, // Reference to structure containing PWM parameters (from Client)
	PWM_CONTROL_TYP &pwm_ctrl_s, // Reference to structure containing double-buffered PWM output data
	chanend c_pwm, // PWM channel between Client and Server
	unsigned motor_id // Motor identifier
)
{
	// Initialise the address of PWM Control structure, in case shared memory is used
	pwm_param_s.mem_addr = get_pwm_struct_address( pwm_ctrl_s ); 

	// Send address to Client, in case shared memory is used
	c_pwm <: pwm_param_s.mem_addr;

	// Wait for initial buffer id
	c_pwm :> pwm_param_s.buf;
} // init_pwm_params
/*****************************************************************************/
static void do_pwm_port_config( 
	buffered out port:32 p32_pwm_hi[], 
	buffered out port:32 p32_pwm_lo[], 
	in port? p16_adc_sync, 
	clock pwm_clk 
)
{
	unsigned i;


	// For historical reasons, PWM timings are based on a 250 MHz clock
 	configure_clock_rate( pwm_clk ,PLATFORM_REFERENCE_MHZ ,1 ); // Configure clock rate to PLATFORM_REFERENCE_MHZ/1 (250 MHz)

	for (i = 0; i < NUM_PWM_PHASES; i++)
	{
		configure_out_port( p32_pwm_hi[i] ,pwm_clk ,0 ); // Set initial value of port to 0 (Switched Off) 
		configure_out_port( p32_pwm_lo[i] ,pwm_clk ,0 ); // Set initial value of port to 0 (Switched Off)  
		set_port_inv( p32_pwm_lo[i] );
	}

	if (1 == LOCK_ADC_TO_PWM)
	{
		configure_in_port( p16_adc_sync ,pwm_clk );	// Dummy port used to send ADC synchronisation pulse
	} // if (1 == LOCK_ADC_TO_PWM)

	start_clock( pwm_clk );
} // do_pwm_port_config_inv_adc_trig
/*****************************************************************************/
static void load_pwm_port_data( // Load one set of output port data
	PWM_PORT_TYP &port_data_s, // Reference to structure containing PWM output port 
	buffered out port:32 p32_pwm_leg, // current 32-bit buffered output port
	unsigned ref_time // Reference time-stamp
)
{
	// Calculate absolute time to load pattern on port
	p32_pwm_leg @ (ref_time + port_data_s.time_off) <: port_data_s.pattern;
} // load_pwm_port_data
/*****************************************************************************/
static void load_pwm_phase( // Load all data ports for current phase/edge
	PWM_PHASE_TYP &phase_data_s, // Reference to structure containing PWM output data for current phase
	buffered out port:32 p32_pwm_hi, // 32-bit buffered output port for High-Leg pulse
	buffered out port:32 p32_pwm_lo, // 32-bit buffered output port for Low-Leg pulse
	unsigned ref_time // Reference time-stamp
)
{
	load_pwm_port_data( phase_data_s.hi ,p32_pwm_hi ,ref_time );
	load_pwm_port_data( phase_data_s.lo ,p32_pwm_lo ,ref_time );
} // load_pwm_phase
/*****************************************************************************/
static void load_pwm_edge_for_all_ports( // Load all data ports for current edge
	PWM_EDGE_TYP pwm_edge_data_s, // Structure containing PWM output data for current edge
	buffered out port:32 p32_pwm_hi[], // 32-bit buffered output port for High-Leg pulse
	buffered out port:32 p32_pwm_lo[], // 32-bit buffered output port for High-Leg pulse
	unsigned ref_time // Reference time-stamp
)
{
	int phase_cnt; // Phase counter


	for (phase_cnt=0; phase_cnt<NUM_PWM_PHASES; phase_cnt++)
	{
		load_pwm_phase( pwm_edge_data_s.phase_data[phase_cnt] ,p32_pwm_hi[phase_cnt] ,p32_pwm_lo[phase_cnt] ,ref_time );
	} // for phase_cnt

} // load_pwm_edge_for_all_ports
/*****************************************************************************/
static void do_pwm_period( // Does processing for one PWM period (4096 cycles)
	PWM_SERV_TYP &pwm_serv_s, // Reference to structure containing PWM server control data structure
	PWM_PARAM_TYP &pwm_param_s, // Reference to structure containing PWM parameters (from Client)
	PWM_BUFFER_TYP &pwm_buf_s, // Reference to buffer containing PWM output data for one period
	chanend c_pwm, 
	buffered out port:32 p32_pwm_hi[], 
	buffered out port:32 p32_pwm_lo[], 
	chanend? c_adc_trig, 
	in port? p16_adc_sync
)
{
	// Check if new data ready
	if (pwm_serv_s.data_ready)
	{
		// If shared memory was used for data transfer, port data is already in pwm_buf_s
		if (0 == PWM_SHARED_MEM)
		{ // Shared Memory NOT used, so receive pulse widths from channel and calculate port data on server side.
	
			for (int phase_cnt = 0; phase_cnt < NUM_PWM_PHASES; phase_cnt++) 
			{
				c_pwm :> pwm_param_s.widths[phase_cnt]; // Receive PWM pulse-width for current phase
			} // for phase_cnt
	
			// Convert all PWM pulse widths to pattern/time_offset port data
			convert_all_pulse_widths( pwm_param_s ,pwm_buf_s );
		} // if (0 == PWM_SHARED_MEM)
	} // if (pwm_serv_s.data_ready)

	pwm_serv_s.ref_time += INIT_SYNC_INCREMENT; // Update reference time to next PWM period

	// WARNING: Load port events in correct time order (i.e. rising THEN falling edge)
	load_pwm_edge_for_all_ports( pwm_buf_s.rise_edg ,p32_pwm_hi ,p32_pwm_lo ,pwm_serv_s.ref_time ); // Load all ports with data for rising edge
	load_pwm_edge_for_all_ports( pwm_buf_s.fall_edg ,p32_pwm_hi ,p32_pwm_lo ,pwm_serv_s.ref_time ); // Load all ports with data for falling edge

	if (1 == LOCK_ADC_TO_PWM)
	{
		// Calculate time to read in dummy value from adc port
		p16_adc_sync @ (pwm_serv_s.ref_time + HALF_DEAD_TIME) :> void; // NB Blocking wait
		outct( c_adc_trig ,XS1_CT_END ); // Send synchronisation token to ADC
	} // if (1 ==LOCK_ADC_TO_PWM)

	// Check if new data is ready
	select
	{
		case c_pwm :> pwm_param_s.buf : // Is new buf_id ready?
			pwm_serv_s.data_ready = 1; // signal new data ready
		break; // c_pwm :> pwm_param_s.buf;

		default :
			pwm_serv_s.data_ready = 0; // signal data NOT ready
		break; // default
	} // select

} // do_pwm_period
/*****************************************************************************/
void foc_pwm_do_triggered( // Implementation of the Centre-aligned, High-Low pair, PWM server, with ADC sync
	unsigned motor_id, // Motor identifier
	chanend c_pwm, // PWM channel between Client and Server
	buffered out port:32 p32_pwm_hi[], // array of PWM ports (High side)  
	buffered out port:32 p32_pwm_lo[], // array of PWM ports (Low side)   
	chanend? c_adc_trig, // ADC trigger channel 
	in port? p16_adc_sync, // Dummy port used with ADC trigger
	clock pwm_clk // clock for generating accurate PWM timing
)
{
	PWM_CONTROL_TYP pwm_ctrl_s; // Structure containing double-buffered PWM output data
	PWM_SERV_TYP pwm_serv_s; // Structure containing PWM server control data 
	PWM_PARAM_TYP pwm_param_s; // Structure containing PWM parameters (Passed from Client)
	unsigned pattern; // Bit-pattern on port


	do_pwm_port_config( p32_pwm_hi ,p32_pwm_lo ,p16_adc_sync ,pwm_clk ); // configure the ports

	// Find out value of time clock on an output port, WITHOUT changing port value
	pattern = peek( p32_pwm_hi[0] ); // Find out value on 1-bit port. NB Only LS-bit is relevant
	pwm_serv_s.ref_time = partout_timestamped( p32_pwm_hi[0] ,1 ,pattern ); // Re-load output port with same bit-value

	init_pwm_params( pwm_param_s ,pwm_ctrl_s ,c_pwm ,motor_id ); // Initialise PWM parameters (from Client)

	pwm_serv_s.data_ready = 1; // Signal new data ready. NB this happened in init_pwm_params() 

	// Loop forever
	while (1)
	{
#pragma xta endpoint "pwm_main_loop"

		// Do processing for one PWM period, using PWM data in current buffer 
		do_pwm_period( pwm_serv_s ,pwm_param_s ,pwm_ctrl_s.buf_data[pwm_param_s.buf] 
			,c_pwm ,p32_pwm_hi ,p32_pwm_lo ,c_adc_trig ,p16_adc_sync );
	} // while(1)

} // foc_pwm_do_triggered
/*****************************************************************************/
// pwm_service_inv
