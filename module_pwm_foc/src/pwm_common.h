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
 **/                                   

#ifndef _PWM_COMMON_H_
#define _PWM_COMMON_H_

#ifndef PWM_SHARED_MEM 
	#error Define. PWM_SHARED_MEM in app_global.h
#endif // PWM_SHARED_MEM

/** Different PWM Phases */
typedef enum PWM_PHASE_ETAG
{
  PWM_PHASE_A = 0,  // 1st Phase
  PWM_PHASE_B,		  // 2nd Phase
  PWM_PHASE_C,		  // 3rd Phase
  NUM_PWM_PHASES    // Handy Value!-)
} PWM_PHASE_ENUM;

#define NUM_PWM_BUFS 2  // Double-buffered

/** Structure containing PWM parameters for one motor */
typedef struct PWM_PARAM_TAG // 
{
	unsigned widths[NUM_PWM_PHASES]; // Array of PWM width values
	unsigned id; // Unique Motor identifier e.g. 0 or 1
	unsigned buf; 	// double-buffer identifier (0 or 1)
	unsigned mem_addr; // Shared memory address (if used)
} PWM_PARAM_TYP;

// Structure containing data for doing timed load of buffered output port
typedef struct PWM_PORT_TAG
{
	unsigned pattern;		// Bit-pattern written to port (used to define pulse edge)
	signed time_off;	// time-offset to start of pattern
} PWM_PORT_TYP;

// Structure containing pwm output data for one phase (& one edge)
typedef struct PWM_PHASE_TAG // Structure containing string
{
	PWM_PORT_TYP hi; // Port data for high leg (V+) of balanced line
	PWM_PORT_TYP lo; // Port data for low leg (V-) of balanced line
} PWM_PHASE_TYP;

// Structure containing data for one pulse edge for all phases
typedef struct PWM_EDGE_TAG
{
	PWM_PHASE_TYP phase_data[NUM_PWM_PHASES]; // Array of phase-data structures, one for each phase
} PWM_EDGE_TYP;

// Structure containing pwm output data for one buffer
typedef struct PWM_BUFFER_TAG
{
	PWM_EDGE_TYP rise_edg; // data structure for rising edge of all pulses
	PWM_EDGE_TYP fall_edg; // data structure for falling edge of all pulses
} PWM_BUFFER_TYP;

// Structure containing pwm output data for all buffers
typedef struct PWM_CONTROL_TAG
{
	PWM_BUFFER_TYP buf_data[NUM_PWM_BUFS]; // Array of buffer-data structures, one for each buffer
} PWM_CONTROL_TYP;

#endif // _PWM_COMMON_H_
