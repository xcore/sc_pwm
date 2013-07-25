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

#ifndef _TEST_PWM_COMMON_H_
#define _TEST_PWM_COMMON_H_

#include <xs1.h>
#include <assert.h>
#include <print.h>
#include <safestring.h>

#include "use_locks.h"
#include "app_global.h"
#include "pwm_common.h"

/** Define string size */
#define STR_LEN 256

/** Define samll PWM width resolution */
#define SMALL_RES_BITS ((PORT_RES_BITS + PWM_RES_BITS - 1) >> 1) // NB Geometric mean of MINI and EQUAL widths

/** Define value for Minimum Speed test */
#define MINI_PWM PWM_PORT_WID

/** Define value for Low Speed test */
#define SMALL_PWM (1 << SMALL_RES_BITS)

/** Define value for Medium Speed test */
#define EQUAL_PWM (PWM_MAX_VALUE >> 1) 

/** Define value for High Speed test */
#define LARGE_PWM (PWM_MAX_VALUE - SMALL_PWM)

/** Define value for Maximum Speed test */
#define MAXI_PWM (PWM_WID_LIMIT - 1)

/** Define ADC Pattern - Must NOT be equivalent to a PWM pattern */
#define ADC_PATN 0xAA // ADC Pattern - Must NOT be equivalent to a PWM pattern

/** Enumeration of PWM Test Options */
typedef enum PWM_TEST_ETAG
{
  TST_PHASE = 0,	// Select which PWM Phase to test
  TST_NARROW,			// Test Narrow PWM Widths
  TST_EQUAL,			// Test Equal PWM Widths
  TST_ADC,				// Test ADC Trigger
  NUM_TEST_OPTS		// Handy Value!-)
} PWM_TEST_ENUM;

/** Enumeration of PWM Test Vector Components */
typedef enum VECT_COMP_ETAG
{
  CNTRL = 0,	// Special Case: Control/Comunications state
  WIDTH,			// PWM Width-state
	LEG,				// PWM-Leg
  ADC_TRIG,		// ADC Trigger
	DEAD,				// Dead-Time
  NUM_VECT_COMPS	// Handy Value!-)
} VECT_COMP_ENUM;

/** Enumeration of PWM Width-states */
typedef enum WIDTH_PWM_ETAG
{
  MINI = 0,	// Minimum PWM width (for Slowest Speed)
  SMALL,		// Small PWM width (for Slow Speed)
  EQUAL,		// Equal High and Low PWM (for Medium Speed)
  LARGE,		// Large PWM width (for Fast Speed)
  MAXI,			// Maximum PWM width (for Fastest Speed)
  NUM_PWM_WIDTHS	// Handy Value!-)
} WIDTH_PWM_ENUM;

/** Enumeration of PWM ADC-trigger states */
typedef enum ADC_PWM_ETAG
{
  NO_ADC = 0,	// ADC-trigger not tested
  ADC_ON,		// ADC-trigger is tested
  NUM_PWM_ADCS	// Handy Value!-)
} ADC_PWM_ENUM;

/** Enumeration of PWM Dead-Time states */
typedef enum DEAD_PWM_ETAG
{
  NO_DEAD = 0,	// Dead-Time not tested
  DEAD_ON,		// Dead-Time is tested
  NUM_PWM_DEADS	// Handy Value!-)
} DEAD_PWM_ENUM;

/** Enumeration of PWM Control-states */
typedef enum CNTRL_PWM_ETAG
{
	QUIT = 0,	// Quit testing (for current motor)
  VALID,		// Valid test
  SKIP,			// Skip this test (test set-up)
  NUM_PWM_CNTRLS	// Handy Value!-)
} CNTRL_PWM_ENUM;

// NB Enumeration of PWM Phase-states in sc_pwm/module_foc_pwm/src/pwm_common.h

/** Define maximum number of states for any test vector component (used to size arrays) */
#define MAX_COMP_STATES NUM_PWM_WIDTHS	// Edit this line

/** Type containing string */
typedef struct STRING_TAG // Structure containing string array
{
	char str[STR_LEN]; // String array (NB Structure allows easy string copy)
} STRING_TYP;

/** Type containing Test Vector */
typedef struct TEST_VECT_TAG // Structure containing test vector (PWM conditions to be tested)
{
	int comp_state[NUM_VECT_COMPS]; // array containing current states for each test vector component 
} TEST_VECT_TYP;

/** Type containing Meta-information for one Test Vector */
typedef struct VECT_COMP_TAG // Structure containing common PWM test data for one test vector component
{
	STRING_TYP state_names[MAX_COMP_STATES]; // Array of names for each state of this test vector component 
	STRING_TYP comp_name; // name for this test vector component
	int num_states; // number of states for this test vector component
} VECT_COMP_TYP;

/** Type containing all Test Options */
typedef struct TEST_OPTS_TAG // Structure containing all test option data
{
	int flags[NUM_TEST_OPTS]; // Array of test option flags
} TEST_OPTS_TYP;

/** Structure containing captured pwm data */
typedef struct PWM_CAPTURE_TAG
{
	PWM_PORT_TYP port_data; // PWM port data
	int id; // Identifies source for this data (Hi-Leg, Lo-leg, ADC-trigger)
} PWM_CAPTURE_TYP;

/** Type containing all Test Vector Meta-information */
typedef struct COMMON_PWM_TAG // Structure containing all common PWM test data
{
	VECT_COMP_TYP comp_data[NUM_VECT_COMPS]; // Array of data for each component of test vector
	TEST_OPTS_TYP options; // Structure of test_option data
	unsigned pwm_wids[NUM_PWM_WIDTHS]; // Array of PWM-widths for each width-state
} COMMON_PWM_TYP;

/*****************************************************************************/
/** Initialise common PWM Test data
 * \param comm_pwm_s, // Reference to structure of common PWM data
 */
void init_common_data( // Initialise common PWM Test data
	COMMON_PWM_TYP &comm_pwm_s // Reference to structure of common PWM data
);
/*****************************************************************************/
/** Print test vector details
 * \param comm_pwm_s, // Reference to structure of common PWM data
 * \param inp_vect, // Structure containing current PWM test vector to be printed
 * \param prefix_str[] // Prefix string
 */
void print_test_vector( // Print test vector details
	COMMON_PWM_TYP &comm_pwm_s, // Reference to structure of common PWM data
	TEST_VECT_TYP inp_vect, // Structure containing current PWM test vector to be printed
	const char prefix_str[] // prefix string
);
/*****************************************************************************/
#endif /* _TEST_PWM_COMMON_H_ */
