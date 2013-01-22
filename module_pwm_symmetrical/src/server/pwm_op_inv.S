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
//
// This implements all PWM configurations for 3 channel
// PWM. The mode of operation should be updated using
// the appropriate functions in the dsc_pwm_cli API
//
// 26 Apr 2010

#include <xs1.h>

#ifdef __pwm_config_h_exists__
#include "pwm_config.h"
#endif

#include "pwm_common.h"

.extern pwm_op_inv
.globl pwm_op_inv.nstackwords
.globl pwm_op_inv.maxthreads
.globl pwm_op_inv.maxtimers
.globl pwm_op_inv.maxchanends

.linkset pwm_op_inv.nstackwords, 13
.linkset pwm_op_inv.maxchanends, 1
.linkset pwm_op_inv.maxtimers, 0
.linkset pwm_op_inv.maxthreads, 0

.globl pwm_op_inv
.cc_top pwm_op_inv.func, pwm_op_inv
.text

// r0 - buf_id [0,1]
// r1 - p32_pwm_hi,
// r2 - p32_pwm_lo,
// r3 - c_pwm,
// sp[14] - mem_addr: address of shared memory buffer
// sp[15] - c_adc_trig: ADC trigger channel
// sp[16] - p16_adc_sync: dummy port for ADC synchronisation
pwm_op_inv:
	entsp 13

	// Callee save: Store whatever in registers (reload on exit)
	stw r4, sp[1] // Store r4 in sp[1]
	stw r5, sp[2]
	stw r6, sp[3]
	stw r7, sp[4]
	stw r8, sp[5]
	stw r9, sp[6]
	stw r10, sp[7]

	stw r0, sp[8]		// sp[8] = buf_id [0,1]
	stw r1, sp[9]		// sp[9] = p32_pwm_hi
	stw r2, sp[10]  // sp[10] = p32_pwm_lo
	stw r3, sp[11]  // sp[11] = c_pwm

	mov r8, r1  // r8 = p32_pwm_hi

	bl read_out_data

	// get current time stamp
	getts r7, res[r0] // r7 = resource[1stPort].time // Time-stamp of previous transfer

	ldc r8, INIT_SYNC_INCREMENT // r8 = 4096 (PWM_MAX_VALUE)
	add r7, r8, r7  // r7 += PWM_MAX_VALUE (1st Port TS + 4096)

	// check mode and branch as appropriate
	eq r8, r10, D_PWM_MODE_0
	bt r8, L_PWM_MODE_0
	eq r8, r10, D_PWM_MODE_1
	bt r8, L_PWM_MODE_1
	eq r8, r10, D_PWM_MODE_2
	bt r8, L_PWM_MODE_2
	eq r8, r10, D_PWM_MODE_3
	bt r8, L_PWM_MODE_3
	eq r8, r10, D_PWM_MODE_4
	bt r8, L_PWM_MODE_4
	eq r8, r10, D_PWM_MODE_5
	bt r8, L_PWM_MODE_5
	eq r8, r10, D_PWM_MODE_6
	bt r8, L_PWM_MODE_6

L_PWM_STOP:
    ldc r8, 0
    sub r7, r8, 1
    out res[r0], r8
    out res[r1], r8
    out res[r2], r8
    out res[r6], r7
    out res[r9], r7
    out res[r11], r7
	bu	L_PWM_STOP

L_PWM_MODE_0:
	// load c_pwm
	ldw r10, sp[11]

L_PWM_MODE_0_LOOP:

	// Channel 0
	ldw r8, r3[0]
	sub r8, r7, r8 
	setpt res[r0], r8
	ldw r8, r3[4]
	sub r8, r7, r8
	setpt res[r6], r8
	ldw r8, r3[1]
	out res[r0], r8
	ldw r8, r3[5]
	out res[r6], r8

	// Channel 1
	ldw r8, r4[0]
	sub r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[4]
	sub r8, r7, r8
	setpt res[r9], r8
	ldw r8, r4[1]
	out res[r1], r8
	ldw r8, r4[5]
	out res[r9], r8
	
	// Channel 2
	ldw r8, r5[0]
	sub r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[4]
	sub r8, r7, r8
	setpt res[r11], r8
	ldw r8, r5[1]
	out res[r2], r8
	ldw r8, r5[5]
	out res[r11], r8

	// trigger adc
	#if LOCK_ADC_TO_PWM
	ldw r8, sp[16] // load port
	setpt res[r8], r7 // pt = sync point
	ldw r10, sp[15] // load adc trig chanend
	in r8, res[r8] // wait until we hit setpt
	outct res[r10], XS1_CT_END // send adc trig token
	ldw r10, sp[11] // load clobbered chanend
	#endif

	// setup event
	mov r8, r11
	ldap r11, L_GO_UPDATE_M1
	setv res[r10], r11
	eeu res[r10]
	setsr 0x1
	// clear events
	clrsr 0x1
	clre
	mov r11, r8

	// update SYNC timestamp
	ldc r8, SYNC_INCREMENT
	add r7, r8, r7

	bu L_PWM_MODE_0
	
L_GO_UPDATE_M1:
	// Expected registers values on entry:
	// r0: p32_pwm_hi[0] Hi-leg of 1st Port
	// r1: p32_pwm_hi[1] Hi-leg of 2nd Port
	// r2: p32_pwm_hi[2] Hi-leg of 3rd Port
	// r3: Addr of 1st pwm_out_data_buf[][] cell
	// r4: Addr of 2nd pwm_out_data_buf[][] cell
	// r5: Addr of 3rd pwm_out_data_buf[][] cell
	// r6: p32_pwm_lo[0] Lo-leg of 1stPort
	// r7: Time-stamp of previous transfer on 1stPort
	// r9: p32_pwm_lo[1] Lo-leg of 2ndPort
	// r10: USUALLY c_pwm
	// r11: p32_pwm_lo[2] Lo-leg of 3rdPort


	chkct res[r10], 0x1	// discard resource[c_pwm].token if equal to  1  
	outct res[r10], 0x1	// output token of value 1 on channel c_pwm
	in r0, res[r10]			// r0 = c_pwm data (Wait to read new buf_id from c_pwm -- NB signals next data ready)
	chkct res[r10], 0x1
	outct res[r10], 0x1

	stw r7, sp[13] // sp[13] = r7 (Store Time-stamp of previous transfer on 1stPort)
	stw r0, sp[8]		// sp[8] = r0 (buf_id)
	ldw r8, sp[9]		// r8 = p32_pwm_hi[]

	bl read_out_data

	// r10: cur_mode

	// update time stamp => start time = old_start_time + SYNC_INCREMENT
	ldw r7, sp[13]
	ldc r8, SYNC_INCREMENT
	add r7, r8, r7

	// check mode and branch as appropriate. NB read_out_data returns r10 = cur_mode
	eq r8, r10, D_PWM_MODE_0
	bt r8, L_PWM_MODE_0
	eq r8, r10, D_PWM_MODE_1
	bt r8, L_PWM_MODE_1
	eq r8, r10, D_PWM_MODE_2
	bt r8, L_PWM_MODE_2
	eq r8, r10, D_PWM_MODE_3
	bt r8, L_PWM_MODE_3
	eq r8, r10, D_PWM_MODE_4
	bt r8, L_PWM_MODE_4
	eq r8, r10, D_PWM_MODE_5
	bt r8, L_PWM_MODE_5
	eq r8, r10, D_PWM_MODE_6
	bt r8, L_PWM_MODE_6
	bu	L_PWM_STOP

L_PWM_MODE_1:
	// load c_pwm
	ldw r10, sp[11]

L_PWM_MODE_1_LOOP:

	// Channel 0
	ldw r8, r3[0]
	sub r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[4]
	sub r8, r7, r8
	setpt res[r6], r8
	ldw r8, r3[1]
	out res[r0], r8
	ldw r8, r3[5]
	out res[r6], r8

	// Channel 1
	ldw r8, r4[0]
	sub r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[4]
	sub r8, r7, r8
	setpt res[r9], r8
	ldw r8, r4[1]
	out res[r1], r8
	ldw r8, r4[5]
	out res[r9], r8
	
	// Channel 2
	ldw r8, r5[0]
	sub r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[4]
	sub r8, r7, r8
	setpt res[r11], r8
	ldw r8, r5[1]
	out res[r2], r8
	ldw r8, r5[5]
	out res[r11], r8

	// trigger adc
	#if LOCK_ADC_TO_PWM
	ldw r8, sp[16] // load port
	setpt res[r8], r7 // pt = sync point
	ldw r10, sp[15] // load adc trig chanend
	in r8, res[r8] // wait until we hit setpt
	outct res[r10], XS1_CT_END // send adc trig token
	ldw r10, sp[11] // load clobbered chanend
	#endif

	// Channel 0
	ldw r8, r3[2]
	add r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[6]
	add r8, r7, r8
	setpt res[r6], r8
	ldw r8, r3[3]
	out res[r0], r8
	ldw r8, r3[7]
	out res[r6], r8
	
	// setup event
	mov r8, r11
	ldap r11, L_GO_UPDATE_M1
	setv res[r10], r11
	eeu res[r10]
	setsr 0x1
	// clear events
	clrsr 0x1
	clre
	mov r11, r8

	// update SYNC timestamp
	ldc r8, SYNC_INCREMENT
	add r7, r8, r7
	mkmsk r8, 16
	and r7, r8, r7
	
	bu L_PWM_MODE_1

L_PWM_MODE_2:
	// load c_pwm
	ldw r10, sp[11]

L_PWM_MODE_2_LOOP:

	// Channel 0
	ldw r8, r3[0]
	sub r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[4]
	sub r8, r7, r8
	setpt res[r6], r8
	ldw r8, r3[1]
	out res[r0], r8
	ldw r8, r3[5]
	out res[r6], r8

	// Channel 1
	ldw r8, r4[0]
	sub r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[4]
	sub r8, r7, r8
	setpt res[r9], r8
	ldw r8, r4[1]
	out res[r1], r8
	ldw r8, r4[5]
	out res[r9], r8
	
	// Channel 2
	ldw r8, r5[0]
	sub r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[4]
	sub r8, r7, r8
	setpt res[r11], r8
	ldw r8, r5[1]
	out res[r2], r8
	ldw r8, r5[5]
	out res[r11], r8

	// trigger adc
	#if LOCK_ADC_TO_PWM
	ldw r8, sp[16] // load port
	setpt res[r8], r7 // pt = sync point
	ldw r10, sp[15] // load adc trig chanend
	in r8, res[r8] // wait until we hit setpt
	outct res[r10], XS1_CT_END // send adc trig token
	ldw r10, sp[11] // load clobbered chanend
	#endif

	// Channel 1
	ldw r8, r4[2]
	add r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[6]
	add r8, r7, r8
	setpt res[r9], r8
	ldw r8, r4[3]
	out res[r1], r8
	ldw r8, r4[7]
	out res[r9], r8

	// Channel 0
	ldw r8, r3[2]
	add r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[6]
	add r8, r7, r8
	setpt res[r6], r8
	ldw r8, r3[3]
	out res[r0], r8
	ldw r8, r3[7]
	out res[r6], r8

	// setup event
	mov r8, r11
	ldap r11, L_GO_UPDATE_M1
	setv res[r10], r11
	eeu res[r10]
	setsr 0x1
	// clear events
	clrsr 0x1
	clre
	mov r11, r8

	// update SYNC timestamp
	ldc r8, SYNC_INCREMENT
	add r7, r8, r7
	mkmsk r8, 16
	and r7, r8, r7
	
	bu L_PWM_MODE_2
	
L_PWM_MODE_3: // 3xDOUBLE
	ldw r10, sp[11] // r10 = c_pwm (load chanend)

L_PWM_MODE_3_LOOP:
	// Expected registers values on exit:
	// r0: p32_pwm_hi[0] Hi-leg of 1st Port
	// r1: p32_pwm_hi[1] Hi-leg of 2nd Port
	// r2: p32_pwm_hi[2] Hi-leg of 3rd Port
	// r3: Addr of 1st pwm_out_data_buf[][] cell
	// r4: Addr of 2nd pwm_out_data_buf[][] cell
	// r5: Addr of 3rd pwm_out_data_buf[][] cell
	// r6: p32_pwm_lo[0] Lo-leg of 1stPort
	// r7: resource[1stPort].time  Time-stamp of next transfer
	// r9: p32_pwm_lo[1] Lo-leg of 2ndPort
	// r11: p32_pwm_lo[2] Lo-leg of 3rdPort

	// sp[8]: buf_id
	// sp[10]: p32_pwm_lo[]
	// sp[11]: c_pwm
	// sp[14]: mem_addr (Shared memory address)
	// sp[15]: c_adc_trig
	// sp[16]: p16_adc_sync

	// Set-up output on 6 PWM ports ...

	// Edge_0 Channel_0 Hi-Leg
	ldw r8, r3[0] // r8 = hi_ts0 (time-stamp for edge_0 of Hi-leg 1stPort)
	sub r8, r7, r8 // r8 = r7 - r8 (= 1stPort_TS - hi_ts0 + 4096 -- Time Diff)
	setpt res[r0], r8 // resource[Hi_Leg 1stPort].time = r8 (set time next for transfer on Hi-Leg 1stPort)
	ldw r8, r3[1] // r8 = hi_out0 (Load Output Value for edge_0 of Hi-leg)
	out res[r0], r8 // resource[Hi_Leg 1stPort].val = r8 (Load output value into Hi-Leg 1stPort)

	// Edge_0 Channel_0 Lo-Leg
	ldw r8, r3[4] // r8 = lo_ts0 (time-stamp for edge_0 of Lo-leg 1stPort)
	sub r8, r7, r8 // r8 = r7 - r8 (= 1stPort_TS - lo_ts0 + 4096 -- Time Diff)
	setpt res[r6], r8 // resource[Lo_leg 1stPort].time = r8 (set time for next transfer on Lo-Leg 1stPort)
	ldw r8, r3[5] // r8 = lo_out0 (Load Output Value for edge_0 of Lo-leg)
	out res[r6], r8 // resource[Lo_Leg 1stPort].val = r8 (Load output value into Lo-Leg 1stPort)

	// Edge_0 Channel_1 Hi-Leg
	ldw r8, r4[0]	// r8 = hi_ts0 (time-stamp for edge_0 of Hi-leg 2ndPort)
	sub r8, r7, r8
	setpt res[r1], r8 // resource[Hi_Leg 2ndPort].time = r8 (set time for next transfer on Hi-Leg 2ndPort)
	ldw r8, r4[1]
	out res[r1], r8

	// Edge_0 Channel_1 Lo-Leg
	ldw r8, r4[4]
	sub r8, r7, r8
	setpt res[r9], r8 // resource[Lo_leg 2ndPort].time = r8 (set time for next transfer on Lo-Leg 2ndPort)
	ldw r8, r4[5]
	out res[r9], r8

	// Edge_0 Channel_2 Hi-Leg
	ldw r8, r5[0]	// r8 = hi_ts0 (time-stamp for edge_0 of Hi-leg 3rdPort)
	sub r8, r7, r8
	setpt res[r2], r8 // resource[Hi_Leg 3rdPort].time = r8 (set time for next transfer on Hi-Leg 3rdPort)
	ldw r8, r5[1]
	out res[r2], r8

	// Edge_0 Channel_2 Lo-Leg
	ldw r8, r5[4]
	sub r8, r7, r8
	setpt res[r11], r8 // resource[Lo_leg 3rdPort].time = r8 (set time for next transfer on Lo-Leg 3rdPort)
	ldw r8, r5[5]
	out res[r11], r8

	// trigger adc
	#if LOCK_ADC_TO_PWM
	ldw r8, sp[16] // r8 = p16_adc_sync (ADC synchronisation port)
	setpt res[r8], r7 // resource[p16_adc_sync].time = 1stPort_TS + 4096 (set time for next transfer on ADC Sync Port to TS for previous transfer on 1stPort)
	ldw r10, sp[15] // r10 = c_adc_trig (load adc trig chanend)
	in r8, res[r8] // r8 = resource[p16_adc_sync].val (Wait until time to input data)
	outct res[r10], XS1_CT_END // resource[c_adc_trig].val = XS1_CT_END ( send adc trig token)
	ldw r10, sp[11] // r10 = c_pwm (reload clobbered chanend c_pwm)
	#endif

	// Edge_1 Channel_2 Hi-Leg
	ldw r8, r5[2]	// r8 = hi_ts1 (time-stamp for edge_1 of Hi-leg 3rdPort)
	add r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[3] // r8 = hi_out1 (Load Output Value for edge_1 of Hi-leg 3rdPort)
	out res[r2], r8

	// Edge_1 Channel_2 Lo-Leg
	ldw r8, r5[6]	// r8 = lo_ts1 (time-stamp for edge_1 of Lo-leg 3rdPort)
	add r8, r7, r8
	setpt res[r11], r8
	ldw r8, r5[7] // r8 = lo_out1 (Load Output Value for edge_1 of Lo-leg 3rdPort)
	out res[r11], r8

	// Edge_1 Channel_1 Hi-Leg
	ldw r8, r4[2]
	add r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[3]
	out res[r1], r8

	// Edge_1 Channel_1 Lo-Leg
	ldw r8, r4[6]
	add r8, r7, r8
	setpt res[r9], r8
	ldw r8, r4[7]
	out res[r9], r8

	// Edge_1 Channel_0 Hi-Leg
	ldw r8, r3[2]
	add r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[3]
	out res[r0], r8

	// Edge_1 Channel_0 Lo-Leg
	ldw r8, r3[6]
	add r8, r7, r8
	setpt res[r6], r8
	ldw r8, r3[7]
	out res[r6], r8

	// setup events ...

	mov r8, r11								// r8 = p32_pwm_lo[2] (Lo-leg of 3rdPort). NB Free up r11 for use with ldap
	ldap r11, L_GO_UPDATE_M1	// r11 = PC + 2xL_GO_UPDATE_M1	
	setv res[r10], r11				// resource[c_pwm].vect = L_GO_UPDATE_M1 (Use Relative address)
	eeu res[r10]							// resource[c_pwm].enable 
	setsr 0x1									// EEBLE (Enable Thread Events - Any Pending Events Fire & jump to L_GO_UPDATE_M1)

	// clear events
	clrsr 0x1									// EEBLE (Clear Thread Events - Queue Pending Events)
	clre											// Clear all thread enabling flags
	mov r11, r8								// r11 = p32_pwm_lo[2] (Lo-leg of 3rdPort) Reload clobbered Port 

	// update SYNC timestamp
	ldc r8, SYNC_INCREMENT	// r8 = PWM_MAX_VALUE = 4096
	add r7, r8, r7					// r7 += 4096 ( Increment Time-stamp of previous transfer )
	mkmsk r8, 16						// r8 = 0x0000_FFFF (Make bitmask)
	and r7, r8, r7          // r7 &= 0x0000_FFFF  (Clear MS 16-bits of Time_Stamp) 

	bu L_PWM_MODE_3	// Branch Relative unconditional

L_PWM_MODE_4:
	// load c_pwm
	ldw r10, sp[11]

L_PWM_MODE_4_LOOP:

	// Channel 0
	ldw r8, r3[0]
	sub r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[4]
	sub r8, r7, r8
	setpt res[r6], r8
	ldw r8, r3[1]
	out res[r0], r8
	ldw r8, r3[5]
	out res[r6], r8

	// Channel 1
	ldw r8, r4[0]
	sub r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[4]
	sub r8, r7, r8
	setpt res[r9], r8
	ldw r8, r4[1]
	out res[r1], r8
	ldw r8, r4[5]
	out res[r9], r8

	// Channel 2
	ldw r8, r5[0]
	sub r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[4]
	sub r8, r7, r8
	setpt res[r11], r8
	ldw r8, r5[1]
	out res[r2], r8
	ldw r8, r5[5]
	out res[r11], r8
	// trigger adc
	#if LOCK_ADC_TO_PWM
	ldw r8, sp[16] // load port
	setpt res[r8], r7 // pt = sync point
	ldw r10, sp[15] // load adc trig chanend
	in r8, res[r8] // wait until we hit setpt
	outct res[r10], XS1_CT_END // send adc trig token
	ldw r10, sp[11] // load clobbered chanend
	#endif

	// Channel 1
	ldw r8, r4[2]
	add r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[6]
	add r8, r7, r8
	setpt res[r9], r8
	ldw r8, r4[3]
	out res[r1], r8
	ldw r8, r4[7]
	out res[r9], r8

	// update SYNC timestamp
	ldc r8, SYNC_INCREMENT
	add r7, r8, r7
	mkmsk r8, 16
	and r7, r8, r7

	// setup event
	mov r8, r11
	ldap r11, L_GO_UPDATE_M7
	setv res[r10], r11
	eeu res[r10]
	setsr 0x1
	// clear events
	clrsr 0x1
	clre
	mov r11, r8

	bu L_PWM_MODE_4

L_PWM_MODE_5:
	// load c_pwm
	ldw r10, sp[11]

L_PWM_MODE_5_LOOP:

	// Channel 0
	ldw r8, r3[0]
	sub r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[4]
	sub r8, r7, r8
	setpt res[r6], r8
	ldw r8, r3[1]
	out res[r0], r8
	ldw r8, r3[5]
	out res[r6], r8

	// Channel 1
	ldw r8, r4[0]
	sub r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[4]
	sub r8, r7, r8
	setpt res[r9], r8
	ldw r8, r4[1]
	out res[r1], r8
	ldw r8, r4[5]
	out res[r9], r8

	// Channel 2
	ldw r8, r5[0]
	sub r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[4]
	sub r8, r7, r8
	setpt res[r11], r8
	ldw r8, r5[1]
	out res[r2], r8
	ldw r8, r5[5]
	out res[r11], r8

	// trigger adc
	#if LOCK_ADC_TO_PWM
	ldw r8, sp[16] // load port
	setpt res[r8], r7 // pt = sync point
	ldw r10, sp[15] // load adc trig chanend
	in r8, res[r8] // wait until we hit setpt
	outct res[r10], XS1_CT_END // send adc trig token
	ldw r10, sp[11] // load clobbered chanend
	#endif

	// Channel 2
	ldw r8, r5[2]
	add r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[6]
	add r8, r7, r8
	setpt res[r11], r8
	ldw r8, r5[3]
	out res[r2], r8
	ldw r8, r5[7]
	out res[r11], r8

	// Channel 1
	ldw r8, r4[2]
	add r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[6]
	add r8, r7, r8
	setpt res[r9], r8
	ldw r8, r4[3]
	out res[r1], r8
	ldw r8, r4[7]
	out res[r9], r8

	// update SYNC timestamp
	ldc r8, SYNC_INCREMENT
	add r7, r8, r7
	mkmsk r8, 16
	and r7, r8, r7

	// setup event
	mov r8, r11
	ldap r11, L_GO_UPDATE_M7
	setv res[r10], r11
	eeu res[r10]
	setsr 0x1
	// clear events
	clrsr 0x1
	clre
	mov r11, r8

	bu L_PWM_MODE_5

L_PWM_MODE_6:
	// load c_pwm
	ldw r10, sp[11]

L_PWM_MODE_6_LOOP:

	// Channel 0
	ldw r8, r3[0]
	sub r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[4]
	sub r8, r7, r8
	setpt res[r6], r8
	ldw r8, r3[1]
	out res[r0], r8
	ldw r8, r3[5]
	out res[r6], r8

	// Channel 1
	ldw r8, r4[0]
	sub r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[4]
	sub r8, r7, r8
	setpt res[r9], r8
	ldw r8, r4[1]
	out res[r1], r8
	ldw r8, r4[5]
	out res[r9], r8

	// Channel 2
	ldw r8, r5[0]
	sub r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[4]
	sub r8, r7, r8
	setpt res[r11], r8
	ldw r8, r5[1]
	out res[r2], r8
	ldw r8, r5[5]
	out res[r11], r8

	// trigger adc
	#if LOCK_ADC_TO_PWM
	ldw r8, sp[16] // load port
	setpt res[r8], r7 // pt = sync point
	ldw r10, sp[15] // load adc trig chanend
	in r8, res[r8] // wait until we hit setpt
	outct res[r10], XS1_CT_END // send adc trig token
	ldw r10, sp[11] // load clobbered chanend
	#endif

	// update SYNC timestamp
	ldc r8, SYNC_INCREMENT
	add r7, r8, r7
	mkmsk r8, 16
	and r7, r8, r7

	// setup event
	mov r8, r11
	ldap r11, L_GO_UPDATE_M7
	setv res[r10], r11
	eeu res[r10]
	setsr 0x1
	// clear events
	clrsr 0x1
	clre
	mov r11, r8

	bu L_PWM_MODE_6

L_GO_UPDATE_M7:
	// Channel 0
	ldw r8, r3[0]
	sub r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[4]
	sub r8, r7, r8
	setpt res[r6], r8
	ldc r8, 0
	out res[r0], r8
	out res[r6], r8

	// get mode
	chkct res[r10], 0x1
	outct res[r10], 0x1
	in r0, res[r10]
	chkct res[r10], 0x1
	outct res[r10], 0x1

	// save TS
	stw r7, sp[13]

	// load up arrays
	ldw r8, sp[9]   // p32_pwm_hi
	mov r7, r0  // buf
	stw r7, sp[8]

	/* load ports and data pointers */
	//prep for reading port order array
	ldw r11, sp[14]
	ldc r0, 12
	mul r0, r7, r0 // buf_id * 12
	add r11, r0, r11 // now at top of correct chan_id_buf

	// prep for reading data_out
    ldw r5, sp[14]
    ldc r2, OFFSET_OF_DATA_OUT
    add r5, r5, r2
    ldc r2, (SIZE_OF_T_DATA_OUT*3)
    mul r7, r7, r2 // buf_id * r2
    add r5, r5, r7 // now at top of correct array of structs

	ldc r2, SIZE_OF_T_DATA_OUT
	ldw r0, r11[0] // chan_id_buf[0]
	mul r3, r0, r2 // mult chan_id_buf[0] by SIZE_OF_T_DATA_OUT
	add r3, r5, r3 // out_data0 assigned
	ldw r0, r8[r0] // port 0 assigned

	ldw r1, r11[1] // chan_id_buf[1]
	mul r4, r1, r2 // mult chan_id_buf[1] by SIZE_OF_T_DATA_OUT
	add r4, r5, r4 // out_data1 assigned
	ldw r1, r8[r1] // port 1 assigned

	ldw r6, r11[2] // chan_id_buf[2]
	mul r10, r6, r2 // mult chan_id_buf[2] by SIZE_OF_T_DATA_OUT
	add r5, r5, r10 // out_data1 assigned
	ldw r2, r8[r6] // port 2 assigned

	/* load inverted ports */
	ldw r10, sp[10]
	// inv port 0
	ldw r6, r11[0]
	ldw r6, r10[r6]

	// inv port 1
	ldw r9, r11[1]
	ldw r9, r10[r9]

	// inv port 2
	ldw r11, r11[2]
	ldw r11, r10[r11]

	// read mode
    ldw r7, sp[8] // load in buffer number
    ldw r8, sp[14]
    ldc r10, OFFSET_OF_MODE_BUF
    add r8, r8, r10
    ldaw r8, r8[r7]
    ldw r10, r8[0]

	// get current time stamp
	ldw r7, sp[13]

	ldc r8, SYNC_INCREMENT
	add r7, r8, r7

	// check mode and branch as appropriate
	// check mode and branch as appropriate
	eq r8, r10, D_PWM_MODE_0
	bt r8, L_PWM_MODE_0
	eq r8, r10, D_PWM_MODE_1
	bt r8, L_PWM_MODE_1
	eq r8, r10, D_PWM_MODE_2
	bt r8, L_PWM_MODE_2
	eq r8, r10, D_PWM_MODE_3
	bt r8, L_PWM_MODE_3
	eq r8, r10, D_PWM_MODE_4
	bt r8, L_PWM_MODE_4
	eq r8, r10, D_PWM_MODE_5
	bt r8, L_PWM_MODE_5
	eq r8, r10, D_PWM_MODE_6
	bt r8, L_PWM_MODE_6
	bu	L_PWM_STOP

read_out_data:
	// Expected stack values on entry:
	// sp[8]: buf_id
	// sp[10]: p32_pwm_lo[]
	// sp[14]: mem_addr (Shared memory address)


	mov r7, r0  // r7 =  buf_id (0 or 1)

	/* load ports and data pointers */

	//prep for reading chan_id_buf
	ldw r11, sp[14] 	// r11 = mem_addr
	ldc r0, 12 				// r0 = 12 ( sizeof(unsigned) * NUM_PWM_PHASES : chan_id_buf line size)
	mul r0, r7, r0 		// r0 = buf_id * 12  (Offset to correct line of chan_id_buf[])
	add r11, r0, r11	// r11 = addr of start of correct chan_id_buf[]

	// prep for reading pwm_out_data_buf
	ldw r5, sp[14]									// r5 = mem_addr
	ldc r2, OFFSET_OF_DATA_OUT			// r2 = Offset to start of pwm_out_data_buf[][]
	add r5, r5, r2  								// r5 = addr of start of pwm_out_data_buf[][]
	ldc r2, (SIZE_OF_T_DATA_OUT*3)	// r2 = 120 = 40 * NUM_PWM_PHASES (pwm_out_data_buf line-size)
	mul r7, r7, r2									// r7 = buf_id * r2 (Offset to correct line of pwm_out_data_buf[])
	add r5, r5, r7 									// r5 = addr of start of correct pwm_out_data_buf[]

	ldc r2, SIZE_OF_T_DATA_OUT // r2 = 40

	/* load High-leg (V+) ports */

	ldw r0, r11[0] // r0 = cur_id = chan_id_buf[0] // channel id for 1st Phase
	mul r3, r0, r2 // r3 = cur_id * SIZE_OF_T_DATA_OUT // Offset to correct column of pwm_out_data_buf[]
	add r3, r5, r3 // r3 = addr of 1st pwm_out_data_buf[][] cell
	ldw r0, r8[r0] // r0 = p32_pwm_hi[cur_id] (current Hi-leg 1st port)

	ldw r1, r11[1] // r1 = cur_id = chan_id_buf[1] // channel id for 2nd Phase
	mul r4, r1, r2 // r4 = cur_id * SIZE_OF_T_DATA_OUT // Offset to correct column of pwm_out_data_buf[]
	add r4, r5, r4 // r4 = addr of 2nd pwm_out_data_buf[][] cell
	ldw r1, r8[r1] // r1 = p32_pwm_hi[cur_id] (current Hi-leg port) (2nd port)

	ldw r6, r11[2] // r6 = cur_id = chan_id_buf[2] // channel id for 3rd Phase
	mul r10, r6, r2 // r10 = cur_id * SIZE_OF_T_DATA_OUT // Offset to correct column of pwm_out_data_buf[] 
	add r5, r5, r10 // r5 = addr of 3rd pwm_out_data_buf[][] cell 
	ldw r2, r8[r6] // r2 = p32_pwm_hi[cur_id] (current Hi-leg port) (3rd port)

	/* load Low-leg(V-) ports */
	ldw r10, sp[10] // r10 = p32_pwm_lo[]

	// Lo-leg 1st Port
	ldw r6, r11[0]		// r6 = cur_id = chan_id_buf[0]  (channel id for 1st Phase)
	ldw r6, r10[r6]		// r6 = p32_pwm_lo[cur_id] (current Lo-leg 1st port)

	// Lo-leg 2nd Port
	ldw r9, r11[1]		// r9 = cur_id = chan_id_buf[1]  (channel id for 2nd Phase)
	ldw r9, r10[r9]		// r9 = p32_pwm_lo[cur_id] (current Lo-leg port) (2nd port)

	// Lo-leg 3rd Port
	ldw r11, r11[2]		// r11 = cur_id = chan_id_buf[3]  (channel id for 3rd Phase)
	ldw r11, r10[r11]	// r11 = p32_pwm_lo[cur_id] (current Lo-leg port) (3rd port)

	// read mode
	ldw r7, sp[8]		// r7 = buf_id
	ldw r8, sp[14]	// r8 = mem_addr
	ldc r10, OFFSET_OF_MODE_BUF // r10 = 24 ( offset to mode_buf)
	add r8, r8, r10	// r8 = addr of mod_buf[]
	ldaw r8, r8[r7]	// r8 += r7 * sizeof(unsigned) (addr of mod_buf[buf_id])
	ldw r10, r8[0]	// r10 = cur_mode

	// Expected registers values on exit:
	// r0: p32_pwm_hi[0] Hi-leg of 1st Port
	// r1: p32_pwm_hi[1] Hi-leg of 2nd Port
	// r2: p32_pwm_hi[2] Hi-leg of 3rd Port
	// r3: Addr of 1st pwm_out_data_buf[][] cell
	// r4: Addr of 2nd pwm_out_data_buf[][] cell
	// r5: Addr of 3rd pwm_out_data_buf[][] cell
	// r6: p32_pwm_lo[0] Lo-leg of 1stPort
	// r7: buf_id
	// r8: Addr of mod_buf[buf_id]
	// r9: p32_pwm_lo[1] Lo-leg of 2ndPort
	// r10: cur_mode
	// r11: p32_pwm_lo[2] Lo-leg of 3rdPort

	retsp 0;
// read_out_data

.cc_bottom pwm_op_inv.func

