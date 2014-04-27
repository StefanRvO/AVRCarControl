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
.include "AutoModeRoutines.asm"
.include "GetRoutines.asm"


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

;***************
SETMAG:

    out OCR0,R18
    ret



PLACEHOLD:
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




