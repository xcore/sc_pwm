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

#ifndef _CHECK_PWM_TESTS_H_
#define _CHECK_PWM_TESTS_H_

#include <xs1.h>
#include <assert.h>
#include <print.h>
#include <safestring.h>

#include "app_global.h"
#include "use_locks.h"
#include "capture_pwm_data.h"
#include "test_pwm_common.h"

/** Define Input buffer size in bits */
#define INP_BUF_BITS 8 // 6 NB This may need to be increased if extra printed output added to checker

/** Define minimum Dead-time limit */
#define DEAD_ERR_LIM	(HALF_DEAD_TIME - HALF_PORT_WID) // Minimum allowed time between High-leg/Low-leg edges

#define NUM_INP_BUFS (1 << INP_BUF_BITS) // No. of input buffers used for storing PWM widths, NB Can probably use 4, but sailing cloase to the wind
#define INP_BUF_MASK (NUM_INP_BUFS - 1) // Bit-mask used to wrap input buffer offset

#define PWM_MASK (PWM_MAX_VALUE - 1) // Used to force into range [0..PWM_MASK]

#define ADC_DELAY 8 // Fudge-Factor: delay between receiving ADC-trigger from channel and outputting to dummy port

/** Class of PWM events */
typedef enum PWM_EVENT_ETAG
{
  PWM_LO_RISE = 0,	// Low-leg rising edge
  PWM_HI_RISE,			// High-leg rising edge
  PWM_ADC_TRIG,			// ADC-trigger event
  PWM_HI_FALL,			// High-leg falling edge 
  PWM_LO_FALL,			// Low-leg falling edge 
  NUM_PWM_EVENTS    // Handy Value!-)
} PWM_EVENT_ENUM;

/** Type containing data for one pulse sample */
typedef struct PWM_SAMP_TAG // Structure containing data for one PWM sample
{
	PWM_PORT_TYP port_data; // PWM port data
	unsigned first; // first pattern bit received (LS bit)
	unsigned last; // last pattern bit received (MS bit)
} PWM_SAMP_TYP;

/** Type containing data for one PWM-leg */
typedef struct PWM_WAVE_TAG // Structure containing data for one PWM Wave
{
	PWM_SAMP_TYP curr_data; // data for current PWM sample 
	PWM_SAMP_TYP prev_data; // data for previous PWM sample
	int meas_wid;	// measured PWM width
	unsigned time_sum; // Time accumulated during pulse
	unsigned hi_wid; // Measure width of High(one) portion of pulse 
	unsigned lo_wid; // Measure width of Low(zero) portion of pulse 
	int hi_sum;	// sum of high-times
	int lo_sum;	// sum of low-times
	int hi_num;	// No. of high-times
	int lo_num;	// No. of high-times
	int new_edge;	// Flag set when new edge found
	PORT_TIME_TYP rise_time; // Time-stamp of rising edge
	PORT_TIME_TYP fall_time; // Time-stamp of falling edge
} PWM_WAVE_TYP;

/** Type containing data for a balanced line (pair of PWM wave trains) */
typedef struct PWM_LINE_TAG
{
	PWM_WAVE_TYP waves[NUM_PWM_LEGS]; // Array of structures containing PWM wave data for each leg of a balanced line
} PWM_LINE_TYP;

/** Type containing all check data */
typedef struct CHECK_TST_TAG // Structure containing PWM check data
{
	COMMON_PWM_TYP common; // Structure of PWM data common to Generator and Checker
	char padstr1[STR_LEN]; // Padding string used to format display output
	char padstr2[STR_LEN]; // Padding string used to format display output
	TEST_VECT_TYP curr_vect; // Structure of containing current PWM test vector (PWM conditions to be tested)
	TEST_VECT_TYP prev_vect; // Structure of containing previous PWM test vector
	int phase_errs[NUM_VECT_COMPS]; // Array of error counters for one phase
	int phase_tsts[NUM_VECT_COMPS]; // Array of test counters for one phase
	PWM_PHASE_ENUM phase_id; // Identifier of phase being tested
	PWM_EVENT_ENUM event; // Current PWM event being processed
	PWM_LEG_ENUM curr_leg; // Current PWM-leg under test
	PWM_LEG_ENUM prev_leg; // Previous PWM-leg under test
	PORT_TIME_TYP adc_time; // port_time when ADC trigger received
	int bound; // error bound for PWM-width measurement
	int print;  // Print flag
	int dbg;  // Debug flag
} CHECK_TST_TYP;

/*****************************************************************************/
/** Check PWM results 
 * \param c_hi_leg[], // Array of Channels for receiving PWM High-Leg data
 * \param c_lo_leg[], // Array of Channels for receiving PWM Low-Leg data
 * \param c_adc, // Channel for receiving PWM ADC-trigger data
 * \param c_tst // Channel for sending test vecotrs to test checker
 */
void check_pwm_server_data( // Checks PWM results for all motors
	streaming chanend c_hi_leg[], // Array of Channels for receiving PWM High-Leg data
	streaming chanend c_lo_leg[], // Array of Channels for receiving PWM Low-Leg data
	streaming chanend c_adc, // Channel for receiving PWM ADC-trigger data
	streaming chanend c_tst // Channel for receiving test vectors from test generator
);
/*****************************************************************************/
#endif /* _CHECK_PWM_TESTS_H_ */
