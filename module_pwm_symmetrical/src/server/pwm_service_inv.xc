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
		buf_id = pwm_op_inv( buf_id, p32_pwm_hi, p32_pwm_lo, c_pwm, mem_addr, c_adc_trig, p16_adc_sync );
#else //if LOCK_ADC_TO_PWM
		buf_id = pwm_op_inv( buf_id ,p32_pwm_hi ,p32_pwm_lo ,c_pwm ,mem_addr ,null ,null );
#endif  //else !LOCK_ADC_TO_PWM
	} // while(1)

} // do_pwm_inv_triggered 
/*****************************************************************************/
// pwm_service_inv
