// doPWM8(out port:32 eight_bit_port, int *program)
// see doc/index.rst for a guide to programming.

    .section .dp.rodata,"awd",@progbits

    .align 4
    .globl stableZero
    .globl changeZero
    .globl loopEven
    .globl loopOdd
stableZero: .word stable3 + 6
changeZero: .word change1 + 4
loopEven: .word stableloopeven
loopOdd: .word stableloopodd

    .text
    
    .align 4
    .globl doPWM8
    .linkset doPWM8.nstackwords, 4
    .globl doPWM8.nstackwords
    
doPWM8:
    entsp 4
    stw dp, sp[1]
    outct res[r1], 1
    chkct res[r1], 1
    in r2, res[r1]
    outct res[r1], 1
    set dp, r2
    bu setTime

doReturn:
    ldw dp, sp[1]
    retsp 4
    
    
change39:    
    ldw r1, dp[43]
    out res[r0], r1
change38:    
    ldw r1, dp[42]
    out res[r0], r1
change37:    
    ldw r1, dp[41]
    out res[r0], r1
change36:    
    ldw r1, dp[40]
    out res[r0], r1
change35:    
    ldw r1, dp[39]
    out res[r0], r1
change34:    
    ldw r1, dp[38]
    out res[r0], r1
change33:    
    ldw r1, dp[37]
    out res[r0], r1
change32:    
    ldw r1, dp[36]
    out res[r0], r1
change31:    
    ldw r1, dp[35]
    out res[r0], r1
change30:    
    ldw r1, dp[34]
    out res[r0], r1
change29:    
    ldw r1, dp[33]
    out res[r0], r1
change28:    
    ldw r1, dp[32]
    out res[r0], r1
change27:    
    ldw r1, dp[31]
    out res[r0], r1
change26:    
    ldw r1, dp[30]
    out res[r0], r1
change25:    
    ldw r1, dp[29]
    out res[r0], r1
change24:    
    ldw r1, dp[28]
    out res[r0], r1
change23:    
    ldw r1, dp[27]
    out res[r0], r1
change22:    
    ldw r1, dp[26]
    out res[r0], r1
change21:    
    ldw r1, dp[25]
    out res[r0], r1
change20:    
    ldw r1, dp[24]
    out res[r0], r1
change19:    
    ldw r1, dp[23]
    out res[r0], r1
change18:    
    ldw r1, dp[22]
    out res[r0], r1
change17:    
    ldw r1, dp[21]
    out res[r0], r1
change16:    
    ldw r1, dp[20]
    out res[r0], r1
change15:    
    ldw r1, dp[19]
    out res[r0], r1
change14:    
    ldw r1, dp[18]
    out res[r0], r1
change13:    
    ldw r1, dp[17]
    out res[r0], r1
change12:    
    ldw r1, dp[16]
    out res[r0], r1
change11:    
    ldw r1, dp[15]
    out res[r0], r1
change10:    
    ldw r1, dp[14]
    out res[r0], r1
change9:    
    ldw r1, dp[13]
    out res[r0], r1
change8:    
    ldw r1, dp[12]
    out res[r0], r1
change7:    
    ldw r1, dp[11]
    out res[r0], r1
change6:    
    ldw r1, dp[10]
    out res[r0], r1
change5:    
    ldw r1, dp[9]
    out res[r0], r1
change4:    
    ldw r1, dp[8]
    out res[r0], r1
change3:    
    ldw r1, dp[7]
    out res[r0], r1
change2:    
    ldw r1, dp[6]
    out res[r0], r1
change1:    
    ldw r1, dp[5]
    out res[r0], r1
    ldw r1, dp[4]
    out res[r0], r1
    ldw r2, dp[2]
    bau r2

stable10: 
    out res[r0], r1
stable9:  
    out res[r0], r1
stable8:  
    out res[r0], r1
stable7:  
    out res[r0], r1
stable6:  
    out res[r0], r1
stable5:  
    out res[r0], r1
stable4:  
    out res[r0], r1
stable3:  
    out res[r0], r1
    ldw r2, dp[1]
    out res[r0], r1
    ldw dp, dp[0]
    out res[r0], r1
    bau r2

stableloopodd:  
    out res[r0], r1
stableloopeven:  
    out res[r0], r1
    ldw r11, dp[3]
stableloop:
    out res[r0], r1
    sub r11, r11, 2
    out res[r0], r1
    bt r11, stableloop
    out res[r0], r1
    ldw r2, dp[1]
    out res[r0], r1
    ldw dp, dp[0]
    out res[r0], r1
    bau r2


    
setTime:
    ldw r2, dp[2]
    ldw r1, dp[3]
    syncr res[r0]
    setpt res[r0], r2
    out res[r0], r1
    ldw r2, dp[1]
    ldw dp, dp[0]
    bau r2



    .globl change9
    .globl change8
    .globl change7
    .globl change6
    .globl change5
    .globl change4
    .globl change3
    .globl change2
    .globl change1
    .globl change
    .globl stable29
    .globl stable28
    .globl stable27
    .globl stable26
    .globl stable25
    .globl stable24
    .globl stable23
    .globl stable22
    .globl stable21
    .globl stable20
    .globl stable19
    .globl stable18
    .globl stable17
    .globl stable16
    .globl stable15
    .globl stable14
    .globl stable13
    .globl stable12
    .globl stable11
    .globl stable10
    .globl stable9
    .globl stable8
    .globl stable7
    .globl stable6
    .globl stable5
    .globl stable4
    .globl stable3

    .globl setTime
