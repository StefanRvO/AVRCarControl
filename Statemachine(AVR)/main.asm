.equ T1_Counter1 = 0x250
.equ T1_Counter2 = 0x251
.equ T1_Counter3 = 0x252
.equ PrevTime1=0x253
.equ PrevTime2=0x254
.equ PrevTime3=0x255
.equ PrevTime4=0x256
.equ PrevTime5=0x257
.equ TickTime1=0x258
.equ TickTime2=0x259
.equ TickTime3=0x260
.equ TickTime4=0x261
.equ MotorSensorCount1 = 0x500 ;Counter for the motor sensor
.equ MotorSensorCount2=0x501
.equ MotorSensorCount3=0x502
.equ TransNum =0x300
.equ TransMSG = 0x301
.equ END_ = 0xFF
.include "m32def.inc"

.org    0x0000
.include "SetupInterrupts.asm"   ;setup Interrupts
.org    0x0060
Reset:
.include "SetupStack.asm"       ;setup the stack
.include "SetupSerial16Mhz.asm"      ;setup serial connection
.include "SetupIO.asm"
.include "SetupTime.asm"
.include "SetupADC.asm"

    sei                         ;enable interrupts
    ldi R16,0x00
    sts TransNum,R16
    sts T1_Counter1,R16  ;zero counter stuff
    sts T1_Counter2,R16  ;zero counter stuff
    sts T1_Counter3,R16  ;zero counter stuff
    sts MotorSensorCount1,R16 ;Clear motor counter
    sts MotorSensorCount2,R16 ;Clear motor counter
    sts MotorSensorCount3,R16 ;Clear motor counter
    jmp     Main
    
;****
;ROUTINES
;****

;******************* Timer1 Overflow Interrupt
T1_OVFLW:
push    R16
in      R16,SREG
push    R16
lds     R16,T1_Counter1
inc     R16
sts     T1_Counter1,R16
BRNE    T1_OVFLW_END
lds     R16,T1_Counter2
inc     R16
sts     T1_Counter2,R16
;out     PORTB,R16 ;Debugger
BRNE    T1_OVFLW_END
lds     R16,T1_Counter3
inc     R16
sts     T1_Counter3,R16 
T1_OVFLW_END:
pop     R16
out     SREG,R16
pop     R16
reti

;******************
;***********INT1,MOTOR SENSOR
;******************
INT0_ISR:
push R16
in R16,SREG
push R16
push R17
push R18
push R19
push R20
push R21
push R22
push R23
push R24
push R25
lds R16,MotorSensorCount1 ;Read in motor counter
lds R17,MotorSensorCount2 ;Read in motor counter
lds R18,MotorSensorCount3 ;Read in motor counter
inc R16 ;Increase it
brne INT0_Counter_Done
inc R17
brne INT0_Counter_Done
inc R18
INT0_Counter_Done:
sts MotorSensorCount1,R16
sts MotorSensorCount2,R17
sts MotorSensorCount3,R18
INT0_ISR_END:
;Calculate time since last tick and store in Memory

;Read previeus time in
lds R16,PrevTime1
lds R17,PrevTime2
lds R18,PrevTime3
lds R19,PrevTime4
lds R20,PrevTime5
;Read Current time in
CLC
in   R21,TCNT1L ;Timer 1 low
lds  R23,T1_Counter1     ;what if timer overflows while in interrupt?
lds  R24,T1_Counter2
lds  R25,T1_Counter3
in  R22,TIFR
SBRS    R22,TOV1 ;Increment R23 if we have a overflow
inc R23
cpi R23,0x00
BRNE    END_INC_INT0
inc R24
cpi R24,0x00
BRNE    END_INC_INT0
inc R25
END_INC_INT0:
in   R22,TCNT1H ;Timer 1 high
sts	PrevTime1,R21
sts	PrevTime2,R22
sts	PrevTime3,R23
sts	PrevTime4,R24
sts	PrevTime5,R25
SUB	R21,R16
SBC	R22,R17
SBC	R23,R18
SBC	R24,R19
SBC	R25,R20
;Load into memry
sts TickTime1,R21
sts TickTime2,R22
sts TickTime3,R23
sts TickTime4,R24
pop R25
pop R24
pop R23
pop R22
pop R21
pop R20
pop R19
pop R18
pop R17
pop R16
out SREG,R16
pop R16
RETI
;*******************
;******************* RECIVE INTERRUPT
RX_ISR: ;We always recive 3 bytes, put them in R16:R18
push    R16 ;Push  to stack
in      R16,SREG
push    R16
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
out      SREG,R16
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
cpi R17,0x13 ;accell loop, continuesly send accelerometer data
BRNE    PC+2
CALL    GetACCELLoop
RET
;*********
;****************GETMODE
GET:
cpi R17,0x10 ;Get speed
brne    PC+2
CALL GETSPEED
cpi R17,0x11 ;Get stop
brne    PC+2
CALL GETSTOP
cpi R17,0x12    ;Get automode
brne    PC+2
CALL GETAUTOMODE
cpi R17,0x13    ;Get timer status
brne PC+2
CALL    GETTIME
cpi R17,0x14
brne PC+2
call    GETACCEL
cpi R17,0x15
brne PC+2
call GETMOTORCOUNTER
cpi R17,0x16
brne PC+2
call GETTPR
RET
;******************
GETSPEED:
push R20
push R21
ldi	ZH,high(TransMSG<<1)	; make high byte of Z point at address of msg
ldi ZL,low(TransMSG<<1)
in  R20,OCR2
ST  Z+,R20
ldi R20,1
sts  TransNum,R20
ldi R20,0xBB
ldi R21,0x10
call TRANSREPLY
pop R21
pop R22
ret

GETTPR: ;Send ticks between last two motor rotations
push R20
push R21
push R22
push R23
;Load from RAM
lds R20,TickTime1
lds R21,TickTime2
lds R22,TickTime3
lds R23,TickTime4
ldi	ZH,high(TransMSG<<1)	; make high byte of Z point at address of msg
ldi ZL,low(TransMSG<<1)
in  R20,OCR2
ST  Z+,R20
ST  Z+,R21
ST  Z+,R22
st  Z+,R23
ldi R20,4
sts TransNum,R20
ldi R20,0xbb
ldi R21,0x17
Call TRANSREPLY
pop R23
pop R22
pop R21
pop R20
GETSTOP:
nop ;Does nothing ATM
ret

GETAUTOMODE:
nop ;Does nothing ATM
ret

GETACCEL: ;Read adc at PA0
SBI ADCSRA,ADSC ;start conversion
push R20
push R21
ldi	ZH,high(TransMSG<<1)	; make high byte of Z point at address of msg
ldi ZL,low(TransMSG<<1)
WAITADC:
SBIS ADCSRA,ADIF ;is adc done?
rjmp    WAITADC
in R20,ADCL
in R21,ADCH
;out PORTB,R21 ;Put value (first 8 bit) on port b (for debugging..?)
ST  Z+,R21 
ST  Z+,R20         ;         ; Put in RAM for transfer
ldi R20,2        ;
sts  TransNum,R20          ;
ldi R20,0xBB ;Response headers
ldi R21,0x14
CALL TRANSREPLY
pop R21
pop R20
RET


GETTIME: ;Send the speed
    push R20
    push R21
    push R22
    push R23
    push R24
    CLC     ;Clear carry flag
    ;fetch clock
    in   R20,TCNT1L ;Timer 1 low
    lds  R22,T1_Counter1     ;what if timer overflows while in interrupt?
    lds  R23,T1_Counter2
    lds  R24,T1_Counter3
    in  R21,TIFR
    SBRS    R21,TOV1 ;Increment R22 if we have a overflow
    inc R22
    cpi R22,0x00
    BRNE    END_INC_GETTIME
    inc R23
    cpi R23,0x00
    BRNE    END_INC_GETTIME
    inc R24
    END_INC_GETTIME: 
    in   R21,TCNT1H ;Timer 1 high 
    ;fetch done
    ;Put Time in TransMSG
    ldi	ZH,high(TransMSG<<1)	; make high byte of Z point at address of msg
    ldi ZL,low(TransMSG<<1)
    ST  Z+,R24
    ST  Z+,R23
    ST  Z+,R22
    ST  Z+,R21
    ST  Z+,R20
    ldi  R20,5
    sts  TransNum,R20
    ldi  R20,0xBB ;Respond header
    ldi  R21,0x13
    call    TRANSREPLY
    pop R24
    pop R23
    pop R22
    pop R21
    pop R20
    ret

GETMOTORCOUNTER: ;Send the motor counter
    push R20
    push R21
    push R22
    ;fetch motor counter
    lds  R22,MotorSensorCount1
    lds  R21,MotorSensorCount2
    lds  R20,MotorSensorCount3
    ;Put counter in TransMSG
    ldi	ZH,high(TransMSG<<1)	; make high byte of Z point at address of msg
    ldi ZL,low(TransMSG<<1)
    ST  Z+,R20
    ST  Z+,R21
    ST  Z+,R22
    ldi  R20,3
    sts  TransNum,R20
    ldi  R20,0xBB ;Respond header
    ldi  R21,0x15
    call    TRANSREPLY
    pop R22
    pop R21
    pop R20
    ret

TRANSREPLY:  ;Sends the data in R20:R21 (header), followed by data starting from 0x301 and forward the number of bytes in 0x300
SBIS    UCSRA,UDRE
RJMP    TRANSREPLY
out     UDR,R20
TRANSREPLY1:
SBIS    UCSRA,UDRE
RJMP    TRANSREPLY1
out     UDR,R21
ldi	ZH,high(TransMSG<<1)	; make high byte of Z point at address of msg
ldi ZL,low(TransMSG<<1)
push R22
push R23
lds R23,TransNum
inc R23 ;Need to inc to get correct count
TRANSREPLYloop:
SBIS    UCSRA,UDRE
RJMP    TRANSREPLYloop
dec    R23
BREQ   TRANSREPLYEXIT
ld     R22,Z+
out     UDR,R22
rjmp    TRANSREPLYloop
TRANSREPLYEXIT:
pop R23
pop R22
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
nop ;convert from 0-100 to 0-255
out OCR2,R18
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
out OCR2,R18
jmp Main
AUTOMODE:
;GET OUT OF INTERRUPT MODE, clear the stack 
		ldi		R16, HIGH(RAMEND)       ;THIS IS UGLY
		out		SPH, R16                ;ANOTHER
		ldi		R16, LOW(RAMEND)        ;SOLUTION
		out		SPL, R16                ;IS NEEDED!!
	    sei		
;*********
ldi R18,0x00
AutoModeLoop:
dec R18   ;Do some artimitic, this is just a placeholder
out OCR2,R18
jmp AutoModeLoop
;******
;*MAIN
;******
Main:
MainLoop:
lds R23,MotorSensorCount3
out	PORTB,R23
RJMP    MainLoop


GetACCELLoop:
CALL GETACCEL
rjmp GetACCELLoop

;;Kør motor sensor ind på T0 ben og sæt rise on falling edge. Timer interrupt sættes med OCR0.
; Dermed Vil vi kunne vælge  at få et interrupt pr. x omdrejning. 0<x<(255/3)
;GOD LØSNING!!! Måske ikke nødvendig
