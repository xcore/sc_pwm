// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

// doPWM8(out port:32 eight_bit_port, streaming chanend c)
// see doc/index.rst for a guide to programming.

// guide to registers:
// r0: contains the port resource identifier. Should be an 8-bit port.
// r1: contains the channel resource identifier; must be streaming.
// r2: used as register for branching to.
// r3: contains current value to be output to port
// r11: temp value for loop counting.

    
    .section .dp.rodata,"awd",@progbits

    .align 4
    .globl stableZero
    .globl changeZero
    .globl loopAround
stableZero: .word stable4 + 8
changeZero: .word change1 + 4
loopAround: .word stableloop

    .text
    
    .align 4
    .globl doPWM8
    .linkset doPWM8.nstackwords, 4
    .globl doPWM8.nstackwords
    
doPWM8:
    entsp 4
    stw dp, sp[1]
    outct res[r1], 0              // Inform control thread that we are ready
    in r2, res[r1]
    set dp, r2
    bu setTime

doReturn:
    ldw dp, sp[1]
    retsp 4
    
    .align 4
change39:    
    ldw r3, dp[20]
    out res[r0], r3
change38:    
    ldw r3, dp[21]
    out res[r0], r3
change37:    
    ldw r3, dp[22]
    out res[r0], r3
change36:    
    ldw r3, dp[23]
    out res[r0], r3
change35:    
    ldw r3, dp[24]
    out res[r0], r3
change34:    
    ldw r3, dp[25]
    out res[r0], r3
change33:    
    ldw r3, dp[26]
    out res[r0], r3
change32:    
    ldw r3, dp[27]
    out res[r0], r3
change31:    
    ldw r3, dp[28]
    out res[r0], r3
change30:    
    ldw r3, dp[29]
    out res[r0], r3
change29:    
    ldw r3, dp[30]
    out res[r0], r3
change28:    
    ldw r3, dp[31]
    out res[r0], r3
change27:    
    ldw r3, dp[32]
    out res[r0], r3
change26:    
    ldw r3, dp[33]
    out res[r0], r3
change25:    
    ldw r3, dp[34]
    out res[r0], r3
change24:    
    ldw r3, dp[35]
    out res[r0], r3
change23:    
    ldw r3, dp[36]
    out res[r0], r3
change22:    
    ldw r3, dp[37]
    out res[r0], r3
change21:    
    ldw r3, dp[38]
    out res[r0], r3
change20:    
    ldw r3, dp[39]
    out res[r0], r3
change19:    
    ldw r3, dp[40]
    out res[r0], r3
change18:    
    ldw r3, dp[41]
    out res[r0], r3
change17:    
    ldw r3, dp[42]
    out res[r0], r3
change16:    
    ldw r3, dp[43]
    out res[r0], r3
change15:    
    ldw r3, dp[44]
    out res[r0], r3
change14:    
    ldw r3, dp[45]
    out res[r0], r3
change13:    
    ldw r3, dp[46]
    out res[r0], r3
change12:    
    ldw r3, dp[47]
    out res[r0], r3
change11:    
    ldw r3, dp[48]
    out res[r0], r3
change10:    
    ldw r3, dp[49]
    out res[r0], r3
change9:    
    ldw r3, dp[50]
    out res[r0], r3
change8:    
    ldw r3, dp[51]
    out res[r0], r3
change7:    
    ldw r3, dp[52]
    out res[r0], r3
change6:    
    ldw r3, dp[53]
    out res[r0], r3
change5:    
    ldw r3, dp[54]
    out res[r0], r3
change4:    
    ldw r3, dp[55]
    out res[r0], r3
change3:    
    ldw r3, dp[56]
    out res[r0], r3
change2:    
    ldw r3, dp[57]
    out res[r0], r3
change1:    
    ldw r3, dp[58]
    out res[r0], r3
    ldw r3, dp[59]
    out res[r0], r3
    ldw r2, dp[61]
    bau r2

stable15: 
    out res[r0], r3
stable14: 
    out res[r0], r3
stable13: 
    out res[r0], r3
stable12: 
    out res[r0], r3
stable11: 
    out res[r0], r3
stable10: 
    out res[r0], r3
stable9:  
    out res[r0], r3
stable8:  
    out res[r0], r3
stable7:  
    out res[r0], r3
stable6:  
    out res[r0], r3
stable5:  
    out res[r0], r3
stable4:  
    out res[r0], r3
    ldw dp, dp[63]
    out res[r0], r3
    ldw r2, dp[62]
    out res[r0], r3
    bau r2

stableloop:  
    out res[r0], r3
    out res[r0], r3
    ldw r2, dp[60]
    out res[r0], r3
    sub r11, r2, 10
    out res[r0], r3
    zext r2, 1
    out res[r0], r3
    bf  r2, skipone
    out res[r0], r3
skipone:    
    out res[r0], r3
    shr r11, r11, 1
dostableloop:
    out res[r0], r3
    sub r11, r11, 1
    out res[r0], r3
    bt r11, dostableloop
    out res[r0], r3
    ldw dp, dp[63]
    out res[r0], r3
    ldw r2, dp[62]
    out res[r0], r3
    bau r2


    
setTime:
    ldw r3, dp[60]
    out res[r0], r3
    ldw r2, dp[61]
    ldc r11, 3
    andnot r2, r11
    ldc r11, 16
    sub r2, r2, r11
    syncr res[r0]
    setpt res[r0], r2
    out res[r0], r3
    out res[r0], r3
    ldw dp, dp[63]
    out res[r0], r3
    ldw r2, dp[62]
    out res[r0], r3
    bau r2


    .globl setTime
