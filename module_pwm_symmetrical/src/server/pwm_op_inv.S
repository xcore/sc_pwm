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
 *
 * This code was substantially re-written Jan-2013 to be more readable.
 * Subroutines are used for common code sections. These require a 2 cycle overhead.
 * Also the 3 missing modes were added (more than one LONG_SINGLES)
 *
 * WARNING: No other modes other than Mode_3 (3xDOUBLE) have ever been tested.
 * This is due to the fact that the H/W used in the test, never needed to use
 * any of the other modes. 
 *
 * The flow of the pwm_op_inv() function is as follows ...
 *
 *(0) Initialisation. NB This function never terminates. It loops through the following stages (1 .. 7):-
 *
 *(1) READ_NEW_DATA: Reads data for 6-edges (3 Phases) from current buffer in shared memory.
 *		including the current mode (pulse configuration. E.g. LONG_SINGLE, DOUBLE, SINGLE)
 *
 *(2) Tests if Motor should be stopped, if so, if so drops through to L_PWM_STOP, else jumps to L_MODE_3
 *
 *(3) L_MODE_3:
 *	(a)	Increment the pulse-centre time-stamp by one full revolution.
 *	(b) Load the 1st 32-bit word onto each of the 6 ports with an individually calculated port time-stamp. 
 *			These words contain the rising edge of the pulse, and will fire when each time-stamp is reached.
 *	(c) If LOCK_ADC_TO_PWM is active, a time-stamp is calculated for the next PWM->ADC trigger.
 *			As the trigger event is sent over channel c_adc_trig (and these can NOT be timed), 
 *			a dummy port is used (p16_adc_sync). This is used to force a wait until the dummy port
 *      reaches the time-stamp. Then immediately afterwards, a token is sent on the c_adc_trig channel.
 *	(d) Load the 2nd 32-bit word onto each of the 6 ports with an individually calculated port time-stamp.
 *			These words contain the falling edge of the pulse, and will fire when each time-stamp is reached.
 *
 *(4) A test is now made to check whether the next set of data is ready (in the other buffer in shared memory).
 *		An attempt to read the next buffer identifier from the c_pwm channel is made ...
 *
 *(5)	If the data is NOT ready, then we loop again to L_MODE_3 (stage 3), and use the same old 32-bit data values.
 *
 *(6)	If the data IS ready, then a jump is performed to the label held in the ldap register (L_READ_NEW_BUF).
 *
 *(7)	In L_READ_NEW_BUF, the new buffer identifier is read, and then a jump is made to L_READ_NEW_DATA (1).
 *
 **/

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
	ldw r8, sp[14] 	// r8 = mem_addr
	ldw r6, r8[0] // r6 = cur_id = chan_id_buf[0] // channel id for 1st Phase
	ldw r11, r1[r6] // r11 = p32_pwm_hi[cur_id] (current Hi-leg 1st port)

	getts r9, res[r11] // r9 = resource[1stPort].time // Time-stamp of previous transfer or current port-time
	stw r9, sp[13] // sp[13] = r9 (Store Time-stamp for centre of previous pulse)

L_READ_NEW_DATA:
	// r0: buf_id
	// r9: Time-stamp of previous transfer on 1stPort

	// Expected stack values on entry:
	// sp[9]: p32_pwm_hi[]
	// sp[10]: p32_pwm_lo[]
	// sp[13]: time-stamp
	// sp[14]: mem_addr (Shared memory address)

	stw r0, sp[8]		// sp[8] = r0 (buf_id)

	ldw r2, sp[9]		// r2 = p32_pwm_hi[]
	ldw r8, sp[14] 	// r8 = mem_addr

	// read mode for this buffer 
	ldc r10, OFFSET_OF_MODE_BUF // r10 = 24 ( offset to mode_buf)
	add r11, r8, r10	// r11 = mem_addr + OFFSET_OF_MODE_BUF (addr of mod_buf[])
	ldaw r11, r11[r0]	// r11 += r0 * sizeof(unsigned) (addr of mod_buf[buf_id])
	ldw r10, r11[0]	// r10 = cur_mode
	stw r10, sp[12]		// sp[12] = r10 (cur_mode)

	/* load ports and data pointers */

	// prep for reading pwm_out_data_buf
	ldc r11, OFFSET_OF_DATA_OUT			// r11 = Offset to start of pwm_out_data_buf[][]
	add r5, r8, r11  								// r5 = addr of start of pwm_out_data_buf[][]
	ldc r11, (SIZE_OF_T_DATA_OUT*3)	// r11 = 120 = 40 * NUM_PWM_PHASES (pwm_out_data_buf line-size)
	mul r9, r0, r11									// r9 = buf_id * r11 (Offset to correct line of pwm_out_data_buf[])
	add r5, r5, r9 									// r5 = addr of start of correct pwm_out_data_buf[]

	//prep for reading chan_id_buf
	ldc r3, 12 				// r3 = 12 ( sizeof(unsigned) * NUM_PWM_PHASES : chan_id_buf line size)
	mul r3, r0, r3 		// r3 = buf_id * 12  (Offset to correct line of chan_id_buf[])
	add r8, r3, r8	// r8 = addr of start of correct chan_id_buf[]

	ldc r11, SIZE_OF_T_DATA_OUT // r11 = 40

	/* load High-leg (V+) ports */

	ldw r6, r8[0] // r6 = 1st_id = chan_id_buf[0] // channel id for 1st Phase
	mul r3, r6, r11 // r3 = 1st_id * SIZE_OF_T_DATA_OUT // Offset to correct column of pwm_out_data_buf[]
	add r3, r5, r3 // r3 = addr of 1st pwm_out_data_buf[][] cell
	ldw r0, r2[r6] // r0 = p32_pwm_hi[1st_id] (current Hi-leg 1st port)

	ldw r7, r8[1] // r7 = 2nd_id = chan_id_buf[1] // channel id for 2nd Phase
	mul r4, r7, r11 // r4 = 2nd_id * SIZE_OF_T_DATA_OUT // Offset to correct column of pwm_out_data_buf[]
	add r4, r5, r4 // r4 = addr of 2nd pwm_out_data_buf[][] cell
	ldw r1, r2[r7] // r1 = p32_pwm_hi[2nd_id] (current Hi-leg port) (2nd port)

	ldw r9, r8[2] // r9 = 3rd_id = chan_id_buf[2] // channel id for 3rd Phase
	mul r8, r9, r11 // r8 = 3rd_id * SIZE_OF_T_DATA_OUT // Offset to correct column of pwm_out_data_buf[] 
	add r5, r5, r8 // r5 = addr of 3rd pwm_out_data_buf[][] cell 
	ldw r2, r2[r9] // r2 = p32_pwm_hi[3rd_id] (current Hi-leg port) (3rd port)

	/* load Low-leg(V-) ports */
	ldw r8, sp[10] // r8 = p32_pwm_lo[]

	ldw r6, r8[r6]	// r6 = p32_pwm_lo[1st_id] (current Lo-leg 1st port)
	ldw r7, r8[r7]	// r7 = p32_pwm_lo[2nd_id] (current Lo-leg port) (2nd port)
	ldw r8, r8[r9]	// r8 = p32_pwm_lo[3rd_id] (current Lo-leg port) (3rd port)

	// Expected registers values when we jump to current mode:
	// r0: p32_pwm_hi[0] Hi-leg of 1st Port
	// r1: p32_pwm_hi[1] Hi-leg of 2nd Port
	// r2: p32_pwm_hi[2] Hi-leg of 3rd Port
	// r3: Addr of 1st pwm_out_data_buf[][] cell
	// r4: Addr of 2nd pwm_out_data_buf[][] cell
	// r5: Addr of 3rd pwm_out_data_buf[][] cell
	// r6: p32_pwm_lo[0] Lo-leg of 1stPort
	// r7: p32_pwm_lo[1] Lo-leg of 2ndPort
	// r8: p32_pwm_lo[2] Lo-leg of 3rdPort
	// r9: Time-stamp of next transfer on 1stPort
	// r10: cur_mode

	// check mode and branch as appropriate. NB read_out_data returns r10 = cur_mode
	eq r11, r10, D_PWM_MODE_3
	bt r11, L_MODE_3

// Default if Mode NOT supported
L_PWM_STOP:
	ldc r11, 0
	sub r9, r11, 1
	out res[r0], r11
	out res[r1], r11
	out res[r2], r11
	out res[r6], r9
	out res[r7], r9
	out res[r11], r9
	bu	L_PWM_STOP

L_MODE_3: // Old 3xDOUBLE mode
	// Expected registers values on exit:
	// r0: p32_pwm_hi[0] Hi-leg of 1st Port
	// r1: p32_pwm_hi[1] Hi-leg of 2nd Port
	// r2: p32_pwm_hi[2] Hi-leg of 3rd Port
	// r3: Addr of 1st pwm_out_data_buf[][] cell
	// r4: Addr of 2nd pwm_out_data_buf[][] cell
	// r5: Addr of 3rd pwm_out_data_buf[][] cell
	// r6: p32_pwm_lo[0] Lo-leg of 1stPort
	// r7: p32_pwm_lo[1] Lo-leg of 2ndPort
	// r8: p32_pwm_lo[2] Lo-leg of 3rdPort
	// r9: resource[1stPort].time  Time-stamp of next transfer
	// r10: cur_mode

	// sp[8]: buf_id
	// sp[10]: p32_pwm_lo[]
	// sp[11]: c_pwm
	// sp[13]: time-stamp
	// sp[14]: mem_addr (Shared memory address)
	// sp[15]: c_adc_trig
	// sp[16]: p16_adc_sync


	// Increment time-stamp for pulse-centre by one revolution
	ldw r9, sp[13] // r9 = sp[13] (Get Time-stamp of previous pulse-centre )
	ldc r11, INIT_SYNC_INCREMENT // r11 = 4096 (PWM_MAX_VALUE)
	add r9, r11, r9  // r9 += PWM_MAX_VALUE (Increment to Time-stamp by one revolution)
	stw r9, sp[13] // sp[13] = r9 (Store Time-stamp of next pulse-centre)

	// Set-up 1st word (Edge_0) outputs on 6 PWM ports (NB Each will fire at time-stamp specified) ...

	// Channel_0 Hi-Leg
	ldw r11, r3[0] // r11 = hi_ts0 (time-offset for edge_0 of Hi-leg 1stPort)
	add r11, r9, r11 // r11 = r9 + r11 (time of start of 1st Hi-leg word. NB r11 is -ve)
	setpt res[r0], r11 // resource[Hi_Leg 1stPort].time = r11 (set time next for transfer on Hi-Leg 1stPort)
	ldw r11, r3[1] // r11 = hi_out0 (Load Hi-leg Output Value)
	out res[r0], r11 // resource[Hi_Leg 1stPort].val = r11 (Load output value into Hi-Leg 1stPort)

	// Channel_0 Lo-Leg
	ldw r11, r3[4] // r11 = lo_ts0 (time-offset for edge_0 of Lo-leg 1stPort)
	add r11, r9, r11 // r11 = r9 + r11  (time of start of 1st Lo-leg word. NB r11 is -ve)
	setpt res[r6], r11 // resource[Lo_leg 1stPort].time = r11 (set time for next transfer on Lo-Leg 1stPort)
	ldw r11, r3[5] // r11 = lo_out0 (Load Lo-Leg Output Value)
	out res[r6], r11 // resource[Lo_Leg 1stPort].val = r11 (Load output value into Lo-Leg 1stPort)

	// Channel_1 Hi-Leg
	ldw r11, r4[0]	// r11 = hi_ts0 (time-offset for edge_0 of Hi-leg 2ndPort)
	add r11, r9, r11
	setpt res[r1], r11 // resource[Hi_Leg 2ndPort].time = r11 (set time for next transfer on Hi-Leg 2ndPort)
	ldw r11, r4[1]
	out res[r1], r11

	// Channel_1 Lo-Leg
	ldw r11, r4[4]
	add r11, r9, r11
	setpt res[r7], r11 // resource[Lo_leg 2ndPort].time = r11 (set time for next transfer on Lo-Leg 2ndPort)
	ldw r11, r4[5]
	out res[r7], r11

	// Channel_2 Hi-Leg
	ldw r11, r5[0]	// r11 = hi_ts0 (time-offset for edge_0 of Hi-leg 3rdPort)
	add r11, r9, r11
	setpt res[r2], r11 // resource[Hi_Leg 3rdPort].time = r11 (set time for next transfer on Hi-Leg 3rdPort)
	ldw r11, r5[1]
	out res[r2], r11

	// Channel_2 Lo-Leg
	ldw r11, r5[4]
	add r11, r9, r11
	setpt res[r8], r11 // resource[Lo_leg 3rdPort].time = r11 (set time for next transfer on Lo-Leg 3rdPort)
	ldw r11, r5[5]
	out res[r8], r11

	// Set-up 2nd word (Edge_1) outputs on 6 PWM ports (NB Each will fire at time-stamp specified) ...

	// Edge_1 Channel_2 Hi-Leg
	ldw r11, r5[2]	// r11 = hi_ts1 (time-offset for edge_1 of Hi-leg 3rdPort)
	add r11, r9, r11
	setpt res[r2], r11
	ldw r11, r5[3] // r11 = hi_out1 (Load Output Value for edge_1 of Hi-leg 3rdPort)
	out res[r2], r11

	// Edge_1 Channel_2 Lo-Leg
	ldw r11, r5[6]	// r11 = lo_ts1 (time-offset for edge_1 of Lo-leg 3rdPort)
	add r11, r9, r11
	setpt res[r8], r11
	ldw r11, r5[7] // r11 = lo_out1 (Load Output Value for edge_1 of Lo-leg 3rdPort)
	out res[r8], r11

	// Edge_1 Channel_1 Hi-Leg
	ldw r11, r4[2]
	add r11, r9, r11
	setpt res[r1], r11
	ldw r11, r4[3]
	out res[r1], r11

	// Edge_1 Channel_1 Lo-Leg
	ldw r11, r4[6]
	add r11, r9, r11
	setpt res[r7], r11
	ldw r11, r4[7]
	out res[r7], r11

	// Edge_1 Channel_0 Hi-Leg
	ldw r11, r3[2]
	add r11, r9, r11
	setpt res[r0], r11
	ldw r11, r3[3]
	out res[r0], r11

	// Edge_1 Channel_0 Lo-Leg
	ldw r11, r3[6]
	add r11, r9, r11
	setpt res[r6], r11
	ldw r11, r3[7]
	out res[r6], r11

	// trigger adc
	#if LOCK_ADC_TO_PWM
	ldw r11, sp[16] // r11 = p16_adc_sync (ADC synchronisation port)
	ldc r10, HALF_DEAD_TIME // r10 = 60 (HALF_DEAD_TIME)
	add r10, r9, r10	// r10 += r9 (Time-stamp + half of Dead-time)
	setpt res[r11], r10 // resource[p16_adc_sync].time = (set time for next transfer on ADC Sync Port)
	ldw r10, sp[15] // r10 = c_adc_trig (load adc trig chanend)
	in r11, res[r11] // r11 = resource[p16_adc_sync].val (Wait until time to input data)
	outct res[r10], XS1_CT_END // resource[c_adc_trig].val = XS1_CT_END ( send adc trig token)
	#endif

	ldw r10, sp[11] // r10 = sp[11] (chanend c_pwm)
	ldap r11, L_READ_NEW_BUF			// r11 = PC + 2xL_READ_NEW_BUF	
	setv res[r10], r11				// resource[c_pwm].vect = L_READ_NEW_BUF (Use Relative address)
	eeu res[r10]							// resource[c_pwm].enable 
	setsr 0x1									// EEBLE (Enable Thread Events - If c_pwm has data jump to L_READ_NEW_BUF)

	// NB Continue if no data on c_pwm
	// clear events
	clrsr 0x1									// EEBLE (Clear Thread Events - Queue Pending Events)
	clre											// Clear all thread enabling flags

	bu L_MODE_3 // repeat old Mode_3 data

L_READ_NEW_BUF: // Wait for new data to arrive
	// Expected registers values on entry:
	// r10: c_pwm

	chkct res[r10], 0x1	// discard resource[c_pwm].token if equal to  1  
	outct res[r10], 0x1	// output token of value 1 on channel c_pwm
	in r0, res[r10]			// r0 = c_pwm data (Wait until new buf_id ready on c_pwm -- NB signals next data ready)
	chkct res[r10], 0x1
	outct res[r10], 0x1

	bu L_READ_NEW_DATA

.cc_bottom pwm_op_inv.func
