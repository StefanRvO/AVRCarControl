.equ        T1_Counter1 = 0x060
.equ        T1_Counter2 = 0x061
.equ        T1_Counter3 = 0x062
.equ        MotorSensorCount1 = 0x063 ;Counter for the motor sensor
.equ        MotorSensorCount2=0x064
.equ        MotorSensorCount3=0x065
.equ        TransNum =0x066
.equ        TransMSG = 0x067 ;//Alocate 10 bytes
.equ        END_ = 0xFF
.equ        AutoModeState=0x071 ;//States: 0x00=Mapping. First lap, 0x01==Calculate, 0x02=Drive
.equ        CurReading=0x072
.equ        ReadingsCur1=0x073 ;//high pointer adress
.equ        ReadingsCur2=0x074 ;//Low pointer adress
.equ        Readings=0x075 ; Here we put in our ADC readings //Alocate 64 bytes
.equ        CarLane =0x0b5
.equ        TURNMAG=8

.equ        BUFFERSIZE=32
.equ        ACCELADJUST=2
.include    "m32Adef.inc"

.org        0x0000
.include    "SetupInterrupts.asm"   ;setup Interrupts
.org        0x0060
Reset:
.include    "SetupStack.asm"       ;setup the stack
.include    "SetupSerial16Mhz.asm"      ;setup serial connection
.include    "SetupIO.asm"
.include    "SetupTime.asm"
.include    "SetupADC.asm"
.include    "ADCAverageStart.asm"

    sei                         ;enable interrupts
    ldi R16,0x00
    sts TransNum,R16
    sts T1_Counter1,R16  ;zero counter stuff
    sts T1_Counter2,R16  ;zero counter stuff
    sts T1_Counter3,R16  ;zero counter stuff
    sts MotorSensorCount1,R16 ;Clear motor counter
    sts MotorSensorCount2,R16 ;Clear motor counter
    sts MotorSensorCount3,R16 ;Clear motor counter
    ldi R16,HIGH(Readings)
    sts ReadingsCur1,R16
    ldi R16,LOW(Readings)
    sts ReadingsCur2,R16
    jmp     Main
    
;****
;ROUTINES
;****

;******************* Timer1 Overflow Interrupt
T1_OVFLW:
    push        R16
    in          R16,SREG
    push        R16
    lds         R16,T1_Counter1
    inc         R16
    sts         T1_Counter1,R16
    BRNE        T1_OVFLW_END
    lds         R16,T1_Counter2
    inc         R16
    sts         T1_Counter2,R16
    ;out        PORTB,R16 ;Debugger
    BRNE        T1_OVFLW_END
    lds         R16,T1_Counter3
    inc         R16
    sts         T1_Counter3,R16

    T1_OVFLW_END:
    CALL        ADCSAMPLE
    pop         R16
    out         SREG,R16
    pop         R16
reti

;******************
;***********INT1,MOTOR SENSOR
;******************
INT0_ISR:
    push        R16
    in          R16,SREG
    push        R16
    push        R17
    push        R18
    lds         R16,MotorSensorCount1 ;Read in motor counter
    lds         R17,MotorSensorCount2 ;Read in motor counter
    lds         R18,MotorSensorCount3 ;Read in motor counter
    inc         R16 ;Increase it
    brne        INT0_Counter_Done
    inc         R17
    brne        INT0_Counter_Done
    inc         R18
    INT0_Counter_Done:
    sts         MotorSensorCount1,R16
    sts         MotorSensorCount2,R17
    sts         MotorSensorCount3,R18
    pop         R18
    pop         R17
    pop         R16
    out         SREG,R16
    pop         R16
RETI

INT1_ISR:
    ;CALL 	        GETMOTORCOUNTER ;Print Out Motor counter
    CALL	        GETTIME
    ldi 	        R16,0x00
    sts             MotorSensorCount1,R16
    sts             MotorSensorCount2,R16
    sts             MotorSensorCount3,R16
reti 	

;*******************
;******************* RECIVE INTERRUPT
RX_ISR: ;We always recive 3 bytes, put them in R16:R18
    push        R16 ;Push  to stack
    in          R16,SREG
    push        R16
    push        R17
    push        R18
    in          R16,UDR ;read recived into R16
    ;wait for new byte
    RX_WAIT1:
        SBIS        UCSRA,RXC
        RJMP        RX_WAIT1
        in          R17,UDR     ;Read into R17
    RX_WAIT2:
        SBIS        UCSRA,RXC
        RJMP        RX_WAIT2
        in          R18,UDR   ;Read into R18
    CALL        STATESET
    pop         R18
    pop         R17
    pop         R16
    out         SREG,R16
    pop         R16
RETI

ADCSAMPLE: ;Get an ADC Sample and Put it into a ring buffer
    push        R19
    push        R18
    push        R17
    push        ZL
    push        ZH

    ;Read In ADC
    in          R19,ADCH
    ldi         R18,ACCELADJUST ;//Adjust for 0g error on accel
    ADD         R19,R18
    ;out        PORTB,R19 ;Debug

    ;ANDI       R19,0b00001111
    ;out        PORTB,R19 ;Debug
    ldi	        ZH,high(Readings)	; make high byte of Z point at the Readings list
    ldi         ZL,low(Readings)

    ldi         R18,0x00
    lds         R17,CurReading
    sub         R18,R17

    Loop:
        cpi         R18,0x00
        breq        STOPINC
        inc         R18
        ADIW        ZL,1
        rjmp        Loop

    STOPINC:
    st          Z,R19
    inc         R17
    cpi         R17,BUFFERSIZE
    brne        ENDT1
    ldi         R17,0x00
    ENDT1:
    sts         CurReading,R17
    pop         ZH
    pop         ZL
    pop         R17
    pop         R18
    pop         R19
    ret


MakeAverage: ;//Read in from the Readings circle buffer, calculate the average. Put in R20

    push        R18
    push        R19
    push        R23
    push        R21
    push        ZH
    push        ZL
    ldi         R20,0x00 ;Here we hold the sum
    ldi         R21,0x00
    
    ldi	        ZH,high(Readings)	; make high byte of Z point at the Readings list
    ldi         ZL,low(Readings)
    ldi         R18,0x00
    ldi         R19,0x00
    AverageLoop:
    inc         R18
    LD	        R23,Z+
    add         R20,R23
    adc         R21,R19
    cpi         R18,BUFFERSIZE
    brne        AverageLoop
                    ;//Divide the sum //This doesn't adjust according to BUFFERSIZE. do it yourself!
    LSR         R21
    ROR         R20
    LSR         R21
    ROR         R20
    LSR         R21
    ROR         R20
    LSR         R21
    ROR         R20 //We have divided by 16
    LSR         R21
    ROR         R20
    
    pop         ZL
    pop         ZH
    pop         R21
    pop         R23
    pop         R19
    pop         R18
ret


;****************************CHANGE STATE
STATESET:
    CPI         R16,0x55
    BRNE        PC+2
    CALL        SET
    STATESET1:
    CPI         R16,0xAA
    BRNE        PC+2
    CALL        GET
    STATERET:
RET
;******************

;*************Set mode
SET:	
;call specific loop
    CPI         R17,0x10
    BRNE        PC+2
    CALL        SETSPEED
    CPI         R17,0x11
    BRNE        PC+2
    CALL        STOP
    CPI         R17,0x12
    BRNE        PC+2
    CALL        AUTOMODE
    cpi         R17,0x13 ;accell loop, continuesly send accelerometer data
    BRNE        PC+2
    CALL        GetACCELLoop
RET
;*********
;****************GETMODE
GET:
    cpi         R17,0x10 ;Get speed
    brne        PC+2
    CALL        GETSPEED
    cpi         R17,0x11 ;Get stop
    brne        PC+2
    CALL        GETSTOP
    cpi         R17,0x12    ;Get automode
    brne        PC+2
    CALL        GETAUTOMODE
    cpi         R17,0x14
    brne        PC+2
    call        GETACCEL
    cpi         R17,0x15
    brne        PC+2
    call        GETMOTORCOUNTER
    cpi         R17,0x16    ;Get timer status
    brne        PC+2
    CALL        GETTIME
RET
;******************
GETSPEED:
    push        R20
    push        R21
    ldi	        ZH,high(TransMSG)	; make high byte of Z point at address of msg
    ldi         ZL,low(TransMSG)
    in          R20,OCR2
    ST          Z+,R20
    ldi         R20,1
    sts         TransNum,R20
    ldi         R20,0xBB
    ldi         R21,0x10
    call        TRANSREPLY
    pop         R21
    pop         R22
ret


GETSTOP:
    nop ;Does nothing ATM
ret

GETAUTOMODE:
    nop ;Does nothing ATM
ret

GETACCEL:
    push        R20
    push        R21
    CALL        MakeAverage 
    sts         TransMSG,R20
    ldi         R20,1        ;
    sts         TransNum,R20          ;
    ldi         R20,0xBB ;Response headers
    ldi         R21,0x14
    CALL        TRANSREPLY
    pop         R21
    pop         R20
RET


GETTIME: ;Send the current time
    push        R19
    push        R20
    push        R21
    push        R22
    push        R23
    push        R24
    ;fetch clock
    lds         R22,T1_Counter1     ;what if timer overflows while in interrupt?
    lds         R23,T1_Counter2
    lds         R24,T1_Counter3
    in          R20,TCNT1L
    in          R21,TCNT1H
    in          R19,TIFR
    SBRS        R19	,TOV1 ;Increment  if we have a overflow
    rjmp        END_INC_GETTIME
    cpi         R21,0xff
    brne        INCREASE_GETTIME ;routine is partly ripped of from arduino's micros() code
    cpi         R20,0xfe
    brsh        INCREASE_GETTIME
    rjmp        END_INC_GETTIME
    INCREASE_GETTIME:
    CLC
    inc         R22
    brne        END_INC_GETTIME
    inc         R23
    brne        END_INC_GETTIME
    inc         R24
    END_INC_GETTIME:  
    ;fetch done


    ;Put Time in TransMSG
    ldi	        ZH,high(TransMSG)	; make high byte of Z point at address of msg
    ldi         ZL,low(TransMSG)
    ST          Z+,R24
    ST          Z+,R23
    ST          Z+,R22
    ST          Z+,R21
    ST          Z+,R20
    ldi         R20,5
    sts         TransNum,R20
    ldi         R20,0xBB ;Respond header
    ldi         R21,0x16
    CALL        TRANSREPLY
    pop         R24
    pop         R23
    pop         R22
    pop         R21
    pop         R20
    pop         R19
ret

GETMOTORCOUNTER: ;Send the motor counter
    push        R20
    push        R21
    push        R22
    ;fetch motor counter
    lds         R22,MotorSensorCount1
    lds         R21,MotorSensorCount2
    lds         R20,MotorSensorCount3
    ;Put counter in TransMSG
    ldi	        ZH,high(TransMSG)	; make high byte of Z point at address of msg
    ldi         ZL,low(TransMSG)
    ST          Z+,R20
    ST          Z+,R21
    ST          Z+,R22
    ldi         R20,3
    sts         TransNum,R20
    ldi         R20,0xBB ;Respond header
    ldi         R21,0x15
    call        TRANSREPLY
    pop         R22
    pop         R21
    pop         R20
ret

TRANSREPLY:  ;Sends the data in R20:R21 (header), followed by data starting from 0x301 and forward the number of bytes in 0x300
    SBIS        UCSRA,UDRE
    RJMP        TRANSREPLY
    out         UDR,R20
    TRANSREPLY1:
    SBIS        UCSRA,UDRE
    RJMP        TRANSREPLY1
    out         UDR,R21
    ldi	        ZH,high(TransMSG)	; make high byte of Z point at address of msg
    ldi         ZL,low(TransMSG)
    lds         R20,TransNum
    inc         R20 ;Need to inc to get correct count
    TRANSREPLYloop:
    SBIS        UCSRA,UDRE
    RJMP        TRANSREPLYloop
    dec         R20
    BREQ        TRANSREPLYEXIT
    ld          R21,Z+
    out         UDR,R21
    rjmp        TRANSREPLYloop
    TRANSREPLYEXIT:
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

    nop ;convert from 0-100 to 0-255 // Not done
    out         OCR2,R18
    jmp         Main ; SET motor speed dependent on R18 value

STOP:
;GET OUT OF INTERRUPT MODE, clear the stack 
		ldi		R16, HIGH(RAMEND)       ;THIS IS UGLY
		out		SPH, R16                ;ANOTHER
		ldi		R16, LOW(RAMEND)        ;SOLUTION
		out		SPL, R16                ;IS NEEDED!!
	    sei		
;*********
    ldi         R18,0x00
    out         OCR2,R18
    jmp         GetACCELLoop

AUTOMODE:
;GET OUT OF INTERRUPT MODE, clear the stack 
		ldi		R16, HIGH(RAMEND)       ;THIS IS UGLY
		out		SPH, R16                ;ANOTHER
		ldi		R16, LOW(RAMEND)        ;SOLUTION
		out		SPL, R16                ;IS NEEDED!!
	    sei		
;*********



AutoModeLoop:
    lds         R19,AutoModeState
    cpi         R19,0x00
    brne        PC+2
    CALL        AUTOMAP
    cpi         R19,0x01
    brne        PC+2
    CALL        CALCULATE
    cpi         R19,0x02
    brne        PC+2
    CALL        DRIVE
AutoModeEnd:
    jmp AutoModeLoop

AUTOMAP:
    push        R18
    push        R20
    ldi         R18,0x70
    out         OCR2,R18
    CALL        MakeAverage
    cpi         R20,127+TURNMAG
    BRLO        PC+4
    CALL        LEFTSWING
    rjmp        AUTOMAPEND
    cpi         R20,127-TURNMAG+1
    BRSH        PC+4
    CALL        RIGHTSWING
    rjmp        AUTOMAPEND
    CALL        STRAIGHT
    
    AUTOMAPEND:
    pop         R20
    pop         R18
ret

CALCULATE:      ;//Does nothing
ret

DRIVE:
ret             ;//Does nothing
    
LEFTSWING:
    push        R20
    push        R21
    push        R22
    push        ZL
    push        ZH
    ldi         R20,0xbf
    out         OCR2,R20
    ldi         R20,0x0F
    sts         TransMsg,R20
    ldi         R20,1
    sts         TransNum,R20
    ldi         R20,0xbb
    ldi         R21,0x12
    CALL        TRANSREPLY

    lds         R20,MotorSensorCount1
    lds         R21,MotorSensorCount2
    lds         R22,MotorSensorCount3
    lds         ZH,ReadingsCur1
    lds         ZL,ReadingsCur2

    ST          Z+,R20
    ST          Z+,R21
    ST          Z+,R22
    ldi         R20,0x0f
    ST          Z+,R20
    
LEFTSWINGWAIT:
        CALL            MakeAverage
        cpi             R20,127+(TURNMAG/2)
        BRLO            PC+2
rjmp LEFTSWINGWAIT

    lds         R20,MotorSensorCount1
    lds         R21,MotorSensorCount2
    lds         R22,MotorSensorCount3
    ST          Z+,R20
    ST          Z+,R21
    ST          Z+,R22
    ldi         R20,0x0f
    ST          Z+,R20
    sts         ReadingsCur1,ZH
    sts         ReadingsCur2,ZL


    pop         ZH
    pop         ZL
    pop         R22
    pop         R21
    pop         R20
ret

RIGHTSWING:
    push        R20
    push        R21
    push        R22
    push        ZL
    push        ZH
    ldi         R20,0xbf
    out         OCR2,R20
    ldi         R20,0x0F
    sts         TransMsg,R20
    ldi         R20,1
    sts         TransNum,R20
    ldi         R20,0xbb
    ldi         R21,0x12
    CALL        TRANSREPLY

    lds         R20,MotorSensorCount1
    lds         R21,MotorSensorCount2
    lds         R22,MotorSensorCount3
    lds         ZH,ReadingsCur1
    lds         ZL,ReadingsCur2

    ST          Z+,R20
    ST          Z+,R21
    ST          Z+,R22
    ldi         R20,0xf0
    ST          Z+,R20
    RIGHTSWINGWAIT:
        CALL        MakeAverage
        cpi         R20,127-(TURNMAG/2)+1
        BRSH        PC+2
    rjmp        RIGHTSWINGWAIT
    lds         R20,MotorSensorCount1
    lds         R21,MotorSensorCount2
    lds         R22,MotorSensorCount3
    ST          Z+,R20
    ST          Z+,R21
    ST          Z+,R22
    ldi         R20,0xf0
    ST          Z+,R20
    sts         ReadingsCur1,ZH
    sts         ReadingsCur2,ZL

    pop         ZH
    pop         ZL
    pop         R22
    pop         R21
    pop         R20
ret

STRAIGHT:
ret

;******
;*MAIN
;******
Main:
MainLoop:
RJMP        MainLoop


GetACCELLoop:
;GET OUT OF INTERRUPT MODE, clear the stack 
		ldi		R16, HIGH(RAMEND)       ;THIS IS UGLY
		out		SPH, R16                ;ANOTHER
		ldi		R16, LOW(RAMEND)        ;SOLUTION
		out		SPL, R16                ;IS NEEDED!!
	    sei		
GetACCELLoopLoop:
    CALL        GETACCEL
rjmp GetACCELLoopLoop

;;Kør motor sensor ind på T0 ben og sæt rise on falling edge. Timer interrupt sættes med OCR0.
; Dermed Vil vi kunne vælge  at få et interrupt pr. x omdrejning. 0<x<(255/3)
;GOD LØSNING!!! Måske ikke nødvendig
