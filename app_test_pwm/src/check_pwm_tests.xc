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

#include "check_pwm_tests.h"

/*****************************************************************************/
static void init_check_data( // Initialise common check data for PWM tests
	CHECK_TST_TYP &chk_data_s // Reference to structure containing test check data
)
{
	init_common_data( chk_data_s.common ); // Initialise data common to Generator and Checker

	safestrcpy( chk_data_s.padstr1 ,"                                             " );
	safestrcpy( chk_data_s.padstr2 ,"                              " );

	chk_data_s.print = VERBOSE_PRINT; // Set print mode
	chk_data_s.dbg = 0; // Set debug mode
} // init_check_data
/*****************************************************************************/
static void init_phase_data( // Initialise check data for tests of one phase of PWM
	CHECK_TST_TYP &chk_data_s // Reference to structure containing test check data
)
{
	VECT_COMP_ENUM comp_cnt; // Counter for Test Vector components


	chk_data_s.event = PWM_LO_RISE; // Start checking when 1st Low-leg falling edge received
	chk_data_s.curr_leg = chk_data_s.curr_vect.comp_state[LEG]; // Initialise PWM-leg under test
	chk_data_s.prev_leg = chk_data_s.curr_leg; // Initialise previous PWM-leg under test

	// Clear error and test counters for current motor
	for (comp_cnt=0; comp_cnt<NUM_VECT_COMPS; comp_cnt++)
	{
		chk_data_s.phase_errs[comp_cnt] = 0; 
		chk_data_s.phase_tsts[comp_cnt] = 0; 
	} // for comp_cnt
} // init_phase_data
/*****************************************************************************/
static void init_wave_data( // Initialise data structure for one PWM wave
	CHECK_TST_TYP &chk_data_s, // Reference to structure containing test check data
	PWM_WAVE_TYP &wave_data_s // input wave-data structure to be initialised
)
{
	wave_data_s.time_sum = 0;
	wave_data_s.hi_wid = 0;
	wave_data_s.lo_wid = 0;
	wave_data_s.hi_sum = 0;
	wave_data_s.lo_sum = 0;
	wave_data_s.hi_num = 0;
	wave_data_s.lo_num = 0;
	wave_data_s.new_edge = 0; // Set to no edge detected

	wave_data_s.curr_data.first = 0;
	wave_data_s.curr_data.last = 0;
	wave_data_s.curr_data.port_data.pattern = 0;
	wave_data_s.curr_data.port_data.time_off = 0;

	wave_data_s.prev_data = wave_data_s.curr_data; // Initialise previous PWM value
} // init_wave_data
/*****************************************************************************/
static void init_line_data( // Initialise wave data for one PWM balanced-line (phase)
	CHECK_TST_TYP &chk_data_s, // Reference to structure containing test check data
	PWM_LINE_TYP &line_data_s // Reference to structure containing balance-line data
)
{
	PWM_LEG_ENUM leg_cnt; // balanced-line leg counter


	for (leg_cnt=0; leg_cnt<NUM_PWM_LEGS; leg_cnt++)
	{ 
		init_wave_data( chk_data_s ,line_data_s.waves[leg_cnt] );
	} // for leg_cnt
} // init_line_data
/*****************************************************************************/
static void print_pwm_pulse( // Print PWM Pulse data
	CHECK_TST_TYP &chk_data_s, // Reference to structure containing test check data
	unsigned pulse_width, // Width of input pulse
	const char pulse_name[] // name for input pulse
)
{
	acquire_lock(); // Acquire Display Mutex
	printstr( chk_data_s.padstr1 );
	printstr( chk_data_s.common.comp_data[LEG].state_names[chk_data_s.curr_leg].str	);
	printstr(pulse_name);
	printstr( "= " );
	printuint( pulse_width );
	printcharln(' ');
	release_lock(); // Release Display Mutex
} // print_pwm_pulse
/*****************************************************************************/
static void print_pwm_sample( // Print PWM parameters
	CHECK_TST_TYP &chk_data_s, // Reference to structure containing test check data
	PWM_WAVE_TYP &wave_data_s // Reference to a structure containing wave data for one PWM-Leg
)
{
	acquire_lock(); // Acquire Display Mutex
	printstr( chk_data_s.padstr1 );
	printstr( chk_data_s.common.comp_data[LEG].state_names[chk_data_s.curr_leg].str	);
	printhex( wave_data_s.curr_data.port_data.pattern );
	printstr( " T=" );
	printint( wave_data_s.curr_data.port_data.time_off );
	printcharln(' ');
	release_lock(); // Release Display Mutex
} // print_pwm_sample
/*****************************************************************************/
static int find_edge_offset_from_ls( // Finds first bit-change in 32-bit pattern (measured from LS end)
	unsigned inp_patn  // input 32-bit pattern
) // Return bit offset
{
	int bit_off = 0; // Initialise bit offset to LS-end of pattern
	unsigned ls_bit = (0x1 & inp_patn); // Get LS bit value from input pattern


	// loop until bit-change found
	while (inp_patn)
	{
		bit_off++; // Increment bit-offset
		inp_patn >>= 1; // shift out checked-bit

		if (ls_bit != (0x1 & inp_patn)) break; // Exit loop if bit-change found
	} // while (inp_patn)

	// Check if edge found
	if (PWM_PORT_WID <= bit_off)
	{
		assert(0 == 1); // ERROR: Edge not found
	} // if (PWM_PORT_WID <= bit_off)

	return bit_off;
} // find_edge_offset_from_ls
/*****************************************************************************/
static void init_sample_data( // Initialise PWM sample data, and if necessary correct edge-time
	PWM_SAMP_TYP &curr_pwm_s // Reference to structure containing current data for one PWM sample
)
{
	unsigned curr_patn = curr_pwm_s.port_data.pattern; // get current PWM sample pattern


	curr_pwm_s.first = (0x1 & curr_patn); // mask-out first (LS) bit
	curr_pwm_s.last = (PWM_MS_MASK & curr_patn) >> (PWM_PORT_WID - 1); // mask-out last (MS) bit

	// Rebase time-offset to just before first (LS) bit
	curr_pwm_s.port_data.time_off -= PWM_PORT_WID; // Correct time_offset

	// Check for edge ...

	/* NB The following logic relies on the fact that some combinations are unreachable,
	 * because the minimum pulse width is PWM_PORT_WID (32) 
	 */
	if (curr_pwm_s.first != curr_pwm_s.last)
	{ // Edge found
		PORT_TIME_TYP bit_off = (PORT_TIME_TYP)find_edge_offset_from_ls( curr_patn ); // Get edge offset
		curr_pwm_s.port_data.time_off += bit_off; // Place time-offset at edge
	} // if (curr_pwm_s.first != curr_pwm_s.last)

} // init_sample_data
/*****************************************************************************/
static void check_adc_trigger( // Check timing of ADC trigger, against previous High-leg rising edge
	CHECK_TST_TYP &chk_data_s, // Reference to structure containing test check data
	PWM_WAVE_TYP &wave_data_s // Reference to wave-data structure for PWM-leg under test
)
{
	int corr_time; // Corrected ADC-trigger time
	int cent_time; // port time for centre of High-Pulse
	int err_time; // ADC error time


	// Calculate ADC trigger error. (distance from centre of High-pulse)
	cent_time = (int)wave_data_s.fall_time - (int)(wave_data_s.hi_wid >> 1); // time_offset for centre of High-Pulse
	corr_time = (int)chk_data_s.adc_time + (int)(QUART_PWM_MAX - ADC_DELAY); // Compensate for early transmission of ADC-trigger

	err_time = corr_time - cent_time; // error for ADC trigger;
	err_time &= PWM_MASK; // mask into range [0..PWM_MASK]
	if (err_time > (PWM_MAX_VALUE >> 1)) err_time -= PWM_MAX_VALUE; // Max. absolute error is half PWM period

	chk_data_s.phase_tsts[ADC_TRIG]++;

	if (HALF_PORT_WID <= abs(err_time))
	{
		chk_data_s.phase_errs[ADC_TRIG]++;

		acquire_lock(); // Acquire Display Mutex
		printcharln(' ');
		printstr( chk_data_s.padstr1 );
		printstr( chk_data_s.common.comp_data[LEG].state_names[chk_data_s.curr_leg].str	);
		printstr(" ");
		printstr( chk_data_s.common.comp_data[ADC_TRIG].state_names[chk_data_s.curr_vect.comp_state[ADC_TRIG]].str	);
		printstr(" FAILURE: Error_Cycles=");
		printintln(err_time);
		release_lock(); // Release Display Mutex
	} // if (HALF_PORT_WID <= abs(err_time))

} // check_adc_trigger
/*****************************************************************************/
static void check_dead_time( // Check dead-time between edges in High and Low legs
	CHECK_TST_TYP &chk_data_s, // Reference to structure containing test check data
	PORT_TIME_TYP early_time,		// time of earlier edge
	PORT_TIME_TYP later_time		// time of later edge 
)
{
	int gap_time; // Time gap between edges


	gap_time = later_time - early_time; // Time difference between edges

	gap_time &= PORT_TIME_MASK; // mask into range [0..PORT_TIME_MASK]
	if (gap_time > (PORT_TIME_MASK>> 1)) gap_time -= PORT_TIME_MASK; // Max. absolute error is half timer period 
	gap_time = abs(gap_time);

	chk_data_s.phase_tsts[DEAD]++;

	// Check gap is large enough (should be half of dead-time)
	if ((HALF_DEAD_TIME - HALF_PORT_WID) > gap_time)
	{
		chk_data_s.phase_errs[DEAD]++;

		acquire_lock(); // Acquire Display Mutex
		printcharln(' ');
		printstr( chk_data_s.padstr1 );
		printstr( chk_data_s.common.comp_data[LEG].state_names[chk_data_s.curr_leg].str	);
		printstr(" DEAD_TIME FAILURE: Gap_Cycles=");
		printintln(gap_time);
		release_lock(); // Release Display Mutex
	} // if ((HALF_DEAD_TIME - HALF_PORT_WID) > abs(gap_time))

} // check_dead_time
/*****************************************************************************/
static void update_pwm_data( // Update PWM data
	CHECK_TST_TYP &chk_data_s, // Reference to structure containing test check data
	PWM_WAVE_TYP &wave_data_s // Reference to wave-data structure to be updated
)
{
	PWM_SAMP_TYP curr_pwm_s = wave_data_s.curr_data; // Reference to structure containing current PWM sample data
	PWM_SAMP_TYP prev_pwm_s = wave_data_s.prev_data; // Reference to structure containing previous PWM sample data
	PORT_TIME_TYP curr_time = (PORT_TIME_TYP)curr_pwm_s.port_data.time_off; // current PWM time-offset
	PORT_TIME_TYP prev_time = (PORT_TIME_TYP)prev_pwm_s.port_data.time_off; // previous PWM time-offset
	PORT_TIME_TYP diff_time = (curr_time - prev_time); // Elapsed time


	wave_data_s.new_edge = 0; // preset flag to NO new edge detected

	// Update pulse times ...

	/* NB The following logic relies on the fact that some combinations are unreachable,
	 * because the minimum pulse width is PWM_PORT_WID (32) 
	 */

	if (curr_pwm_s.last)
	{ // Currently High
		if (prev_pwm_s.last)
		{ // Constant High
			wave_data_s.time_sum +=  diff_time; // Update time for high portion of pulse
		} // if (prev_pwm_s.last)
		else
		{ // Rising edge
			wave_data_s.rise_time = curr_time; // Store Rising-edge time-stamp
			wave_data_s.lo_wid = wave_data_s.time_sum + diff_time; // Finalise time for low portion of pulse
			wave_data_s.time_sum = 0; // Initialise time sum for high portion of pulse
			wave_data_s.new_edge = 1; // Set flag for new edge

			// Check if this current test vector is valid
			if (VALID == chk_data_s.curr_vect.comp_state[CNTRL])
			{ // update accumulators for test of low-pulse-width
				wave_data_s.lo_sum += wave_data_s.lo_wid;
				wave_data_s.lo_num++;
			} // if (VALID == chk_data_s.curr_vect.comp_state[CNTRL])
		} // else !(prev_pwm_s.last)
	} // if (curr_pwm_s.last)
	else
	{ // Currently Low
		if (prev_pwm_s.last)
		{ // Falling Edge
			wave_data_s.fall_time = curr_time; // Store Falling-edge time-stamp
			wave_data_s.hi_wid = wave_data_s.time_sum + diff_time; // Finalise time for high portion of pulse
			wave_data_s.time_sum = 0; // Initialise time sum for low portion of pulse
			wave_data_s.new_edge = 1; // Set flag for new edge

			// Check if this current test vector is valid
			if (VALID == chk_data_s.curr_vect.comp_state[CNTRL])
			{ // update accumulators for test of high-pulse-width
				wave_data_s.hi_sum += wave_data_s.hi_wid;
				wave_data_s.hi_num++;
	
				if (chk_data_s.print)
				{
					print_pwm_pulse( chk_data_s ,wave_data_s.hi_wid ,"Hi_Width" ); // Print new PWM pulse data
				} // if (chk_data_s.print)
			} // if (VALID == chk_data_s.curr_vect.comp_state[CNTRL])
		} // if (prev_pwm_s.last)
		else
		{ // Constant Low
			wave_data_s.time_sum += diff_time; // Update time for low portion of pulse
		} // else !(prev_pwm_s.last)
	} // else !(curr_pwm_s.last)
} // update_pwm_data
/*****************************************************************************/
static void check_pwm_pulse_levels( // Check PWM mean voltage
	CHECK_TST_TYP &chk_data_s, // Reference to structure containing test check data
	PWM_WAVE_TYP &wave_data_s, // Reference to a structure containing wave data for one PWM-leg
	unsigned chk_wid 					// Check width for this width-state 
)
{
	chk_data_s.phase_tsts[WIDTH]++;

	if (chk_data_s.bound < abs(wave_data_s.meas_wid - chk_wid))
	{
		chk_data_s.phase_errs[WIDTH]++;

		acquire_lock(); // Acquire Display Mutex
		printcharln(' ');
		printstr( chk_data_s.padstr1 );
		printstr( chk_data_s.common.comp_data[LEG].state_names[chk_data_s.curr_leg].str	);
		printstrln(" FAILURE");
		release_lock(); // Release Display Mutex
	} // if (chk_data_s.hi_bound < abs(wave_data_s.meas_wid - chk_wid))

} // check_pwm_pulse_levels
/*****************************************************************************/
static void measure_pwm_width( // Calculate PWM-width from captured PWM wave data
	CHECK_TST_TYP &chk_data_s, // Reference to structure containing test check data
	PWM_WAVE_TYP &wave_data_s // Reference to wave-data structure containing line_data_s.waves[PWM_HI_LEG].meas_wid to be evaluated
)
{
	int hi_mean = 0; // Clear Mean of time PWM was high
	int lo_mean = 0; // Clear Mean of time PWM was low
	int period = 0; // Clear Mean PWM wave period


	wave_data_s.meas_wid = 0; // Clear Mean PWM wave period

	// Calculate Mean high-level time
	if (wave_data_s.hi_num)
	{
		hi_mean = (wave_data_s.hi_sum + (wave_data_s.hi_num >> 1)) / wave_data_s.hi_num;
	} // if (wave_data_s.hi_num)

	// Calculate Mean low-level time
	if (wave_data_s.lo_num)
	{
		lo_mean = (wave_data_s.lo_sum + (wave_data_s.lo_num >> 1)) / wave_data_s.lo_num;
	} // if (wave_data_s.lo_num)

	period = hi_mean + lo_mean;	// Calculate mean PWM wave period

	// Calculate equivalent measured PWM-width
	if (period) 
	{
		wave_data_s.meas_wid = ((PWM_MAX_VALUE * hi_mean) + (period >> 1))/period;
	} // if (period) 

} // measure_pwm_width
/*****************************************************************************/
static void initialise_pwm_width_test( // Initialise data for new Pulse-width test
	CHECK_TST_TYP &chk_data_s, // Reference to structure containing test check data
	PWM_LINE_TYP &line_s // Reference to all wave data for one motor
)
{
	// Clear accumulated data
	init_line_data( chk_data_s ,line_s ); // Initialise all wave data for one balanced line (phase)

	// Evaluate error bounds for Pulse-width checks (~2%)
	chk_data_s.bound = 1 + (chk_data_s.common.pwm_wids[chk_data_s.curr_vect.comp_state[WIDTH]] >> 6); 
} // initialise_pwm_width_test 
/*****************************************************************************/
static void finalise_pwm_leg( // Terminate pulse-width test for one PWM-leg
	CHECK_TST_TYP &chk_data_s, // Reference to structure containing test check data
	PWM_WAVE_TYP &wave_data_s, // Reference to wave data for one PWM-leg
	unsigned chk_wid // check width for this width-state under test
)
{
	measure_pwm_width( chk_data_s ,wave_data_s ); // Measure average pulse width

	if (chk_data_s.print)
	{
		acquire_lock(); // Acquire Display Mutex
		printstr( chk_data_s.padstr1 );
		printstr( chk_data_s.common.comp_data[LEG].state_names[chk_data_s.curr_leg].str	);
		printstr( " Mean_Width " );
		printuint(wave_data_s.meas_wid);
		printcharln(' ');
		release_lock(); // Release Display Mutex
	} // if (chk_data_s.print)

	check_pwm_pulse_levels( chk_data_s ,wave_data_s ,chk_wid ); // Check PWM pulse width

} // finalise_pwm_leg
/*****************************************************************************/
static void finalise_pwm_phase( // Terminate pulse-width test for one phase
	CHECK_TST_TYP &chk_data_s, // Reference to structure containing test check data
	PWM_LINE_TYP &line_data_s // Reference to all wave data for one balanced-line (phase)
)
{
	WIDTH_PWM_ENUM wid_state = chk_data_s.prev_vect.comp_state[WIDTH]; // Local copy of width-state under test
	unsigned hi_width = chk_data_s.common.pwm_wids[wid_state]; // Pulse-width check value for High-Leg 


	chk_data_s.curr_leg = PWM_HI_LEG; // Set PWM-leg under test
	finalise_pwm_leg( chk_data_s ,line_data_s.waves[PWM_HI_LEG] ,hi_width ); // finalise pulse-width test for Hi-Leg

	chk_data_s.curr_leg = PWM_LO_LEG; // Set PWM-leg under test
	finalise_pwm_leg( chk_data_s ,line_data_s.waves[PWM_LO_LEG] ,(hi_width + PWM_DEAD_TIME) ); // finalise pulse-width test for Lo-Leg
} // finalise_pwm_phase
/*****************************************************************************/
static void finalise_pwm_width_test( // Terminate pulse-width test for all phases under test
	CHECK_TST_TYP &chk_data_s, // Reference to structure containing test check data
	PWM_LINE_TYP &line_s // Reference to all wave data for one motor
)
{
	finalise_pwm_phase( chk_data_s ,line_s );
} // finalise_pwm_width_test 
/*****************************************************************************/
static int pwm_data_compare( // Check if 2 sets of PWM data are different
	PWM_PORT_TYP &data_a,	// Structure containing 1st set of PWM parameters
	PWM_PORT_TYP &data_b	// Structure containing 2nd set of PWM parameters
) // return TRUE (1) if sets are different, FALSE(0) if equal
{
	if (data_a.pattern != data_b.pattern) return 1;	// Check Pattern value

	if (data_a.time_off != data_b.time_off) return 1;	// Check time offset

	return 0; // No differences found
} // pwm_data_compare
/*****************************************************************************/
static void test_pwm_wave( // test new PWM input value
	CHECK_TST_TYP &chk_data_s, // Reference to structure containing test check data
	PWM_WAVE_TYP &wave_data_s // Reference to a structure containing wave data for one PWM-leg
)
{
	int do_test = 0;	// Flag set when next test required


	// Check for change in PWM data
	do_test = pwm_data_compare( wave_data_s.curr_data.port_data  ,wave_data_s.prev_data.port_data );

	// Check for parameter change
	if (do_test)
	{ // Parameters changed

		if (chk_data_s.print)
		{
//			print_pwm_sample( chk_data_s ,wave_data_s ); // Print new PWM sample
		} // if (chk_data_s.print)

		init_sample_data( wave_data_s.curr_data ); 

		update_pwm_data( chk_data_s ,wave_data_s ); // Update PWM-leg data

		// Store previous PWM data
		wave_data_s.prev_data = wave_data_s.curr_data;
	} // if (do_test)
} // test_pwm_wave
/*****************************************************************************/
static void test_pwm_phase( // test new PWM data against PWM data for phase under test
	CHECK_TST_TYP &chk_data_s, // Reference to structure containing test check data
	PWM_LINE_TYP &phase_data_s // Reference to a structure containing wave data for one PWM phase
)
{
	// test new PWM data against PWM-leg under test
	test_pwm_wave( chk_data_s ,phase_data_s.waves[chk_data_s.curr_leg] );

	// Check if new edge detected in wave-train
	if (phase_data_s.waves[chk_data_s.curr_leg].new_edge)
	{
		// Check which PWM event expected
		switch(chk_data_s.event)
		{
			case PWM_LO_RISE : // Low-leg rising edge 
				check_dead_time( chk_data_s ,phase_data_s.waves[PWM_HI_LEG].fall_time ,phase_data_s.waves[PWM_LO_LEG].rise_time );

				chk_data_s.event = PWM_HI_RISE; // set next event
			break; // case PWM_LO_RISE
			
			case PWM_HI_RISE : // High-leg rising edge 
				check_dead_time( chk_data_s ,phase_data_s.waves[PWM_LO_LEG].rise_time ,phase_data_s.waves[PWM_HI_LEG].rise_time );

				chk_data_s.event = PWM_ADC_TRIG; // set next event
			break; // case PWM_HI_RISE

			case PWM_HI_FALL :  // High-leg falling edge
				/* NB The ADC test sits here, because, before we can check whether the ADC-trigger is centred in the pulse.
				 * We require the new high-pulse-width to have been calculated
				 */
				if (VALID == chk_data_s.curr_vect.comp_state[CNTRL]) // Check if this current test vector is valid
				{
					// Check if ADC-trigger being tested
					if (chk_data_s.common.options.flags[TST_ADC])
					{ // Check adc-trigger against High-Leg falling edge
						check_adc_trigger( chk_data_s ,phase_data_s.waves[PWM_HI_LEG] );
					} // if (chk_data_s.common.options.flags[TST_ADC])
				} // if (VALID == chk_data_s.curr_vect.comp_state[CNTRL])

				check_dead_time( chk_data_s ,phase_data_s.waves[PWM_LO_LEG].rise_time ,phase_data_s.waves[PWM_HI_LEG].fall_time );

				chk_data_s.event = PWM_LO_FALL; // set next event
			break; // case PWM_HI_FALL
			
			case PWM_LO_FALL : // Low-leg falling edge 
				check_dead_time( chk_data_s ,phase_data_s.waves[PWM_HI_LEG].fall_time ,phase_data_s.waves[PWM_LO_LEG].fall_time );

				chk_data_s.event = PWM_LO_RISE; // set next event
			break; // case PWM_LO_FALL
		
			default :
				assert( 0 == 1); // Unexpected PWM event found
			break; // default
		} // switch(cur_event)
	} // if (phase_data_s.waves[chk_data_s.curr_leg].new_edge)
} // test_pwm_phase
/*****************************************************************************/
static void test_all_pwm( // test new PWM data against all previous PWM data
	CHECK_TST_TYP &chk_data_s, // Reference to structure containing test check data
	PWM_LINE_TYP &line_s // Reference to a structure containing wave data for one PWM-leg
)
{
	// test new PWM data against PWM data for phase under test
	test_pwm_phase( chk_data_s ,line_s );
} // test_all_pwm
/*****************************************************************************/
static void process_new_test_vector( // Process new test vector
	CHECK_TST_TYP &chk_data_s, // Reference to structure containing test check data
	PWM_LINE_TYP &line_s // Reference to all wave data for one motor
)
{
	int change = 0; // Clear flag indicating change in test vector detected


	// Check for change in Pulse-width
	if (chk_data_s.curr_vect.comp_state[WIDTH] != chk_data_s.prev_vect.comp_state[WIDTH])
	{
		finalise_pwm_width_test( chk_data_s ,line_s );

		initialise_pwm_width_test( chk_data_s ,line_s );

		change = 1; // Set flag indicating change in test vector detected
	} // if ((chk_data_s.curr_vect.comp_state[WIDTH] ...

	// Check for change in ADC-state
	if (chk_data_s.curr_vect.comp_state[ADC_TRIG] != chk_data_s.prev_vect.comp_state[ADC_TRIG])
	{
		change = 1; // Set flag indicating change in test vector detected
	} // if ((chk_data_s.curr_vect.comp_state[ADC_TRIG] ...

	// Check if test vector changed
	if (change)
	{
		chk_data_s.prev_vect = chk_data_s.curr_vect; // Update previous test-vector
	} // if (change)

	if (chk_data_s.print)
	{
		print_test_vector( chk_data_s.common ,chk_data_s.curr_vect ,chk_data_s.padstr1 ); // Print new test vector details
	} // if (chk_data_s.print)

} // process_new_test_vector
/*****************************************************************************/
void check_phase_data( // Checks PWM results for one phase
	CHECK_TST_TYP &chk_data_s, // Reference to structure containing test check data
	PWM_LINE_TYP &line_s, // Reference to all PWM data for one balanced-line (phase)
	streaming chanend c_hi_leg[], // Array of Channels for receiving PWM High-Leg data
	streaming chanend c_lo_leg[], // Array of Channels for receiving PWM Low-Leg data
	streaming chanend c_cap, // Channel for receiving from core that captures PWM ADC-trigger data
	streaming chanend c_gen // Channel for receiving test vectors from test generator core
)
/* PWM Events are assumed to be transmitted in the following cyclic sequence
 * 	PWM_LO_RISE --> PWM_HI_RISE --> PWM_ADC_TRIG --> PWM_HI_FALL --> PWM_LO_FALL --> PWM_LO_RISE ...
 * Actually for short pulse-widths the ADC-trigger may be received earlier. 
 * However this does NOT effect this test schedule.
 */
{
	PWM_CAPTURE_TYP hi_bufs[NUM_INP_BUFS]; // Set of buffers for capturing High-leg PWM data
	PWM_CAPTURE_TYP lo_bufs[NUM_INP_BUFS]; // Set of buffers for capturing Low-leg PWM data
	PWM_CAPTURE_TYP adc_bufs[NUM_INP_BUFS]; // Set of buffers for capturing ADC-trigger PWM data
	int do_loop = 1;   // Flag set until loop-end condition found 

	int hi_inp_cnt = 0; // No of High-leg inputs
	int lo_inp_cnt = 0; // No of Low-leg inputs
	int adc_inp_cnt = 0; // No of ADC-trig inputs
	int hi_read_cnt = 0; // No of High-leg buffer reads
	int lo_read_cnt = 0; // No of Low-leg buffer reads
	int adc_read_cnt = 0; // No of ADC-trig buffer reads
	unsigned hi_write_off = 0; // High-leg buffer write offset
	unsigned lo_write_off = 0; // Low-leg buffer write offset
	unsigned adc_write_off = 0; // ADC-trig buffer write offset
	unsigned hi_read_off = 0; // High-leg buffer read offset
	unsigned lo_read_off = 0; // Low-leg buffer read offset
	unsigned adc_read_off = 0; // ADC-trig buffer read offset
	unsigned hi_chan_off = 0; // High-leg channel offset
	unsigned lo_chan_off = 0; // Low-leg channel offset


	acquire_lock(); // Acquire Display Mutex
	printstr( chk_data_s.padstr1 );
	printstr("Start Checks For Phase_"); 
	printcharln( ('A' + chk_data_s.phase_id) );
	release_lock(); // Release Display Mutex

	// Send Phase option to capture cores
	c_hi_leg[0] <: chk_data_s.phase_id;
	c_lo_leg[0] <: chk_data_s.phase_id;

	c_gen :> chk_data_s.curr_vect; // Initialise test-vector structure with 1st test

	init_phase_data( chk_data_s ); // Initialise check data

	// special case: initialisation for first test
  chk_data_s.prev_vect = chk_data_s.curr_vect;

	if (chk_data_s.print)
	{
		print_test_vector( chk_data_s.common ,chk_data_s.curr_vect ,chk_data_s.padstr1 ); // Print new test vector details
	} // if (chk_data_s.print)

	initialise_pwm_width_test( chk_data_s ,line_s ); 

	while (do_loop) {
		select {
			// Service any new PWM data on High-Leg input channel
			case c_hi_leg[hi_chan_off] :> hi_bufs[hi_write_off].port_data :
				hi_bufs[hi_write_off].id = PWM_HI_LEG;

				// Update circular buffer offsets
				hi_inp_cnt++; // Increment write counter
				hi_write_off = (((unsigned)hi_inp_cnt) & INP_BUF_MASK); // Wrap offset into range [0..INP_BUF_MASK];
				hi_chan_off = (((unsigned)hi_inp_cnt) & CHAN_MASK); // Wrap offset into range [0..CHAN_MASK];
			break;

			// Service any new PWM data on Low-Leg input channel
			case c_lo_leg[lo_chan_off] :> lo_bufs[lo_write_off].port_data :
				lo_bufs[lo_write_off].id = PWM_LO_LEG;

				// Update circular buffer offsets
				lo_inp_cnt++; // Increment write counter
				lo_write_off = (((unsigned)lo_inp_cnt) & INP_BUF_MASK); // Wrap offset into range [0..INP_BUF_MASK];
				lo_chan_off = (((unsigned)lo_inp_cnt) & CHAN_MASK); // Wrap offset into range [0..CHAN_MASK];
			break;

			// Service any new PWM data on ADC input channel
			case c_cap :> adc_bufs[adc_write_off].port_data.time_off :
				adc_bufs[adc_write_off].id = ADC_PATN;

				// Update circular buffer offsets
				adc_inp_cnt++; // Increment write counter
				adc_write_off = (((unsigned)adc_inp_cnt) & INP_BUF_MASK); // Wrap offset into range [0..INP_BUF_MASK];
			break;

			// Service any change on test channel
			case c_gen :> chk_data_s.curr_vect :
				// New test vector detected.
				process_new_test_vector( chk_data_s ,line_s ); // Process new test vector

				// Check if testing has ended for current motor
				if (QUIT == chk_data_s.curr_vect.comp_state[CNTRL])
				{
					do_loop = 0; // Error flag signals end-of-loop
				} // if (QUIT == chk_data_s.curr_vect.comp_state[CNTRL])
			break; // c_gen 

			default:
				// Ensure received events are checked in same order they were transmitted ...

				// Check which PWM event is expected
				switch(chk_data_s.event)
				{
					case PWM_LO_RISE : case PWM_LO_FALL : // Low-leg Channel
						// Check if any new data to read
						if (lo_inp_cnt > lo_read_cnt)
						{
							assert(lo_inp_cnt <= (lo_read_cnt + NUM_INP_BUFS)); // Check we have enough input buffers
							line_s.waves[PWM_LO_LEG].curr_data.port_data = lo_bufs[lo_read_off].port_data; // Update High-Leg PWM data

							chk_data_s.curr_leg = PWM_LO_LEG; // Set PWM-leg under test
							test_all_pwm( chk_data_s ,line_s ); // test new PWM data

							// Update circular buffer offset
							lo_read_cnt++; // Increment write counter
							lo_read_off = (((unsigned)lo_read_cnt) & INP_BUF_MASK); // Wrap offset into range [0..INP_BUF_MASK];
						} // if (lo_inp_cnt > lo_read_cnt)
					break; // case PWM_LO_RISE
					
					case PWM_HI_RISE : case PWM_HI_FALL : // High-leg channel
						// Check if any new data to read
						if (hi_inp_cnt > hi_read_cnt)
						{
							assert(hi_inp_cnt <= (hi_read_cnt + NUM_INP_BUFS)); // Check we have enough input buffers
							line_s.waves[PWM_HI_LEG].curr_data.port_data = hi_bufs[hi_read_off].port_data; // Update High-Leg PWM data

							chk_data_s.curr_leg = PWM_HI_LEG; // Set PWM-leg under test
							test_all_pwm( chk_data_s ,line_s ); // test new PWM data

							// Update circular buffer offset
							hi_read_cnt++; // Increment write counter
							hi_read_off = (((unsigned)hi_read_cnt) & INP_BUF_MASK); // Wrap offset into range [0..INP_BUF_MASK];
						} // if (hi_inp_cnt > hi_read_cnt)
					break; // case PWM_HI_RISE
					
					case PWM_ADC_TRIG : // ADC-trigger
						// Check if any new data to read
						if (adc_inp_cnt >adc_read_cnt)
						{
							assert(adc_inp_cnt <= (adc_read_cnt + NUM_INP_BUFS)); // Check we have enough input buffers
							chk_data_s.adc_time = adc_bufs[adc_read_off].port_data.time_off; // Update ADC trigger time

							// Update circular buffer offset
							adc_read_cnt++; // Increment write counter
							adc_read_off = (((unsigned)adc_read_cnt) & INP_BUF_MASK); // Wrap offset into range [0..INP_BUF_MASK];

							chk_data_s.event = PWM_HI_FALL; // set next event
						} // if (adc_inp_cnt >adc_cap_read_cnt)
					break; // case PWM_ADC_TRIG

					default :
						assert( 0 == 1); // Unknown PWM event found
					break; // default
				} // switch(cur_event)
			break; // default
		} // select
	}	// while (do_loop)

	// special case: finalisation for last pulse-width test
	finalise_pwm_width_test( chk_data_s ,line_s ); 

} // check_phase_data
/*****************************************************************************/
static void display_test_results( // Display results for one PWM phase
	CHECK_TST_TYP &chk_data_s // Reference to structure containing test check data
)
{
	int comp_cnt; // Counter for Test Vector components
	int check_errs = 0;   // Preset flag to NO check errors for current PWM phase
	int num_checks = 0;   // Clear check counter for current PWM phase
	int test_errs = 0;   // Preset flag to NO test errors for current PWM phase
	int num_tests = 0;   // Clear test counter for current PWM phase


	// Update error statistics for current PWM phase
	for (comp_cnt=1; comp_cnt<NUM_VECT_COMPS; comp_cnt++)
	{
		// Check if any micro-tests where done for current test vector component
		if (0 < chk_data_s.phase_tsts[comp_cnt])
		{
			num_tests++; // Update macro-test counter
			num_checks += chk_data_s.phase_tsts[comp_cnt]; 

			// Check if any micro-errors where detected for current test vector component
			if (0 < chk_data_s.phase_errs[comp_cnt])
			{
				test_errs++; // Update macro-error counter
				check_errs += chk_data_s.phase_errs[comp_cnt]; 
			} // if (0 < chk_data_s.phase_errs[comp_cnt])
		} // if (0 < chk_data_s.phase_tsts[comp_cnt])
	} // for comp_cnt

	acquire_lock(); // Acquire Display Mutex
	printstrln("");
	printstr( chk_data_s.padstr1 );
	printint( num_tests );
	printstr( " Tests run" );

	// Check for verbose test output
	if (1 == MICRO_TESTS)
	{
		printstr(" (Comprising ");
		printint( num_checks );
		printstr( " checks)" );
	} // if (1 == MICRO_TESTS)

	printstrln("");

	// Check if this PWM phase had any errors
	if (test_errs)
	{
		printstr( chk_data_s.padstr1 );
		printint( test_errs );
		printstrln( " Tests FAILED, as follows:" );

		// Print Vector Component Names
		for (comp_cnt=1; comp_cnt<NUM_VECT_COMPS; comp_cnt++)
		{
			// Check if any test run for this component
			if (chk_data_s.phase_tsts[comp_cnt])
			{
				printstr( chk_data_s.padstr1 );
				printstr( chk_data_s.common.comp_data[comp_cnt].comp_name.str );
	
				if (chk_data_s.phase_errs[comp_cnt])
				{
					printstr(" Test FAILED");

					// Check for verbose test output
					if (1 == MICRO_TESTS)
					{
						printstr(" (");
						printint( chk_data_s.phase_errs[comp_cnt] );
						printstr( " out of " );
						printint( chk_data_s.phase_tsts[comp_cnt] );
						printstr( " checks failed)" );
					} // if (1 == MICRO_TESTS)
				} // if (chk_data_s.phase_errs[comp_cnt])
				else
				{
					printstr(" Test Passed");

					// Check for verbose test output
					if (1 == MICRO_TESTS)
					{
						printstr(" (");
						printint( chk_data_s.phase_tsts[comp_cnt] );
						printstr( " checks run)" );
					} // if (1 == MICRO_TESTS)
				} // if (chk_data_s.phase_errs[comp_cnt])

				printstrln("");

			} // if (chk_data_s.phase_tsts[comp_cnt])
		} // for comp_cnt
	} // if (check_errs)
	else
	{
		printstr( chk_data_s.padstr1 );
		printstr( "All Phase_" );
		printchar( ('A' + chk_data_s.phase_id) );
 		printstrln( " Tests Passed" );
	} // else !(check_errs)

	printstrln("");
	release_lock(); // Release Display Mutex

} // display_test_results
/*****************************************************************************/
void check_pwm_server_data( // Checks PWM results
	streaming chanend c_hi_leg[], // Array of Channels for receiving PWM High-Leg data
	streaming chanend c_lo_leg[], // Array of Channels for receiving PWM Low-Leg data
	streaming chanend c_cap, // Channel for receiving from core that captures PWM ADC-trigger data
	streaming chanend c_gen // Channel for receiving test vectors from test generator core
)
/* PWM Events are assumed to be transmitted in the following cyclic sequence
 * 	PWM_LO_RISE --> PWM_HI_RISE --> PWM_ADC_TRIG --> PWM_HI_FALL --> PWM_LO_FALL --> PWM_LO_RISE ...
 * Actually for short pulse-widths the ADC-trigger may be received earlier. 
 * However this does NOT effect this test schedule.
 */
{
	CHECK_TST_TYP chk_data_s; // Structure containing test check data
	PWM_LINE_TYP line_s; // All PWM data for one balanced-line (phase)


	c_gen :> chk_data_s.common.options; // Get test options from generator core
	chk_data_s.phase_id = chk_data_s.common.options.flags[TST_PHASE];

	init_check_data( chk_data_s ); // Initialise check data

	check_phase_data( chk_data_s ,line_s ,c_hi_leg ,c_lo_leg ,c_cap ,c_gen ); // Check results for one PWM phase

	display_test_results( chk_data_s );

	acquire_lock(); // Acquire Display Mutex
	printstr( chk_data_s.padstr1 );
	printstrln( "Test Check Ends " );
	release_lock(); // Release Display Mutex

	c_gen <: PWM_TERMINATED; // Signal to Generator that Checker has terminated
} // check_pwm_server_data
/*****************************************************************************/
