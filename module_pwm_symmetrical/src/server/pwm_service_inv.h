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
#include "pwm_common.h"
#include "pwm_service.h"


/** \brief Implementation of the centre aligned inverted pair PWM server, with ADC synchronization
 *
 *  This server includes a port which triggers the ADC measurement
 *
 *  \param c_pwm the control channel for setting PWM values
 *  \param p32_pwm_hi the array of PWM ports (HI side)
 *  \param p32_pwm_lo the array of PWM ports (LO side)
 *  \param c_adc_trig the control channel for triggering the ADC
 *  \param p16_adc_sync a dummy port used for precise timing of the ADC trigger
 *  \param pwm_clk a clock for generating accurate PWM timing
 */
void do_pwm_inv_triggered( 
	unsigned motor_id, // Motor identifier
	chanend c_pwm, 
	buffered out port:32 p32_pwm_hi[],  
	buffered out port:32 p32_pwm_lo[], 
	chanend? c_adc_trig, // Optional ADC trigger channel 
	in port? p16_adc_sync, // Optional ADC trigger channel  
	clock pwm_clk
);

