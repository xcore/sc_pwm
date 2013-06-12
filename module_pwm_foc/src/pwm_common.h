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

// #include "use_locks.h" //MB~ Dbg

#ifndef PWM_SHARED_MEM 
	#error Define. PWM_SHARED_MEM in app_global.h
#endif // PWM_SHARED_MEM

/** Define Number of buffers in storage ring */
#define NUM_PWM_BUFS 2  // Double-buffered

/** Define PWM port width in bits */
#define PWM_PORT_WID 32 // PWM port width in bits

#define PWM_MS_MASK ((unsigned)(1 << (PWM_PORT_WID - 1))) // Mask for MS-bit of PWM pattern (e.g. 0x8000_0000)
#define PWM_ONES_PATN ((unsigned)(PWM_MS_MASK + (PWM_MS_MASK - 1))) // All-ones PWM pattern (e.g. 0xFFFF_FFFF)

/** Different PWM Phases */
typedef enum PWM_PHASE_ETAG
{
  PWM_PHASE_A = 0,  // 1st Phase
  PWM_PHASE_B,		  // 2nd Phase
  PWM_PHASE_C,		  // 3rd Phase
  NUM_PWM_PHASES    // Handy Value!-)
} PWM_PHASE_ENUM;

/** Enumeration of PWM-Leg States */
typedef enum PWM_LEG_ETAG
{
  PWM_HI_LEG = 0,	// Positive-leg of PWM
  PWM_LO_LEG,			// Negative-leg of PWM
  NUM_PWM_LEGS	// Handy Value!-)
} PWM_LEG_ENUM;

/** Type for Port timer values */
typedef unsigned short PORT_TIME_TYP;

/** Structure containing PWM parameters for one motor */
typedef struct PWM_PARAM_TAG // 
{
	unsigned widths[NUM_PWM_PHASES]; // Array of PWM width values
	unsigned id; // Unique Motor identifier e.g. 0 or 1
} PWM_PARAM_TYP;

/** Structure containing pwm communication control data */
typedef struct PWM_COMMS_TAG
{
	PWM_PARAM_TYP params; // Structure of PWM parameters (for Server)
	unsigned buf; 	// double-buffer identifier (0 or 1)
	unsigned mem_addr; // Shared memory address (if used)
} PWM_COMMS_TYP;

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
typedef struct PWM_ARRAY_TAG
{
	PWM_BUFFER_TYP buf_data[NUM_PWM_BUFS]; // Array of buffer-data structures, one for each buffer
} PWM_ARRAY_TYP;

#endif // _PWM_COMMON_H_
