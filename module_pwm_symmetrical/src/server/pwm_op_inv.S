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
	entsp 13 // Create a stack of 13 values. NB sp[0] and sp[max] are reserved

	// Callee save: Store old register values (reload on exit)
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


	// Get initial time stamp. NB This assumes 1st buf_id = 0
	ldw r11, sp[14] 	// r11 = mem_addr
	ldw r11, r11[0] // r11 = cur_id = chan_id_buf[0] // channel id for 1st Phase
	ldw r11, r1[r11] // r11 = p32_pwm_hi[cur_id] (current Hi-leg 1st port)

	getts r7, res[r11] // r7 = resource[1stPort].time // Time-stamp of previous transfer or current port-time

L_READ_NEW_DATA:
	// Expected stack values on entry:
	// sp[9]: p32_pwm_hi[]
	// sp[10]: p32_pwm_lo[]
	// sp[14]: mem_addr (Shared memory address)


	stw r7, sp[13] // sp[13] = r7 (Store Time-stamp of previous transfer on 1stPort)
	stw r0, sp[8]		// sp[8] = r0 (buf_id)

	ldw r11, sp[9]		// r11 = p32_pwm_hi[]
	mov r7, r0  // r7 =  buf_id (0 or 1)

	/* load ports and data pointers */

	//prep for reading chan_id_buf
	ldw r8, sp[14] 	// r8 = mem_addr
	ldc r0, 12 				// r0 = 12 ( sizeof(unsigned) * NUM_PWM_PHASES : chan_id_buf line size)
	mul r0, r7, r0 		// r0 = buf_id * 12  (Offset to correct line of chan_id_buf[])
	add r8, r0, r8	// r8 = addr of start of correct chan_id_buf[]

	// prep for reading pwm_out_data_buf
	ldw r5, sp[14]									// r5 = mem_addr
	ldc r2, OFFSET_OF_DATA_OUT			// r2 = Offset to start of pwm_out_data_buf[][]
	add r5, r5, r2  								// r5 = addr of start of pwm_out_data_buf[][]
	ldc r2, (SIZE_OF_T_DATA_OUT*3)	// r2 = 120 = 40 * NUM_PWM_PHASES (pwm_out_data_buf line-size)
	mul r7, r7, r2									// r7 = buf_id * r2 (Offset to correct line of pwm_out_data_buf[])
	add r5, r5, r7 									// r5 = addr of start of correct pwm_out_data_buf[]

	ldc r2, SIZE_OF_T_DATA_OUT // r2 = 40

	/* load High-leg (V+) ports */

	ldw r0, r8[0] // r0 = cur_id = chan_id_buf[0] // channel id for 1st Phase
	mul r3, r0, r2 // r3 = cur_id * SIZE_OF_T_DATA_OUT // Offset to correct column of pwm_out_data_buf[]
	add r3, r5, r3 // r3 = addr of 1st pwm_out_data_buf[][] cell
	ldw r0, r11[r0] // r0 = p32_pwm_hi[cur_id] (current Hi-leg 1st port)

	ldw r1, r8[1] // r1 = cur_id = chan_id_buf[1] // channel id for 2nd Phase
	mul r4, r1, r2 // r4 = cur_id * SIZE_OF_T_DATA_OUT // Offset to correct column of pwm_out_data_buf[]
	add r4, r5, r4 // r4 = addr of 2nd pwm_out_data_buf[][] cell
	ldw r1, r11[r1] // r1 = p32_pwm_hi[cur_id] (current Hi-leg port) (2nd port)

	ldw r6, r8[2] // r6 = cur_id = chan_id_buf[2] // channel id for 3rd Phase
	mul r10, r6, r2 // r10 = cur_id * SIZE_OF_T_DATA_OUT // Offset to correct column of pwm_out_data_buf[] 
	add r5, r5, r10 // r5 = addr of 3rd pwm_out_data_buf[][] cell 
	ldw r2, r11[r6] // r2 = p32_pwm_hi[cur_id] (current Hi-leg port) (3rd port)

	/* load Low-leg(V-) ports */
	ldw r10, sp[10] // r10 = p32_pwm_lo[]

	// Lo-leg 1st Port
	ldw r6, r8[0]		// r6 = cur_id = chan_id_buf[0]  (channel id for 1st Phase)
	ldw r6, r10[r6]		// r6 = p32_pwm_lo[cur_id] (current Lo-leg 1st port)

	// Lo-leg 2nd Port
	ldw r9, r8[1]		// r9 = cur_id = chan_id_buf[1]  (channel id for 2nd Phase)
	ldw r9, r10[r9]		// r9 = p32_pwm_lo[cur_id] (current Lo-leg port) (2nd port)

	// Lo-leg 3rd Port
	ldw r8, r8[2]		// r8 = cur_id = chan_id_buf[3]  (channel id for 3rd Phase)
	ldw r8, r10[r8]	// r8 = p32_pwm_lo[cur_id] (current Lo-leg port) (3rd port)

	// read mode
	ldw r7, sp[8]		// r7 = buf_id
	ldw r11, sp[14]	// r11 = mem_addr
	ldc r10, OFFSET_OF_MODE_BUF // r10 = 24 ( offset to mode_buf)
	add r11, r11, r10	// r11 = addr of mod_buf[]
	ldaw r11, r11[r7]	// r11 += r7 * sizeof(unsigned) (addr of mod_buf[buf_id])
	ldw r10, r11[0]	// r10 = cur_mode

	// update time stamp => start time = old_start_time + SYNC_INCREMENT
	ldw r7, sp[13] // r7 = sp[13] (Get Time-stamp of previous transfer on 1stPort)
	ldc r11, INIT_SYNC_INCREMENT // r11 = 4096 (PWM_MAX_VALUE)
	add r7, r11, r7  // r7 += PWM_MAX_VALUE (1st Port TS + 4096)

	// Expected registers values when we jump to current mode:
	// r0: p32_pwm_hi[0] Hi-leg of 1st Port
	// r1: p32_pwm_hi[1] Hi-leg of 2nd Port
	// r2: p32_pwm_hi[2] Hi-leg of 3rd Port
	// r3: Addr of 1st pwm_out_data_buf[][] cell
	// r4: Addr of 2nd pwm_out_data_buf[][] cell
	// r5: Addr of 3rd pwm_out_data_buf[][] cell
	// r6: p32_pwm_lo[0] Lo-leg of 1stPort
	// r7: Time-stamp of next transfer on 1stPort
	// r11: INIT_SYNC_INCREMENT
	// r9: p32_pwm_lo[1] Lo-leg of 2ndPort
	// r10: cur_mode
	// r8: p32_pwm_lo[2] Lo-leg of 3rdPort

	// check mode and branch as appropriate. NB read_out_data returns r10 = cur_mode
	eq r11, r10, D_PWM_MODE_0
	bt r11, L_MODE_0
	eq r11, r10, D_PWM_MODE_1
	bt r11, L_MODE_1
	eq r11, r10, D_PWM_MODE_2
	bt r11, L_MODE_2
	eq r11, r10, D_PWM_MODE_3
	bt r11, L_MODE_3
	eq r11, r10, D_PWM_MODE_4
	bt r11, L_MODE_4
	eq r11, r10, D_PWM_MODE_5
	bt r11, L_MODE_5
	eq r11, r10, D_PWM_MODE_6
	bt r11, L_MODE_6

// Default if Mode NOT supported
L_PWM_STOP:
	ldc r11, 0
	sub r7, r11, 1
	out res[r0], r11
	out res[r1], r11
	out res[r2], r11
	out res[r6], r7
	out res[r9], r7
	out res[r11], r7
	bu	L_PWM_STOP

L_MODE_0: // 3xSINGLE
	bl load_word1_data // Load 1st word containing 1 or 2 edges onto ports

	bl No_LS_new_data_test  // test if new data arrived if No LONG_SINGLE

	bu L_MODE_0 // repeat old Mode_0 data
	
L_MODE_1: // 2xSINGLE + DOUBLE
	bl load_word1_data // Load 1st word containing 1 or 2 edges onto ports

	// Edge_1 Channel_0 Hi-Leg
	ldw r11, r3[2] // r11 = hi_ts0 (time-stamp for edge_1 of Hi-leg 1stPort)
	add r11, r7, r11 // r11 = r7 - r11 (= 1stPort_TS - hi_ts0 + 4096 -- Time Diff)
	setpt res[r0], r11 // resource[Hi_Leg 1stPort].time = r11 (set time next for transfer on Hi-Leg 1stPort)
	ldw r11, r3[3] // r11 = hi_out0 (Load Hi-leg Output Value)
	out res[r0], r11 // resource[Hi_Leg 1stPort].val = r11 (Load output value into Hi-Leg 1stPort)

	// Edge_1 Channel_0 Lo-Leg
	ldw r11, r3[6] // r11 = lo_ts0 (time-stamp for edge_1 of Lo-leg 1stPort)
	add r11, r7, r11 // r11 = r7 - r11 (= 1stPort_TS - lo_ts0 + 4096 -- Time Diff)
	setpt res[r6], r11 // resource[Lo_leg 1stPort].time = r11 (set time for next transfer on Lo-Leg 1stPort)
	ldw r11, r3[7] // r11 = lo_out0 (Load Lo-Leg Output Value)
	out res[r6], r11 // resource[Lo_Leg 1stPort].val = r11 (Load output value into Lo-Leg 1stPort)

	bl No_LS_new_data_test  // test if new data arrived if No LONG_SINGLE

	bu L_MODE_1 // repeat old Mode_1 data

L_MODE_2: // SINGLE + 2xDOUBLE
	bl load_word1_data // Load 1st word containing 1 or 2 edges onto ports

	// Edge_1 Channel_1 Hi-Leg
	ldw r11, r4[2]
	add r11, r7, r11
	setpt res[r1], r11
	ldw r11, r4[3]
	out res[r1], r11

	// Edge_1 Channel_1 Lo-Leg
	ldw r11, r4[6]
	add r11, r7, r11
	setpt res[r9], r11
	ldw r11, r4[7]
	out res[r9], r11

	// Edge_1 Channel_0 Hi-Leg
	ldw r11, r3[2] // r11 = hi_ts0 (time-stamp for edge_1 of Hi-leg 1stPort)
	add r11, r7, r11 // r11 = r7 - r11 (= 1stPort_TS - hi_ts0 + 4096 -- Time Diff)
	setpt res[r0], r11 // resource[Hi_Leg 1stPort].time = r11 (set time next for transfer on Hi-Leg 1stPort)
	ldw r11, r3[3] // r11 = hi_out0 (Load Hi-leg Output Value)
	out res[r0], r11 // resource[Hi_Leg 1stPort].val = r11 (Load output value into Hi-Leg 1stPort)

	// Edge_1 Channel_0 Lo-Leg
	ldw r11, r3[6] // r11 = lo_ts0 (time-stamp for edge_1 of Lo-leg 1stPort)
	add r11, r7, r11 // r11 = r7 - r11 (= 1stPort_TS - lo_ts0 + 4096 -- Time Diff)
	setpt res[r6], r11 // resource[Lo_leg 1stPort].time = r11 (set time for next transfer on Lo-Leg 1stPort)
	ldw r11, r3[7] // r11 = lo_out0 (Load Lo-Leg Output Value)
	out res[r6], r11 // resource[Lo_Leg 1stPort].val = r11 (Load output value into Lo-Leg 1stPort)

	bl No_LS_new_data_test  // test if new data arrived if No LONG_SINGLE
	
	bu L_MODE_2 // repeat old Mode_2 data
	
L_MODE_3: // 3xDOUBLE
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
	// r10: c_pwm
	// r8: p32_pwm_lo[2] Lo-leg of 3rdPort

	// sp[8]: buf_id
	// sp[10]: p32_pwm_lo[]
	// sp[11]: c_pwm
	// sp[14]: mem_addr (Shared memory address)
	// sp[15]: c_adc_trig
	// sp[16]: p16_adc_sync

	// Set-up Edge_0 outputs on 6 PWM ports (NB Each will fire at timestamp specified) ...

	bl load_word1_data // Load 1st word containing 1 or 2 edges onto ports

	// Set-up Edge_1 outputs on 6 PWM ports (NB Each will fire at timestamp specified) ...

	// Edge_1 Channel_2 Hi-Leg
	ldw r11, r5[2]	// r11 = hi_ts1 (time-stamp for edge_1 of Hi-leg 3rdPort)
	add r11, r7, r11
	setpt res[r2], r11
	ldw r11, r5[3] // r11 = hi_out1 (Load Output Value for edge_1 of Hi-leg 3rdPort)
	out res[r2], r11

	// Edge_1 Channel_2 Lo-Leg
	ldw r11, r5[6]	// r11 = lo_ts1 (time-stamp for edge_1 of Lo-leg 3rdPort)
	add r11, r7, r11
	setpt res[r8], r11
	ldw r11, r5[7] // r11 = lo_out1 (Load Output Value for edge_1 of Lo-leg 3rdPort)
	out res[r8], r11

	// Edge_1 Channel_1 Hi-Leg
	ldw r11, r4[2]
	add r11, r7, r11
	setpt res[r1], r11
	ldw r11, r4[3]
	out res[r1], r11

	// Edge_1 Channel_1 Lo-Leg
	ldw r11, r4[6]
	add r11, r7, r11
	setpt res[r9], r11
	ldw r11, r4[7]
	out res[r9], r11

	// Edge_1 Channel_0 Hi-Leg
	ldw r11, r3[2]
	add r11, r7, r11
	setpt res[r0], r11
	ldw r11, r3[3]
	out res[r0], r11

	// Edge_1 Channel_0 Lo-Leg
	ldw r11, r3[6]
	add r11, r7, r11
	setpt res[r6], r11
	ldw r11, r3[7]
	out res[r6], r11

	bl No_LS_new_data_test  // test if new data arrived if No LONG_SINGLE

	bu L_MODE_3 // repeat old Mode_3 data

L_MODE_4: // LONG + 2xSINGLE
	bl load_word1_data // Load 1st word containing 1 or 2 edges onto ports

 	bl long_single_new_data_test // test if new data arrived if LONG_SINGLE

	bu L_MODE_4 // repeat old Mode_4 data

L_MODE_5: // LONG + SINGLE + DOUBLE
	bl load_word1_data // Load 1st word containing 1 or 2 edges onto ports

	// Edge_1 Channel_1 Hi-Leg
	ldw r11, r4[2]
	add r11, r7, r11
	setpt res[r1], r11
	ldw r11, r4[3]
	out res[r1], r11

	// Edge_1 Channel_1 Lo-Leg
	ldw r11, r4[6]
	add r11, r7, r11
	setpt res[r9], r11
	ldw r11, r4[7]
	out res[r9], r11

 	bl long_single_new_data_test // test if new data arrived if LONG_SINGLE

	bu L_MODE_5 // repeat old Mode_5 data

L_MODE_6: // LONG + 2xDOUBLE
	bl load_word1_data // Load 1st word containing 1 or 2 edges onto ports

	// Edge_1 Channel_2 Hi-Leg
	ldw r11, r5[2]	// r11 = hi_ts1 (time-stamp for edge_1 of Hi-leg 3rdPort)
	add r11, r7, r11
	setpt res[r2], r11
	ldw r11, r5[3] // r11 = hi_out1 (Load Output Value for edge_1 of Hi-leg 3rdPort)
	out res[r2], r11

	// Edge_1 Channel_2 Lo-Leg
	ldw r11, r5[6]	// r11 = lo_ts1 (time-stamp for edge_1 of Lo-leg 3rdPort)
	add r11, r7, r11
	setpt res[r8], r11
	ldw r11, r5[7] // r11 = lo_out1 (Load Output Value for edge_1 of Lo-leg 3rdPort)
	out res[r8], r11

	// Edge_1 Channel_1 Hi-Leg
	ldw r11, r4[2]
	add r11, r7, r11
	setpt res[r1], r11
	ldw r11, r4[3]
	out res[r1], r11

	// Edge_1 Channel_1 Lo-Leg
	ldw r11, r4[6]
	add r11, r7, r11
	setpt res[r9], r11
	ldw r11, r4[7]
	out res[r9], r11

 	bl long_single_new_data_test // test if new data arrived if LONG_SINGLE

	bu L_MODE_6 // repeat old Mode_6 data

L_MODE_7: // 2xLONG + SINGLE
	bl load_word1_data // Load 1st word containing 1 or 2 edges onto ports

 	bl long_single2_new_data_test // test if new data arrived if 2xLONG_SINGLE

	bu L_MODE_7 // repeat old Mode_7 data

L_MODE_8: // 2xLONG + DOUBLE
	bl load_word1_data // Load 1st word containing 1 or 2 edges onto ports

	// Edge_1 Channel_2 Hi-Leg
	ldw r11, r5[2]	// r11 = hi_ts1 (time-stamp for edge_1 of Hi-leg 3rdPort)
	add r11, r7, r11
	setpt res[r2], r11
	ldw r11, r5[3] // r11 = hi_out1 (Load Output Value for edge_1 of Hi-leg 3rdPort)
	out res[r2], r11

	// Edge_1 Channel_2 Lo-Leg
	ldw r11, r5[6]	// r11 = lo_ts1 (time-stamp for edge_1 of Lo-leg 3rdPort)
	add r11, r7, r11
	setpt res[r8], r11
	ldw r11, r5[7] // r11 = lo_out1 (Load Output Value for edge_1 of Lo-leg 3rdPort)
	out res[r8], r11

 	bl long_single2_new_data_test // test if new data arrived if 2xLONG_SINGLE

	bu L_MODE_8 // repeat old Mode_8 data

L_MODE_9: // 3xLONG
	bl load_word1_data // Load 1st word containing 1 or 2 edges onto ports

 	bl long_single3_new_data_test // test if new data arrived if 3xLONG_SINGLE

	bu L_MODE_9 // repeat old Mode_9 data

L_THREE_LONG: // Load 3rd Port with zero, for 3xLONG_SINGLE 
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
	// r8: p32_pwm_lo[2] Lo-leg of 3rdPort

	// Edge_0 Channel_2 Hi-Leg
	ldw r11, r5[0]	// r11 = hi_ts1 (time-stamp for edge_0 of Hi-leg 3rdPort)
	add r11, r7, r11
	setpt res[r2], r11

	// Edge_0 Channel_2 Lo-Leg
	ldw r11, r5[4]	// r11 = lo_ts1 (time-stamp for edge_0 of Lo-leg 3rdPort)
	add r11, r7, r11
	setpt res[r8], r11

	// Edge_0 Channel_2 Both-Legs
	ldc r11, 0					// r11 = 0 (Load Output Value for both legs of edge_0
	out res[r2], r11		// resource[Hi_Leg 3rdPort].val = 0 (Load Zero into Hi-Leg 3rdPort)
	out res[r8], r11	// resource[Lo_Leg 3rdPort].val = 0 (Load Zero into Lo-Leg 3rdPort)

L_TWO_LONG: // Load 2nd Port with zero, for 2xLONG_SINGLE

	// Edge_0 Channel_1 Hi-Leg
	ldw r11, r4[0]			// r11 = hi_ts1 (time-stamp for edge_0 of Hi-leg 2nd Port)
	add r11, r7, r11
	setpt res[r1], r11

	// Edge_0 Channel_1 Lo-Leg
	ldw r11, r4[4]			// r11 = lo_ts1 (time-stamp for edge_0 of Lo-leg 2nd Port)
	add r11, r7, r11
	setpt res[r9], r11

	// Edge_0 Channel_1 Both-Legs
	ldc r11, 0					// r11 = 0 (Load Output Value for both legs of edge_0
	out res[r1], r11	// resource[Hi_Leg 2ndPort].val = 0 (Load Zero into Hi-Leg 2nd Port)
	out res[r9], r11	// resource[Lo_Leg 2ndPort].val = 0 (Load Zero into Lo-Leg 2nd Port)

L_ONE_LONG: // Load 1st Port with zero, for one LONG_SINGLE

	// Edge_0 Channel_0 Hi-Leg
	ldw r11, r3[0]			// r11 = hi_ts0 (time-stamp for edge_0 of Hi-leg 1stPort)
	sub r11, r7, r11		// r11 = r7 - r11 (= 1stPort_TS - hi_ts0 + 4096 -- Time Diff)
	setpt res[r0], r11	// resource[Hi_Leg 1stPort].time = r11 (set time next for transfer on Hi-Leg 1stPort)

	// Edge_0 Channel_0 Lo-Leg
	ldw r11, r3[4]			// r11 = lo_ts0 (time-stamp for edge_0 of Lo-leg 1stPort)
	sub r11, r7, r11		// r11 = r7 - r11 (= 1stPort_TS - lo_ts0 + 4096 -- Time Diff)
	setpt res[r6], r11	// resource[Lo_leg 1stPort].time = r11 (set time for next transfer on Lo-Leg 1stPort)

	// Edge_0 Channel_0 Both-Legs
	ldc r11, 0					// r11 = 0 (Load Output Value for both legs of edge_0
	out res[r0], r11		// resource[Hi_Leg 1stPort].val = 0 (Load Zero into Hi-Leg 1stPort)
	out res[r6], r11		// resource[Lo_Leg 1stPort].val = 0 (Load Zero into Hi-Leg 1stPort)

L_WAIT_NO_LONG: // Wait for new data to arrive

	chkct res[r10], 0x1	// discard resource[c_pwm].token if equal to  1  
	outct res[r10], 0x1	// output token of value 1 on channel c_pwm
	in r0, res[r10]			// r0 = c_pwm data (Wait until new buf_id ready on c_pwm -- NB signals next data ready)
	chkct res[r10], 0x1
	outct res[r10], 0x1

	bu L_READ_NEW_DATA

/*****************************************************************************/
load_word1_data:
	// Load 1st word onto ports, this contains at least the first edge (Edge_0),
	// and for SINGLE and LONG_SINGLE, also the 2nd edge (Edge_1)
	// Expected registers values on entry
	// r0: p32_pwm_hi[0] Hi-leg of 1st Port
	// r1: p32_pwm_hi[1] Hi-leg of 2nd Port
	// r2: p32_pwm_hi[2] Hi-leg of 3rd Port
	// r3: Addr of 1st pwm_out_data_buf[][] cell
	// r4: Addr of 2nd pwm_out_data_buf[][] cell
	// r5: Addr of 3rd pwm_out_data_buf[][] cell
	// r6: p32_pwm_lo[0] Lo-leg of 1stPort
	// r7: resource[1stPort].time  Time-stamp of next transfer
	// r9: p32_pwm_lo[1] Lo-leg of 2ndPort
	// r8: p32_pwm_lo[2] Lo-leg of 3rdPort

	// Set-up 1st word output on 6 PWM ports ...

	// Channel_0 Hi-Leg
	ldw r11, r3[0] // r11 = hi_ts0 (time-stamp for edge_0 of Hi-leg 1stPort)
	sub r11, r7, r11 // r11 = r7 - r11 (= 1stPort_TS - hi_ts0 + 4096 -- Time Diff)
	setpt res[r0], r11 // resource[Hi_Leg 1stPort].time = r11 (set time next for transfer on Hi-Leg 1stPort)
	ldw r11, r3[1] // r11 = hi_out0 (Load Hi-leg Output Value)
	out res[r0], r11 // resource[Hi_Leg 1stPort].val = r11 (Load output value into Hi-Leg 1stPort)

	// Channel_0 Lo-Leg
	ldw r11, r3[4] // r11 = lo_ts0 (time-stamp for edge_0 of Lo-leg 1stPort)
	sub r11, r7, r11 // r11 = r7 - r11 (= 1stPort_TS - lo_ts0 + 4096 -- Time Diff)
	setpt res[r6], r11 // resource[Lo_leg 1stPort].time = r11 (set time for next transfer on Lo-Leg 1stPort)
	ldw r11, r3[5] // r11 = lo_out0 (Load Lo-Leg Output Value)
	out res[r6], r11 // resource[Lo_Leg 1stPort].val = r11 (Load output value into Lo-Leg 1stPort)

	// Channel_1 Hi-Leg
	ldw r11, r4[0]	// r11 = hi_ts0 (time-stamp for edge_0 of Hi-leg 2ndPort)
	sub r11, r7, r11
	setpt res[r1], r11 // resource[Hi_Leg 2ndPort].time = r11 (set time for next transfer on Hi-Leg 2ndPort)
	ldw r11, r4[1]
	out res[r1], r11

	// Channel_1 Lo-Leg
	ldw r11, r4[4]
	sub r11, r7, r11
	setpt res[r9], r11 // resource[Lo_leg 2ndPort].time = r11 (set time for next transfer on Lo-Leg 2ndPort)
	ldw r11, r4[5]
	out res[r9], r11

	// Channel_2 Hi-Leg
	ldw r11, r5[0]	// r11 = hi_ts0 (time-stamp for edge_0 of Hi-leg 3rdPort)
	sub r11, r7, r11
	setpt res[r2], r11 // resource[Hi_Leg 3rdPort].time = r11 (set time for next transfer on Hi-Leg 3rdPort)
	ldw r11, r5[1]
	out res[r2], r11

	// Channel_2 Lo-Leg
	ldw r11, r5[4]
	sub r11, r7, r11
	setpt res[r8], r11 // resource[Lo_leg 3rdPort].time = r11 (set time for next transfer on Lo-Leg 3rdPort)
	ldw r11, r5[5]
	out res[r8], r11

	// trigger adc
	#if LOCK_ADC_TO_PWM
	ldw r11, sp[16] // r11 = p16_adc_sync (ADC synchronisation port)
	setpt res[r11], r7 // resource[p16_adc_sync].time = 1stPort_TS + 4096 (set time for next transfer on ADC Sync Port to TS for previous transfer on 1stPort)
	ldw r10, sp[15] // r10 = c_adc_trig (load adc trig chanend)
	in r11, res[r11] // r11 = resource[p16_adc_sync].val (Wait until time to input data)
	outct res[r10], XS1_CT_END // resource[c_adc_trig].val = XS1_CT_END ( send adc trig token)
	ldw r10, sp[11] // r10 = c_pwm (reload clobbered chanend c_pwm)
	#endif

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
	// r10: c_pwm
	// r8: p32_pwm_lo[2] Lo-leg of 3rdPort

	retsp 0;
// load_word1_data
/*****************************************************************************/
long_single3_new_data_test:  // test if new data arrived, if 3xLONG_SINGLE

	// update SYNC timestamp
	ldc r11, SYNC_INCREMENT	// r11 = PWM_MAX_VALUE = 4096
	add r7, r11, r7					// r7 += 4096 ( Increment Time-stamp of previous transfer )

	ldap r11, L_THREE_LONG			// r11 = PC + 2xL_THREE_LONG (Load jump address)
	setv res[r10], r11				// resource[c_pwm].vect = L_THREE_LONG (Use Relative address)
	eeu res[r10]							// resource[c_pwm].enable 
	setsr 0x1									// EEBLE (Enable Thread Events - If c_pwm has data jump to L_THREE_LONG)

	// NB Continue if no data on c_pwm
	// clear events
	clrsr 0x1									// EEBLE (Clear Thread Events - Queue Pending Events)
	clre											// Clear all thread enabling flags

	retsp 0;
// long_single3_new_data_test
/*****************************************************************************/
long_single2_new_data_test:  // test if new data arrived, if 2xLONG_SINGLE

	// update SYNC timestamp
	ldc r11, SYNC_INCREMENT	// r11 = PWM_MAX_VALUE = 4096
	add r7, r11, r7					// r7 += 4096 ( Increment Time-stamp of previous transfer )

	ldap r11, L_TWO_LONG			// r11 = PC + 2xL_TWO_LONG (Load jump address)
	setv res[r10], r11				// resource[c_pwm].vect = L_TWO_LONG (Use Relative address)
	eeu res[r10]							// resource[c_pwm].enable 
	setsr 0x1									// EEBLE (Enable Thread Events - If c_pwm has data jump to L_TWO_LONG)

	// NB Continue if no data on c_pwm
	// clear events
	clrsr 0x1									// EEBLE (Clear Thread Events - Queue Pending Events)
	clre											// Clear all thread enabling flags

	retsp 0;
// long_single2_new_data_test
/*****************************************************************************/
long_single_new_data_test:  // test if new data arrived, if LONG_SINGLE

	// update SYNC timestamp
	ldc r11, SYNC_INCREMENT	// r11 = PWM_MAX_VALUE = 4096
	add r7, r11, r7					// r7 += 4096 ( Increment Time-stamp of previous transfer )

	ldap r11, L_ONE_LONG			// r11 = PC + 2xL_ONE_LONG (Load jump address)
	setv res[r10], r11				// resource[c_pwm].vect = L_ONE_LONG (Use Relative address)
	eeu res[r10]							// resource[c_pwm].enable 
	setsr 0x1									// EEBLE (Enable Thread Events - If c_pwm has data jump to L_ONE_LONG)

	// NB Continue if no data on c_pwm
	// clear events
	clrsr 0x1									// EEBLE (Clear Thread Events - Queue Pending Events)
	clre											// Clear all thread enabling flags

	retsp 0;
// long_single_new_data_test
/*****************************************************************************/
No_LS_new_data_test:  // test if new data arrived if No LONG_SINGLE

	ldap r11, L_WAIT_NO_LONG			// r11 = PC + 2xL_WAIT_NO_LONG	
	setv res[r10], r11				// resource[c_pwm].vect = L_WAIT_NO_LONG (Use Relative address)
	eeu res[r10]							// resource[c_pwm].enable 
	setsr 0x1									// EEBLE (Enable Thread Events - If c_pwm has data jump to L_WAIT_NO_LONG)

	// NB Continue if no data on c_pwm
	// clear events
	clrsr 0x1									// EEBLE (Clear Thread Events - Queue Pending Events)
	clre											// Clear all thread enabling flags

	// update SYNC timestamp
	ldc r11, SYNC_INCREMENT	// r11 = PWM_MAX_VALUE = 4096
	add r7, r11, r7					// r7 += 4096 ( Increment Time-stamp of previous transfer )

	retsp 0;
// No_LS_new_data_test
/*****************************************************************************/

.cc_bottom pwm_op_inv.func
