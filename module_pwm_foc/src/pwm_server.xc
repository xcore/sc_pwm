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


	acquire_lock();
	printstrln("PWM Server Starts");
	release_lock();

	pwm_serv_s.id = motor_id; // Assign motor identifier

	do_pwm_port_config( p32_pwm_hi ,p32_pwm_lo ,p16_adc_sync ,pwm_clk ); // configure the ports

	// Find out value of time clock on an output port, WITHOUT changing port value
	pattern = peek( p32_pwm_hi[0] ); // Find out value on 1-bit port. NB Only LS-bit is relevant
	pwm_serv_s.ref_time = partout_timestamped( p32_pwm_hi[0] ,1 ,pattern ); // Re-load output port with same bit-value

	init_pwm_data( pwm_serv_s ,pwm_comms_s ,pwm_ctrl_s ,c_pwm ); // Initialise PWM parameters (from Client)

	pwm_serv_s.data_ready = 1; // Signal new data ready. NB this happened in init_pwm_data()

	/* This loop requires at least ~280 cycles, which means the PWM period must be at least 512 cycles.
	 * If convert_all_pulse_widths was optimised for speed, maybe a PWM period of 256 cycles would be possible
	 */
	while (1)
	{
#pragma xta endpoint "pwm_main_loop"
		// Do processing for one PWM period, using PWM data in current buffer

		// Check if new data ready
		if (pwm_serv_s.data_ready)
		{
			// If shared memory was used for data transfer, port data is already in pwm_ctrl_s.buf_data[pwm_comms_s.buf]
			if (0 == PWM_SHARED_MEM)
			{ // Shared Memory NOT used, so receive pulse widths from channel and calculate port data on server side.

				c_pwm :> pwm_comms_s.params; // Receive PWM parameters from Client

				if (PWM_TERMINATED == pwm_comms_s.params.id) break; // Break out of while loop

				// Convert all PWM pulse widths to pattern/time_offset port data
				convert_all_pulse_widths( pwm_comms_s ,pwm_ctrl_s.buf_data[pwm_comms_s.buf] ); // Max 178 Cycles
			} // if (0 == PWM_SHARED_MEM)
		} // if (pwm_serv_s.data_ready)

		pwm_serv_s.ref_time += INIT_SYNC_INCREMENT; // Update reference time to next PWM period

		// Load ports in correct time order. Rising-edges --> ADC_trigger --> Falling-edges ...

		/* These port-load commands have been unwrapped and expanded to improve timing.
		 * WARNING: If timing is not met pulse stays low for whole timer period (2^16 cycles)
		 */
    // Rising edges - these have negative time offsets - 44 Cycles
		p32_pwm_hi[PWM_PHASE_A] @ (PORT_TIME_TYP)(pwm_serv_s.ref_time + pwm_ctrl_s.buf_data[pwm_comms_s.buf].rise_edg.phase_data[PWM_PHASE_A].hi.time_off) <: pwm_ctrl_s.buf_data[pwm_comms_s.buf].rise_edg.phase_data[PWM_PHASE_A].hi.pattern;

		p32_pwm_lo[PWM_PHASE_A] @ (PORT_TIME_TYP)(pwm_serv_s.ref_time + pwm_ctrl_s.buf_data[pwm_comms_s.buf].rise_edg.phase_data[PWM_PHASE_A].lo.time_off) <: pwm_ctrl_s.buf_data[pwm_comms_s.buf].rise_edg.phase_data[PWM_PHASE_A].lo.pattern;

		p32_pwm_hi[PWM_PHASE_B] @ (PORT_TIME_TYP)(pwm_serv_s.ref_time + pwm_ctrl_s.buf_data[pwm_comms_s.buf].rise_edg.phase_data[PWM_PHASE_B].hi.time_off) <: pwm_ctrl_s.buf_data[pwm_comms_s.buf].rise_edg.phase_data[PWM_PHASE_B].hi.pattern;
		p32_pwm_lo[PWM_PHASE_B] @ (PORT_TIME_TYP)(pwm_serv_s.ref_time + pwm_ctrl_s.buf_data[pwm_comms_s.buf].rise_edg.phase_data[PWM_PHASE_B].lo.time_off) <: pwm_ctrl_s.buf_data[pwm_comms_s.buf].rise_edg.phase_data[PWM_PHASE_B].lo.pattern;

		p32_pwm_hi[PWM_PHASE_C] @ (PORT_TIME_TYP)(pwm_serv_s.ref_time + pwm_ctrl_s.buf_data[pwm_comms_s.buf].rise_edg.phase_data[PWM_PHASE_C].hi.time_off) <: pwm_ctrl_s.buf_data[pwm_comms_s.buf].rise_edg.phase_data[PWM_PHASE_C].hi.pattern;
		p32_pwm_lo[PWM_PHASE_C] @ (PORT_TIME_TYP)(pwm_serv_s.ref_time + pwm_ctrl_s.buf_data[pwm_comms_s.buf].rise_edg.phase_data[PWM_PHASE_C].lo.time_off) <: pwm_ctrl_s.buf_data[pwm_comms_s.buf].rise_edg.phase_data[PWM_PHASE_C].lo.pattern;

		if (1 == LOCK_ADC_TO_PWM)
		{
			/* This trigger is used to signal to the ADC block the location of the PWM High-pulse mid-point.
			 * As a blocking wait is required, we send the trigger early by 1/4 of a PWM pulse.
			 * This then allows time to set up the falling edges before they are required.
			 * WARNING: The ADC module (module_foc_adc) must compensate for the early trigger.
			 */
			p16_adc_sync @ (PORT_TIME_TYP)(pwm_serv_s.ref_time - QUART_PWM_MAX) :> void; // NB Blocking wait
			outct( c_adc_trig ,XS1_CT_END ); // Send synchronisation token to ADC
		} // if (1 ==LOCK_ADC_TO_PWM)

		/* These port-load commands have been unwrapped and expanded to improve timing.
		 * DANGER: If a short pulse (Low voltage) does NOT meet timing, then the pulse stays high for a whole timer period
		 * (2^16 cycles) This is a HIGH voltage and could damage the motor.
		 */
    // Falling edges - these have positive time offsets - 44 Cycles
		p32_pwm_hi[PWM_PHASE_A] @ (PORT_TIME_TYP)(pwm_serv_s.ref_time + pwm_ctrl_s.buf_data[pwm_comms_s.buf].fall_edg.phase_data[PWM_PHASE_A].hi.time_off) <: pwm_ctrl_s.buf_data[pwm_comms_s.buf].fall_edg.phase_data[PWM_PHASE_A].hi.pattern;
		p32_pwm_lo[PWM_PHASE_A] @ (PORT_TIME_TYP)(pwm_serv_s.ref_time + pwm_ctrl_s.buf_data[pwm_comms_s.buf].fall_edg.phase_data[PWM_PHASE_A].lo.time_off) <: pwm_ctrl_s.buf_data[pwm_comms_s.buf].fall_edg.phase_data[PWM_PHASE_A].lo.pattern;

		p32_pwm_hi[PWM_PHASE_B] @ (PORT_TIME_TYP)(pwm_serv_s.ref_time + pwm_ctrl_s.buf_data[pwm_comms_s.buf].fall_edg.phase_data[PWM_PHASE_B].hi.time_off) <: pwm_ctrl_s.buf_data[pwm_comms_s.buf].fall_edg.phase_data[PWM_PHASE_B].hi.pattern;
		p32_pwm_lo[PWM_PHASE_B] @ (PORT_TIME_TYP)(pwm_serv_s.ref_time + pwm_ctrl_s.buf_data[pwm_comms_s.buf].fall_edg.phase_data[PWM_PHASE_B].lo.time_off) <: pwm_ctrl_s.buf_data[pwm_comms_s.buf].fall_edg.phase_data[PWM_PHASE_B].lo.pattern;

		p32_pwm_hi[PWM_PHASE_C] @ (PORT_TIME_TYP)(pwm_serv_s.ref_time + pwm_ctrl_s.buf_data[pwm_comms_s.buf].fall_edg.phase_data[PWM_PHASE_C].hi.time_off) <: pwm_ctrl_s.buf_data[pwm_comms_s.buf].fall_edg.phase_data[PWM_PHASE_C].hi.pattern;
		p32_pwm_lo[PWM_PHASE_C] @ (PORT_TIME_TYP)(pwm_serv_s.ref_time + pwm_ctrl_s.buf_data[pwm_comms_s.buf].fall_edg.phase_data[PWM_PHASE_C].lo.time_off) <: pwm_ctrl_s.buf_data[pwm_comms_s.buf].fall_edg.phase_data[PWM_PHASE_C].lo.pattern;

		// Check if new data is ready  - ~8 cycles
		select
		{
			case c_pwm :> pwm_comms_s.buf : // Is new buf_id ready?
				pwm_serv_s.data_ready = 1; // signal new data ready
			break; // c_pwm :> pwm_comms_s.buf;

			default :
				pwm_serv_s.data_ready = 0; // signal data NOT ready
			break; // default
		} // select
	} // while(1)

	acquire_lock();
	printstrln("PWM Server Ends");
	release_lock();
} // foc_pwm_do_triggered
/*****************************************************************************/
// pwm_service_inv
