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

#ifndef _CAPTURE_PWM_DATA_H_
#define _CAPTURE_PWM_DATA_H_

#include <stdlib.h>

#include <xs1.h>
#include <assert.h>
#include <print.h>
#include <safestring.h>

#include "app_global.h"
#include "use_locks.h"
#include "test_pwm_common.h"

/** Define number of channels in bits */
#define CHAN_BITS 2 // No. of channels in bits, NB Can probably use 1, but sailing close to the wind
#define NUM_CHANS (1 << CHAN_BITS) // No. of channel 
#define CHAN_MASK (NUM_CHANS - 1) // Bit-mask used to wrap channel offset

#define RESYNC_LIMIT 3 // No. of re-synchronisations allowed

/*****************************************************************************/
/** // Configure all ports to use the same clock
 * \param p32_tst_hi, // array of PWM ports (High side)  
 * \param p32_tst_lo, // array of PWM ports (Low side)   
 * \param p8_tst_sync, // NB Dummy output port
 * \param comm_clk, // Common clock for all test ports
 */
void config_all_ports( // Configure all ports to use the same clock
	buffered in port:32 p32_tst_hi[], // array of PWM ports for PWM High-leg
	buffered in port:32 p32_tst_lo[], // array of PWM ports for PWM Low-leg
	out port p8_tst_sync, // NB Dummy output port
	clock comm_clk // Common clock for all test ports
);
/*****************************************************************************/
/** Captures PWM data from PWM-to-ADC trigger channel
 * \param p8_tst_sync, // NB Dummy output port
 * \param c_trigger // PWM-to-ADC trigger channel 
 * \param c_chk // Channel for transmitting trigger data to test checker
 */
void capture_pwm_trigger_data( // Captures PWM to ADC trigger data
	out port p8_tst_sync, // NB Dummy output port
	chanend c_trigger, // PWM-to-ADC trigger channel from PWM server 
	streaming chanend c_chk // Channel for transmitting trigger data to test checker
);
/*****************************************************************************/
/** Captures PWM data from input pins for one PWM-leg
 * \param p32_leg, // array of PWM ports for one PWM-leg
 * \param comm_clk, // Common clock for all test ports
 * \param c_chk[] // Array of channels for sending PWM data to test checker
 * \param leg_id // PWM-leg identifier
 */
void capture_pwm_leg_data( // Captures PWM data results for one leg
	buffered in port:32 p32_leg[], // array of PWM ports for one PWM-leg
	streaming chanend c_chk[], // Array of channel for transmitting PWM data to test checker
	PWM_LEG_ENUM leg_id // PWM-leg identifier
	);
/*****************************************************************************/
#endif /* _CAPTURE_PWM_DATA_H_ */
