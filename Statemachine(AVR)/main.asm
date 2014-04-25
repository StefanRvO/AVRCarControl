.equ        T1_Counter1 = 0x060
.equ        T1_Counter2 = 0x061
.equ        T1_Counter3 = 0x062
.equ        MotorSensorCount1 = 0x063 ;Counter for the motor sensor
.equ        MotorSensorCount2=0x064
.equ        MotorSensorCount3=0x065
.equ        TransNum =0x066
.equ        TransMSG = 0x067 ;//Alocate 10 bytes
.equ        END_ = 0xFF
.equ        AutoModeState=0x071 ;//States: 0x10=Mapping. First lap, 0x11==Calculate, 0x12=Drive
.equ        CurReading=0x072
.equ        LanePointerH=0x073 ;//high pointer adress
.equ        LanePointerL=0x074 ;//Low pointer adress
.equ        LanePointerENDH=0x075
.equ        LanePointerENDL=0x076
.equ        TurnCount=0x077
.equ        Readings=0x078 ; Here we put in our ADC readings //Alocate 64 bytes
.equ        CarLane =0x0b8 ; Here we put  the mapping
.equ        TURNMAG=8
.equ        BRAKELENGHT=20

.equ        BUFFERSIZE=32
.equ        ACCELADJUST=2
.include    "m32Adef.inc"

.org        0x0000
.include    "SetupInterrupts.asm"   ;setup Interrupts
.org        0x0060
Reset:
.include    "ResetRoutines.asm"


;ROUTINES INCLUDES
.include "MotorAndBrakeControl.asm"
.include "ADCRoutines.asm"


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
;***********INT0,MOTOR SENSOR
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

INT1_ISR: ;//Line sensor...
    push        R16
    in          R16,SREG
    push        R16
    push        R20
    push        R21
    push        R22
    push        ZL
    push        ZH
    ;CALL 	    GETMOTORCOUNTER ;Print Out Motor counter
    ;CALL	    GETTIME
    
    lds         R16,AutoModeState
    cpi         R16,0x10
    brne        ENDAutoStateChange
    inc         R16
    sts         AutoModeState,R16
    
    lds         R20,MotorSensorCount1
    lds         R21,MotorSensorCount2
    lds         R22,MotorSensorCount3
    lds         ZH,LanePointerH
    lds         ZL,LanePointerL
    sts         LanePointerENDH,ZH
    sts         LanePointerENDL,ZL
    ldi         R16,0xff
    ST          Z+,R16
    
    ST          Z+,R20
    ST          Z+,R21
    ST          Z+,R22
    
    ENDAutoStateChange:
    
    ldi 	    R16,0x00
    sts         MotorSensorCount1,R16
    sts         MotorSensorCount2,R16
    sts         MotorSensorCount3,R16
    ;CALL        DELAY
    ;CALL        BRAKELOOP
    pop         ZH
    pop         ZL
    pop         R22
    pop         R21
    pop         R20
    pop         R16
    out         SREG,R16
    pop         R16
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
    CPI         R17,0x13 ;accell loop, continuesly send accelerometer data
    BRNE        PC+2
    CALL        GetACCELLoop
    CPI         R17,0x14 ;BRAKE
    BRNE        PC+2
    CALL        BRAKE
    CPI         R17,0x15 ;UNBRAKE
    BRNE        PC+2
    CALL        UNBRAKE
    CPI         R17,0x16 ;SETMAG
    BRNE        PC+2
    CALL        SETMAG
RET     
;*********
;****************GETMODE
GET:
    CPI         R17,0x10
    BREQ        CALL1
    CPI         R17,0x11
    BREQ        CALL2
    CPI         R17,0x12
    BREQ        CALL3
    CPI         R17,0x13
    BREQ        CALL4
    CPI         R17,0x14
    BREQ        CALL5
    CPI         R17,0x15
    BREQ        CALL6
    RET
    
    
    CALL1:
    CALL        GETSPEED
    RET
    CALL2:
    CALL        GETSTOP
    RET
    CALL3:
    CALL        GETAUTOMODE
    RET
    CALL4:
    CALL        GETMOTORCOUNTER
    RET
    CALL5:
    CALL        GETTIME
    RET
    CALL6:
    CALL        GETACCEL
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
ret

GETAUTOMODE:
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

SWINGPING: ;//Send the motorcounter, Turncount, ZL, ZH
    push        R22
    push        R21
    push        R20
    
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
    lds         R20,TurnCount
    ST          Z+,R20
    lds         R20,LanePointerH
    ST          Z+,R20
    lds         R20,LanePointerL
    ST          Z+,R20
    ldi         R20,6
    sts         TransNum,R20
    ldi         R20,0xBB ;Respond header
    ldi         R21,0x17
    CALL        TRANSREPLY
    
    pop         R20
    pop         R21
    pop         R22
    ret



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
SETMAG:

    out OCR0,R18
    ret



PLACEHOLD:
ret

AUTOMODE:
;GET OUT OF INTERRUPT MODE, clear the stack 
		ldi		R16, HIGH(RAMEND)       ;THIS IS UGLY
		out		SPH, R16                ;ANOTHER
		ldi		R16, LOW(RAMEND)        ;SOLUTION
		out		SPL, R16                ;IS NEEDED!!
	    sei		
;*********

ldi         R16,HIGH(CarLane)
sts         LanePointerH,R16
ldi         R16,LOW(CarLane)
sts         LanePointerL,R16
ldi         R16,0x10
sts         AutoModeState,R16

AutoModeLoop:
    lds         R19,AutoModeState
    cpi         R19,0x10
    brne        PC+2
    CALL        AUTOMAP
    cpi         R19,0x11
    brne        PC+2
    CALL        CALCULATE
    cpi         R19,0x12
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
    push        R19
    lds         R19,AutoModeState
    inc         R19
    sts         AutoModeState,R19
    pop R19
ret

DRIVE:
push        R16
push        R17
push        R18
push        R19
push        R20
push        R21
push        R22
push        ZH
push        ZL
ldi         R16,HIGH(CarLane)
sts         LanePointerH,R16
ldi         R16,LOW(CarLane)
sts         LanePointerL,R16




DRIVELOOP:
        ;Set speed to 80
ldi     R16,0x80
out     OCR2,R16
lds         R20,MotorSensorCount1
lds         R21,MotorSensorCount2
lds         R22,MotorSensorCount3
lds         ZH,LanePointerH
lds         ZL,LanePointerL

LD          R16,Z+
                  ;Read in MotorCounter at next turn
LD          R16,Z+
LD          R17,Z+
LD          R18,Z+
                ;Add BRAKELENGHT to current count
ldi         R19,BRAKELENGHT
add         R20,R19
ldi         R19,0x00
adc         R21,R19
adc         R22,R19

                ;Check if the numbers is equal
cp      R16,R17
cpc     R17,R21
cpc     R18,R19
brne DRIVELOOP
CALL    SOONTURN
jmp DRIVELOOP


DRIVELOOPEND:
pop         ZL
pop         ZH
pop         R22
pop         R21
pop         R20
pop         R19
pop         R18
pop         R17
pop         R16

ret             ;//Does nothing




    
LEFTSWING:
    push        R16
    push        R20
    push        R21
    push        R22
    push        ZL
    push        ZH
    lds         R20,TurnCount
    inc         R20
    sts         TurnCount,R20
    ;ldi         R20,0x0F
    ;sts         TransMsg,R20
    ;ldi         R20,1
    ;sts         TransNum,R20
    ;ldi         R20,0xbb
    ;ldi         R21,0x12
    ;CALL        TRANSREPLY
    CALL        SWINGPING
    lds         R20,MotorSensorCount1
    lds         R21,MotorSensorCount2
    lds         R22,MotorSensorCount3
    lds         ZH,LanePointerH
    lds         ZL,LanePointerL
    
    ldi         R16,0x0f
    ST          Z+,R16
    
    ST          Z+,R20
    ST          Z+,R21
    ST          Z+,R22
    
LEFTSWINGWAIT:
        CALL            MakeAverage
        cpi             R20,127+(TURNMAG/2)
        BRLO            PC+2
rjmp LEFTSWINGWAIT

    lds         R20,MotorSensorCount1
    lds         R21,MotorSensorCount2
    lds         R22,MotorSensorCount3
    
    ldi         R16,0x0f
    ST          Z+,R16
    
    ST          Z+,R20
    ST          Z+,R21
    ST          Z+,R22
    
    sts         LanePointerH,ZH
    sts         LanePointerL,ZL


    pop         ZH
    pop         ZL
    pop         R22
    pop         R21
    pop         R20
    pop         R16
ret

RIGHTSWING:
    push        R16
    push        R20
    push        R21
    push        R22
    push        ZL
    push        ZH
    lds         R20,TurnCount
    inc         R20
    sts         TurnCount,R20
    ;ldi         R20,0x0F
    ;sts         TransMsg,R20
    ;ldi         R20,1
    ;sts         TransNum,R20
    ;ldi         R20,0xbb
    ;ldi         R21,0x12
    ;CALL        TRANSREPLY
    CALL        SWINGPING
    lds         R20,MotorSensorCount1
    lds         R21,MotorSensorCount2
    lds         R22,MotorSensorCount3
    lds         ZH,LanePointerH
    lds         ZL,LanePointerL

    ldi         R16,0xf0
    ST          Z+,R16
    
    ST          Z+,R20
    ST          Z+,R21
    ST          Z+,R22
    
    RIGHTSWINGWAIT:
        CALL        MakeAverage
        cpi         R20,127-(TURNMAG/2)+1
        BRSH        PC+2
    rjmp        RIGHTSWINGWAIT
    lds         R20,MotorSensorCount1
    lds         R21,MotorSensorCount2
    lds         R22,MotorSensorCount3
    
    ldi         R16,0xf0
    ST          Z+,R16
    
    ST          Z+,R20
    ST          Z+,R21
    ST          Z+,R22
    
    sts         LanePointerH,ZH
    sts         LanePointerL,ZL

    pop         ZH
    pop         ZL
    pop         R22
    pop         R21
    pop         R20
    pop         R16
ret

STRAIGHT:
ret

;******
;*MAIN
;******
Main:
MainLoop:
ldi R16,0x00
sts AutoModeState,R16
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



DELAY:
push R17
push R18
ldi R17,0xff
ldi R18,0x0f
DELAYLOOP:
dec R17
breq R18DEC
rjmp DELAYLOOP
R18DEC:
dec R18
breq DELAYEND
ldi R17,0xff
rjmp DELAYLOOP
DELAYEND:
pop R18
pop R17
ret


SOONTURN: ;//Prepare for the turn in a sec
push R16

; ADD 4 to z pointer
ADIW ZL,4
;Save to ram
sts         LanePointerH,ZH
sts         LanePointerL,ZL

;Break in 1000 ms
ldi R16,0xff
CALL BRAKETIME
CALL GETMOTORCOUNTER
pop R16
ret


