
.include "m32def.inc"

.org    0x0000
.include "SetupInterrupts.asm"   ;setup Interrupts
.org    0x0060
Reset:
.include "SetupStack.asm"       ;setup the stack
.include "SetupSerial.asm"      ;setup serial connection
.include "SetupIO.asm"

    sei                         ;enable interrupts
    jmp     Main
    
;****
;ROUTINES
;****
;******************* RECIVE INTERRUPT
RX_ISR: ;We always recive 3 bytes, put them in R16:R18
push    R16 ;Push  to stack
push    R17
push    R18
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
CALL STATESET
pop     R18
pop     R17
pop     R16
RETI


;****************************CHANGE STATE
STATESET:
CPI R16,0x55
BRNE    PC+2
CALL     SET
STATESET1:
CPI R16,0xAA
BRNE    PC+2
CALL     GET
STATERET:
RET
;******************

;*************Set mode
SET:	
;call specific loop
CPI R17,0x10
BRNE    PC+2
CALL SETSPEED
CPI R17,0x11
BRNE    PC+2
CALL STOP
CPI R17,0x12
BRNE    PC+2
CALL AUTOMODE
RET
;*********
;****************GETMODE
GET:
push    R17         
push    R18
push    R19
ldi     R17,0xBB
;****                   ;HERE WE SHOULD
ldi     R18,0x00        ;FETCH THE WANTED 
in      R19,PORTB       ;DATA
;****                   ;
CALL    TRANSREPLY
pop     R17
pop     R18
pop     R19
RET
;******************

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
;GET OUT OF INTERRUPT MODE, clear the stack 
		ldi		R16, HIGH(RAMEND)       ;THIS IS UGLY
		out		SPH, R16                ;ANOTHER
		ldi		R16, LOW(RAMEND)        ;SOLUTION
		out		SPL, R16                ;IS NEEDED!!
	    sei		
;*********
nop
out PORTB,R18
jmp Main ; SET motor speed dependent on R18 value

STOP:
;GET OUT OF INTERRUPT MODE, clear the stack 
		ldi		R16, HIGH(RAMEND)       ;THIS IS UGLY
		out		SPH, R16                ;ANOTHER
		ldi		R16, LOW(RAMEND)        ;SOLUTION
		out		SPL, R16                ;IS NEEDED!!
	    sei		
;*********
ldi R18,0x00
out PORTB,R18
jmp Main
AUTOMODE:
;GET OUT OF INTERRUPT MODE, clear the stack 
		ldi		R16, HIGH(RAMEND)       ;THIS IS UGLY
		out		SPH, R16                ;ANOTHER
		ldi		R16, LOW(RAMEND)        ;SOLUTION
		out		SPL, R16                ;IS NEEDED!!
	    sei		
;*********
ldi R18,0xee   
out PORTB,R18
jmp AUTOMODE
;******
;*MAIN
;******
Main:
RJMP    Main



;;RECODE TO WHILE LOOPS...!! CPI, BREQ +2, RET..??
