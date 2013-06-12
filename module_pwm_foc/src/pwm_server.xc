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
static void init_pwm_data( // Initialise structure containing PWM data
	PWM_SERV_TYP &pwm_serv_s, // Reference to structure containing PWM server control data 
	PWM_COMMS_TYP &pwm_comms_s, // Reference to structure containing PWM communication data 
	PWM_ARRAY_TYP &pwm_ctrl_s, // Reference to structure containing double-buffered PWM output data
	chanend c_pwm // PWM channel between Client and Server
)
{
	// Initialise the address of PWM Control structure, in case shared memory is used
	pwm_comms_s.mem_addr = get_pwm_struct_address( pwm_ctrl_s ); 

	// Send address to Client, in case shared memory is used
	c_pwm <: pwm_comms_s.mem_addr;

	// Wait for initial buffer id
	c_pwm :> pwm_comms_s.buf;
} // init_pwm_data
/*****************************************************************************/
static void do_pwm_port_config( 
	buffered out port:32 p32_pwm_hi[], 
	buffered out port:32 p32_pwm_lo[], 
	in port? p16_adc_sync, 
	clock pwm_clk 
)
{
	unsigned i;


 	configure_clock_rate( pwm_clk ,PLATFORM_REFERENCE_MHZ ,1 ); // Configure clock rate to PLATFORM_REFERENCE_MHZ/1 (100 MHz)

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
	PWM_SERV_TYP &pwm_serv_s, // Reference to structure containing PWM server control data 
	PWM_PORT_TYP &port_data_s, // Reference to structure containing PWM output port 
	buffered out port:32 p32_pwm_leg, // current 32-bit buffered output port
	unsigned ref_time // Reference time-stamp
)
{
	// Calculate absolute time to load pattern on port
	p32_pwm_leg @ (PORT_TIME_TYP)(ref_time + port_data_s.time_off) <: port_data_s.pattern;

#ifdef MB
// This xscope overloads the bus, so needs to be very selective
if (pwm_serv_s.id) // Only do motor_1
{
	if (!(pwm_serv_s.temp & 7)) // Only do phase_A on high-leg
	{
		if (16 & pwm_serv_s.cnt) // Only do alternate bursts of 16
		{
			xscope_probe_data( 3 ,pwm_serv_s.temp );
		} // if (16 & pwm_serv_s.cnt)

		pwm_serv_s.cnt++;
	} // if (pwm_serv_s.temp & 7)
} // if (pwm_serv_s.id)
#endif //MB~

} // load_pwm_port_data
/*****************************************************************************/
static void load_pwm_phase( // Load all data ports for current phase/edge
	PWM_SERV_TYP &pwm_serv_s, // Reference to structure containing PWM server control data 
	PWM_PHASE_TYP &phase_data_s, // Reference to structure containing PWM output data for current phase
	buffered out port:32 p32_pwm_hi, // 32-bit buffered output port for High-Leg pulse
	buffered out port:32 p32_pwm_lo, // 32-bit buffered output port for Low-Leg pulse
	unsigned ref_time // Reference time-stamp
)
{
	int base = (pwm_serv_s.temp << 1); // MB~ dbg


pwm_serv_s.temp = base + 0; //MB~ dbg
	load_pwm_port_data( pwm_serv_s ,phase_data_s.hi ,p32_pwm_hi ,ref_time );
pwm_serv_s.temp = base + 1; //MB~ dbg
	load_pwm_port_data( pwm_serv_s ,phase_data_s.lo ,p32_pwm_lo ,ref_time );
} // load_pwm_phase
/*****************************************************************************/
static void load_pwm_edge_for_all_ports( // Load all data ports for current edge
	PWM_SERV_TYP &pwm_serv_s, // Reference to structure containing PWM server control data 
	PWM_EDGE_TYP pwm_edge_data_s, // Structure containing PWM output data for current edge
	buffered out port:32 p32_pwm_hi[], // 32-bit buffered output port for High-Leg pulse
	buffered out port:32 p32_pwm_lo[], // 32-bit buffered output port for High-Leg pulse
	unsigned ref_time // Reference time-stamp
)
{
	int phase_cnt; // Phase counter
	int base = (pwm_serv_s.temp << 2); // MB~ dbg


// acquire_lock(); printstr("S_PTN="); printhexln( pwm_edge_data_s.phase_data[PWM_PHASE_A].hi.pattern ); release_lock(); //MB~
	for (phase_cnt=0; phase_cnt<NUM_PWM_PHASES; phase_cnt++)
	{
pwm_serv_s.temp =  base + phase_cnt; //MB~ dbg
		load_pwm_phase( pwm_serv_s ,pwm_edge_data_s.phase_data[phase_cnt] ,p32_pwm_hi[phase_cnt] ,p32_pwm_lo[phase_cnt] ,ref_time );
	} // for phase_cnt

} // load_pwm_edge_for_all_ports
/*****************************************************************************/
static void do_pwm_period( // Does processing for one PWM period (4096 cycles)
	PWM_SERV_TYP &pwm_serv_s, // Reference to structure containing PWM server control data 
	PWM_COMMS_TYP &pwm_comms_s, // Reference to structure containing PWM communication data
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
	
			c_pwm :> pwm_comms_s.params; // Receive PWM parameters from Client
	
			// Convert all PWM pulse widths to pattern/time_offset port data
			convert_all_pulse_widths( pwm_comms_s ,pwm_buf_s );
		} // if (0 == PWM_SHARED_MEM)
	} // if (pwm_serv_s.data_ready)

	pwm_serv_s.ref_time += INIT_SYNC_INCREMENT; // Update reference time to next PWM period

	// WARNING: Load port events in correct time order (i.e. rising THEN falling edge)
pwm_serv_s.temp = 1; //MB~ dbg
	load_pwm_edge_for_all_ports( pwm_serv_s ,pwm_buf_s.rise_edg ,p32_pwm_hi ,p32_pwm_lo ,pwm_serv_s.ref_time ); // Load all ports with data for rising edge
pwm_serv_s.temp = 0; //MB~ dbg
	load_pwm_edge_for_all_ports( pwm_serv_s ,pwm_buf_s.fall_edg ,p32_pwm_hi ,p32_pwm_lo ,pwm_serv_s.ref_time ); // Load all ports with data for falling edge

	if (1 == LOCK_ADC_TO_PWM)
	{
		// Calculate time to read in dummy value from adc port
		p16_adc_sync @ (PORT_TIME_TYP)(pwm_serv_s.ref_time + HALF_DEAD_TIME) :> void; // NB Blocking wait
		outct( c_adc_trig ,XS1_CT_END ); // Send synchronisation token to ADC
	} // if (1 ==LOCK_ADC_TO_PWM)

	// Check if new data is ready
	select
	{
		case c_pwm :> pwm_comms_s.buf : // Is new buf_id ready?
			pwm_serv_s.data_ready = 1; // signal new data ready
		break; // c_pwm :> pwm_comms_s.buf;

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
	PWM_ARRAY_TYP pwm_ctrl_s; // Structure containing double-buffered PWM output data
	PWM_SERV_TYP pwm_serv_s; // Structure containing PWM server control data 
	PWM_COMMS_TYP pwm_comms_s; // Structure containing PWM communication data
	unsigned pattern; // Bit-pattern on port


	pwm_serv_s.id = motor_id; // Assign motor identifier
	pwm_serv_s.cnt = 0; // MB~ dbg

	do_pwm_port_config( p32_pwm_hi ,p32_pwm_lo ,p16_adc_sync ,pwm_clk ); // configure the ports

	// Find out value of time clock on an output port, WITHOUT changing port value
	pattern = peek( p32_pwm_hi[0] ); // Find out value on 1-bit port. NB Only LS-bit is relevant
	pwm_serv_s.ref_time = partout_timestamped( p32_pwm_hi[0] ,1 ,pattern ); // Re-load output port with same bit-value

	init_pwm_data( pwm_serv_s ,pwm_comms_s ,pwm_ctrl_s ,c_pwm ); // Initialise PWM parameters (from Client)

	pwm_serv_s.data_ready = 1; // Signal new data ready. NB this happened in init_pwm_data() 

	// Loop forever
	while (1)
	{
#pragma xta endpoint "pwm_main_loop"

		// Do processing for one PWM period, using PWM data in current buffer 
		do_pwm_period( pwm_serv_s ,pwm_comms_s ,pwm_ctrl_s.buf_data[pwm_comms_s.buf] 
			,c_pwm ,p32_pwm_hi ,p32_pwm_lo ,c_adc_trig ,p16_adc_sync );
	} // while(1)

} // foc_pwm_do_triggered
/*****************************************************************************/
// pwm_service_inv
