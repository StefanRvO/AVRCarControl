;R21,R22,R23 is state registers, R21 holds recived data, R22 holds state (Automode, etc) and R23 holds mode , Get,Set.. etc. Memory adress 0x200-0x202 holds former states
;VERY buggy
.include "m32def.inc"

.org    0x0000
.include "SetupInterrupts.asm"   ;setup Interrupts
.org    0x0060
Reset:
.include "SetupStack.asm"       ;setup the stack
.include "SetupSerial.asm"      ;setup serial connection
.include "SetupIO.asm"
ldi R23,0xFF
ldi R22,0xFF
ldi R21,0xFF


    sei                         ;enable interrupts
    jmp     Main
    
;****
;ROUTINES
;****
;******************* RECIVE INTERRUPT
RX_ISR: ;We always recive 3 bytes, put them in R16:R18
    ;Push  to stack
    push    R16
    push    R17
    push    R18
    in      R16,SREG
    push    R16
    in      R16,UDR ;read recived into R16
    ;wait for new byte
    RX_WAIT1:
    SBIS    UCSRA,RXC
    RJMP    RX_WAIT1
    in  R17,UDR     ;Read into R17
    RX_WAIT2:
    SBIS    UCSRA,RXC
    RJMP    RX_WAIT2
    in    R18,UDR   ;Read into R18
    CALL StateSet
    pop     R18
    out     SREG,R18
    pop     R18
    pop     R17
    pop     R16
RETI
StateSet:
    ;Set the states in Reg35-33
    sts 0x200,R23
    sts 0x201,R22
    sts 0x202,R21
    
    cpi R16,0x55    ;Set mode?
    BRNE Checkget
    ldi R23,0x00
    mov R22,r17
    mov R21,r18
    ret
    Checkget:
    
    cpi R16,0xaa    ;Get mode?
    brne endcheck
    ldi R23,0x01
    mov R22,R17
    mov R21,R18
    endcheck:
    ret
    
    
    

TRANSREPLY:  ;Sends the data in R17:R19
    SBIS    UCSRA,UDRE
    RJMP    TRANSREPLY
    out     UDR,R17
    TRANSREPLY1:
    SBIS    UCSRA,UDRE
    RJMP    TRANSREPLY1
    out     UDR,R18
    TRANSREPLY2:
    SBIS    UCSRA,UDRE
    RJMP    TRANSREPLY2
    out     UDR,R19
RET
;***************

SETSPEED:
    cpi R23,0x00
    breq    PC+2
    ret
    SETSPEED2:
    cpi R22,0x10
    breq    PC+2
    ret
    SETSPEED3:
    nop
    out PORTB,R21
rjmp SETSPEED  ; SET motor speed dependent on R18 value

STOP:
    cpi R23,0x00
    breq    PC+2
    ret
    cpi R22,0x11
    breq    PC+2
    ret
    ldi R21,0x00
    out PORTB,R21
ret

AutoMode:
    cpi R23,0x00
    breq    PC+2
    ret
    cpi R22,0x12
    breq    PC+2
    ret
    ldi R21,0xee   
    out PORTB,R18
rjmp    AutoMode

SET:
    cpi R23,0x00
    breq SET1
    ret
    SET1:
    cpi R22,0x10
    brne SET2
    call SETSPEED
    SET2:
    cpi R22,0x11
    brne SET3
    call STOP
    SET3:
    cpi R22,0x12
    brne SET4
    call AutoMode
    SET4:
rjmp SET

Get:
    cpi R23,0x01
    breq GETCHECK1
    ret
    GETCHECK1:
    cpi  R22,0x10 ;Get speed data
    brne    GETCHECK2
    call GETSPEED
    GETCHECK2:
    cpi R22,0x11 
    brne    GETCHECK3
    call GETSTOP     ;Get stop data
    GETCHECK3:
    cpi R22,0x12
    brne    ENDGETCHECK    ;Get Automode data
    call GETAUTOMODE
    ;Return to last state 
    ENDGETCHECK:   
    lds R23,0x200
    lds R22,0x201
    lds R21,0x202
    rjmp Get

GETSPEED:
push    R17
push    R18
push    R19
ldi     R17,0xbb
ldi     R18,0x10
in      R19,PORTB   ;Read value from port B. This should be changed to actual motor speed
CALL    TRANSREPLY
pop     R19
pop     R18
pop     R17
RET

GETSTOP:
push    R17
push    R18
push    R19
push    R20
ldi     R17,0xbb
ldi     R18,0x11
in      R20,PORTB   ;Read value from port B. This should be changed to actual motor speed
ldi     R19,0x00
cpi     R20,0x00
brne    PC+2
ldi     R19,0x01
CALL    TRANSREPLY
pop     R20
pop     R19
pop     R18
pop     R17
RET

GETAUTOMODE:
push    R17
push    R18
push    R19
push    R20
ldi     R17,0xbb
ldi     R18,0x12
lds     R20,0x201
ldi     R19,0x00
cpi     R20,0x12
brne    PC+2
ldi     R19,0x01
CALL    TRANSREPLY
pop     R20
pop     R19
pop     R18
pop     R17
RET
;******
;*MAIN
;******

Main:
    cpi R23,0x00
    brne PC+2
    Call    SET
    cpi R23,0x01
    brne PC+2
    call    Get
RJMP    Main



;;RECODE TO WHILE LOOPS...!! CPI, BREQ +2, RET..??
