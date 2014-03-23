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
.equ TickTime5=0x262
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
.include "SetupSerial.asm"      ;setup serial connection
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
    sts PrevTime1,R16
    sts PrevTime2,R16
    sts PrevTime3,R16
    sts PrevTime4,R16
    sts PrevTime5,R16
    sts TickTime1,R16
    sts TickTime2,R16
    sts TickTime3,R16
    sts TickTime4,R16
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
;***********INT0,MOTOR SENSOR
;******************
INT0_ISR:
push R20
in R20,SREG
push R20
push R21
push R22
;Read Current time in
    ;fetch clock
    in   R20,TCNT1L ;Timer 1 low
    in   R21,TCNT1H ;Timer 1 high 
    in R22,TIFR
push R16
push R17
push R18
push R19
push R23
push R24
push R25
    lds  R23,T1_Counter1     ;what if timer overflows while in interrupt?
    lds  R24,T1_Counter2
    lds  R25,T1_Counter3
    sbrs R22,TOV1
    rjmp CLOCK_OFLW_END_INT0
    ldi R16,0x00
    cpse R21,R16
    rjmp CLOCK_OFLW_END_INT0
    inc R23
    cpse R23,R16
    rjmp CLOCK_OFLW_END_INT0
    inc R24
    cpse R24,R16
    rjmp CLOCK_OFLW_END_INT0
    inc R25
    
CLOCK_OFLW_END_INT0:
;Read previeus time in
lds R16,PrevTime1
lds R17,PrevTime2
lds R18,PrevTime3
lds R19,PrevTime4
lds R22,PrevTime5

sts	PrevTime1,R20
sts	PrevTime2,R21
sts	PrevTime3,R23
sts	PrevTime4,R24
sts	PrevTime5,R25
SUB	R20,R16
SBC	R21,R17
SBC	R23,R18
SBC	R24,R19
SBC	R25,R22
;Load into memry
sts TickTime1,R25
sts TickTime2,R24
sts TickTime3,R23
sts TickTime4,R21
sts TickTime5,R20
ldi R16,0x11
out PORTB,R16



;counter
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
pop R25
pop R24
pop R23
pop R19
pop R18
pop R17
pop R16
pop R22
pop R21
pop R20
out SREG,R20
pop R20
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
brne    GETSTOPTEST
CALL GETSPEED
GETSTOPTEST:
cpi R17,0x11 ;Get stop
brne    GETAUTOMODETEST
CALL GETSTOP
GETAUTOMODETEST:
cpi R17,0x12    ;Get automode
brne    GETTIMETEST
CALL GETAUTOMODE
GETTIMETEST:
cpi R17,0x13    ;Get timer status
brne GETACCELTEST
CALL    GETTIME
GETACCELTEST:
cpi R17,0x14
brne GETMOTORCOUNTERTEST
call    GETACCEL
GETMOTORCOUNTERTEST:
cpi R17,0x15
brne GETTPRTEST
call GETMOTORCOUNTER
GETTPRTEST:
cpi R17,0x16
brne ENDGET
call GETTPR
ENDGET:
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

GETTPR: ;Send ticks between last two motor rotations7
push R16
push R17
push R20
push R21
push R22
lds R16,TickTime1
lds R17,TickTime2
lds R20,TickTime3
lds R21,TickTime4
lds R22,TickTime5
ldi	ZH,high(TransMSG<<1)	; make high byte of Z point at address of msg
ldi ZL,low(TransMSG<<1)
ST Z+,R16
ST Z+,R17
ST Z+,R20
ST Z+,R21
ST Z+,R22
ldi R16,0x05
sts TransNum,R16
ldi R20,0xbb
ldi R21,0x16
CALL TRANSREPLY
pop R22
pop R21
pop R20
pop R17
pop R16
RET

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
;lds R16,MotorSensorCount2
;out PORTB,R16
RJMP    MainLoop


GetACCELLoop:
CALL GETACCEL
rjmp GetACCELLoop

;;Kør motor sensor ind på T0 ben og sæt rise on falling edge. Timer interrupt sættes med OCR0.
; Dermed Vil vi kunne vælge  at få et interrupt pr. x omdrejning. 0<x<(255/3)
;GOD LØSNING!!! Måske ikke nødvendig
