/**
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

#include "capture_pwm_data.h"

/*****************************************************************************/
void config_all_ports( // Configure all ports to use the same clock
	buffered in port:32 p32_tst_hi[], // array of PWM ports for PWM High-leg
	buffered in port:32 p32_tst_lo[], // array of PWM ports for PWM Low-leg
	out port p8_tst_sync, // NB Dummy output port
	clock comm_clk // Common clock for all test ports
)
{
  PWM_PHASE_ENUM phase_cnt; // PWM phase counter


	for (phase_cnt=0; phase_cnt<NUM_PWM_PHASES; phase_cnt++)
	{
	  configure_in_port( p32_tst_hi[phase_cnt] ,comm_clk );
	  configure_in_port( p32_tst_lo[phase_cnt] ,comm_clk );

		// PWM server is set-up to invert Low-Leg port. So we have to compensate
		set_port_inv( p32_tst_lo[phase_cnt] );
	} // for phase_cnt

  configure_out_port( p8_tst_sync ,comm_clk ,0 );

  start_clock(comm_clk);

} // config_all_ports
/*****************************************************************************/
void capture_pwm_trigger_data( // Captures PWM-to-ADC trigger data
	out port p8_tst_sync, // NB Dummy output port
	chanend c_trigger, // PWM-to-ADC trigger channel from PWM server
	streaming chanend c_chk // Channel for transmitting trigger data to test checker
)
{
	PORT_TIME_TYP port_time; // Time when port read
	unsigned char cntrl_token; // control token


	// Loop forever
	while (1)
	{
		inct_byref( c_trigger, cntrl_token );

		p8_tst_sync <: (unsigned char)cntrl_token @ port_time; // Ouput dummy data to get timestamp

		c_chk <: (signed)port_time; // Send timestamp of trigger to checker
	}	// while (1)

} // capture_pwm_trigger_data
/*****************************************************************************/
void capture_pwm_leg_data( // Captures PWM data results for one leg
	buffered in port:32 p32_leg[], // array of PWM ports for one PWM-leg
	streaming chanend c_chk[], // Array of channel for transmitting PWM data to test checker
	PWM_LEG_ENUM leg_id // PWM-leg identifier
)
{
	PWM_PORT_TYP port_data_s; // Structure containing PWM port data captured from input pins

	PWM_PHASE_ENUM phase_id; // Identifier of phase being tested
	unsigned curr_pins; // current value on High-Leg input pins
	unsigned prev_pins; // Initialise previous High-Leg input pins to impossible value
	unsigned chan_off = 0; // offset into channel array


	c_chk[0] :> phase_id; // Get identifier of phase to be tested from checker

	p32_leg[phase_id] :> prev_pins; // Initialise previous pin value

	// Loop forever
	while (1)
	{
		p32_leg[phase_id] :> curr_pins @ port_data_s.time_off;

		if (curr_pins != prev_pins)
		{
			port_data_s.pattern = curr_pins;

			// NB We need an array of channels, as one channel does NOT read quick enough (in checker)
			c_chk[chan_off] <: port_data_s; // Send PWM data to checker

			// Update circular channel offset
			chan_off++; // Increment channel counter
			chan_off = (((unsigned)chan_off) & CHAN_MASK); // Wrap offset into range [0..CHAN_MASK];

			prev_pins = curr_pins;
		} // if (curr_pins != prev_pins)
	}	// while (1)

} // capture_pwm_leg_data
/*****************************************************************************/
