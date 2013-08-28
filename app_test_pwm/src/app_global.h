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
#ifndef _APP_GLOBAL_H_
#define _APP_GLOBAL_H_

/** Define this to include XSCOPE support */
#define USE_XSCOPE 1

#if (USE_XSCOPE)
#include <xscope.h>
#endif // (USE_XSCOPE)

/** Define this to switch on error checks */
#define CHECK_ERRORS 1

/** Define Motor Identifier (0 or 1) */
#define MOTOR_ID 1

/** Define the number of pole-pairs in motor */
#define NUM_POLE_PAIRS 4

/** Define seconds in a minute */
#define SECS_PER_MIN 60

/** Define Maximum specified motor speed. WARNING: Safety critical */
#define MAX_SPEC_RPM 4000

/** Define flag for verbose printing */
#define VERBOSE_PRINT 0

/** Define flag for printing Micro-test info. */
#define MICRO_TESTS 0

/** Print width - fix for non-wrapped output in xTIMEcomposer */
#define PRINT_WID 72

// PWM specific definitions ...

/** Define the resolution of PWM (WARNING: effects update rate as tied to ref clock) */
#define PWM_RES_BITS 12 // Number of bits used to define number of different PWM pulse-widths
#define PWM_MAX_VALUE (1 << PWM_RES_BITS) // No.of different PWM pulse-widths
#define QUART_PWM_MAX (PWM_MAX_VALUE >> 2)  // Quarter of maximum PWM width value

// If locked, the ADC sampling will occur in the middle of the  switching sequence.
// It is triggered over a channel. Set this define to 0 to disable this feature
/** Define sync. mode for ADC sampling. Default 1 is 'ADC synchronised to PWM' */
#define LOCK_ADC_TO_PWM 1

/** Define if Shared Memory is used to transfer PWM data from Client to Server */
#define PWM_SHARED_MEM 0 // 0: Use c_pwm channel for pwm data transfer

/* This is a bit of a cludge, we are using a non-standard configuration
 * where the timer on the tile for inner_loop() is running at 250 MHz,
 * but other timers are running at the default of 100 MHz.
 * Currently this flexibility to define timer frequencies for each tile does not exist.
 * Therefore, we set up the timer frequency here.
 */
#ifndef PLATFORM_REFERENCE_MHZ
#define PLATFORM_REFERENCE_MHZ 100
#define PLATFORM_REFERENCE_KHZ (1000 * PLATFORM_REFERENCE_MHZ) 

/** Define Referency Frequency to Match that in platform configuration (.XN) file */
#define PLATFORM_REFERENCE_HZ  (1000 * PLATFORM_REFERENCE_KHZ) // NB Uses 28-bits
#endif

#define SECOND PLATFORM_REFERENCE_HZ // One Second in Clock ticks
#define MILLI_SEC (PLATFORM_REFERENCE_KHZ) // One milli-second in clock ticks
#define MICRO_SEC (PLATFORM_REFERENCE_MHZ) // One micro-second in clock ticks

#endif /* _APP_GLOBAL_H_ */
