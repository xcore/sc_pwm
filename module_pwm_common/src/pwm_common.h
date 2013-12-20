/*
 *
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
#ifndef __PWM_COMMON_H_
#define __PWM_COMMON_H_

#ifdef __pwm_config_h_exists__
#include "pwm_config.h"
#endif

// The offset and size of components in the PWM control structure
#define OFFSET_OF_CHAN_ID  0
#define OFFSET_OF_MODE_BUF 24
#define OFFSET_OF_DATA_OUT 32
#define SIZE_OF_T_DATA_OUT 40

// Define this if using shared memory to pass data between Client and Server. NB Otherwise data sent over c_pwm channel
// #define SHARED_MEM

// The number of PWM channels that are supported by the symmetrical PWM
#ifndef PWM_CHAN_COUNT
#define PWM_CHAN_COUNT 3
#endif

// The number of clocks to increment between each phase
#ifndef SYNC_INCREMENT
#define SYNC_INCREMENT (PWM_MAX_VALUE)
#endif

// The initial number of clocks to wait before starting the PWM loops
#ifndef INIT_SYNC_INCREMENT
#define INIT_SYNC_INCREMENT (SYNC_INCREMENT)
#endif

// Enumerate PWM Modes
// NB These were originally used in assembler, therefore are defines NOT enums!-(
// They are now redundant apart from D_PWM_MODE_3, which is used as an integrity check

#define D_PWM_MODE_0 0 // 3xSINGLE
#define D_PWM_MODE_1 1 // DOUBLE + 2xSINGLE
#define D_PWM_MODE_2 2 // 2xDOUBLE + SINGLE
#define D_PWM_MODE_3 3 // 3xDOUBLE
#define D_PWM_MODE_4 4 // LONG_SINGLE + 2xSINGLE
#define D_PWM_MODE_5 5 // LONG_SINGLE + DOUBLE + SINGLE
#define D_PWM_MODE_6 6 // LONG_SINGLE + 2xDOUBLE
#define D_PWM_MODE_7 7 // 2xLONG_SINGLE + SINGLE (WARNING Unsupported)
#define D_PWM_MODE_8 8 // 2xLONG_SINGLE + DOUBLE (WARNING Unsupported)
#define D_PWM_MODE_9 9 // 3xLONG_SINGLE (WARNING Unsupported)

#define NUM_PWM_PHASES 3 // 3-phase PWM
#define NUM_PWM_BUFS 2  // Double-buffered
#define NUM_PULSE_EDGES 2  // Max. number of edges in a pulse!

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
	unsigned cur_mode; // current PWM mode for this buffer
} PWM_BUFFER_TYP;

// Structure containing pwm output data for all buffers
typedef struct PWM_CONTROL_TAG
{
	PWM_BUFFER_TYP buf_data[NUM_PWM_BUFS]; // Array of buffer-data structures, one for each buffer
} PWM_CONTROL_TYP;

#endif /*DSC_ALT_PWM_H_*/
