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

#include "main.h"

// PWM Output ports
on tile[MOTOR_TILE]: buffered out port:32 pb32_pwm_hi[NUM_PWM_PHASES] = {PORT_M1_HI_A, PORT_M1_HI_B, PORT_M1_HI_C};
on tile[MOTOR_TILE]: buffered out port:32 pb32_pwm_lo[NUM_PWM_PHASES] = {PORT_M1_LO_A, PORT_M1_LO_B, PORT_M1_LO_C};
on tile[MOTOR_TILE]: clock pwm_clk= XS1_CLKBLK_5;
on tile[MOTOR_TILE]: in port p16_adc_sync = XS1_PORT_16A; // NB Dummy input port

// Test/Check Input ports
on tile[MOTOR_TILE]: buffered in port:32 pb32_tst_hi[NUM_PWM_PHASES]	= {PORT_M2_HI_A, PORT_M2_HI_B, PORT_M2_HI_C};
on tile[MOTOR_TILE]: buffered in port:32 pb32_tst_lo[NUM_PWM_PHASES]	= {PORT_M2_LO_A, PORT_M2_LO_B, PORT_M2_LO_C};
on tile[MOTOR_TILE]: out port p8_tst_sync = XS1_PORT_8C; // NB Dummy output port

// Test/Check Clocks
on tile[MOTOR_TILE]: clock comm_clk = XS1_CLKBLK_1; // Common clock for all test ports

#if (USE_XSCOPE)
/*****************************************************************************/
void xscope_user_init()
{
	xscope_register( 3
		,XSCOPE_CONTINUOUS, "PWM_A", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "PWM_B", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "PWM_C", XSCOPE_INT , "n"
	); // xscope_register 
} // xscope_user_init
/*****************************************************************************/
#endif // (USE_XSCOPE)

/*****************************************************************************/
int main ( void ) // Program Entry Point
{
	chan c_pwm2adc_trig;
	chan c_gen_pwm; // Channel for sending test data from Generator core to PWM Server core
	streaming chan c_gen_chk; // Channel for sending test vectors from Generator to Checker core
	streaming chan c_cap_chk; // Channel for sending PWM-to-ADC trigger data from Capture to Checker core
	streaming chan c_hi_leg[NUM_CHANS]; // Array of channels for sending PWM Hi-Leg data from Capture to Checker core
	streaming chan c_lo_leg[NUM_CHANS]; // Array of channels for sending PWM Lo-Leg data from Capture to Checker core


	par
	{	// NB All cores are run on one tile so that all cores use the same clock frequency (100 MHz)
		on tile[MOTOR_TILE] : 
		{
		  init_locks(); // Initialise Mutex for display

			config_all_ports( pb32_tst_hi ,pb32_tst_lo ,p8_tst_sync ,comm_clk );

			par
			{
				gen_all_pwm_test_data( c_gen_chk ,c_gen_pwm ); // Generate test data using PWM Client
		
				// Server function under test
				foc_pwm_do_triggered( MOTOR_ID, c_gen_pwm ,pb32_pwm_hi ,pb32_pwm_lo ,c_pwm2adc_trig ,p16_adc_sync ,pwm_clk );
		
				capture_pwm_leg_data( pb32_tst_hi ,c_hi_leg ,PWM_HI_LEG ); // Capture PWM Hi-Leg data

				capture_pwm_leg_data( pb32_tst_lo ,c_lo_leg ,PWM_LO_LEG ); // Capture PWM Lo-Leg data

				capture_pwm_trigger_data( p8_tst_sync ,c_pwm2adc_trig ,c_cap_chk ); // Capture PWM ADC-trigger data

				check_pwm_server_data( c_hi_leg ,c_lo_leg ,c_cap_chk ,c_gen_chk ); // Check results
			} // par
		
		  free_locks(); // Free Mutex for display
		} // on tile[MOTOR_TILE] : 
	} // par 

	return 0;
} // main
/*****************************************************************************/
// main.xc
