
.equ        OUTER45=0x01
.equ        OUTER90=0x02
.equ        OUTER135=0x03
.equ        OUTER180=0x04

.equ        INNER45=0x05
.equ        INNER90=0x06
.equ        INNER135=0x07
.equ        INNER180=0x08

.equ        INNER45_90=75
.equ        INNER90_135=103
.equ        INNER135_180=137

.equ        OUTER45_90=80
.equ        OUTER90_135=129
.equ        OUTER135_180=159

.equ        INNER45_BRAKESPEED=0xAA
.equ        INNER90_BRAKESPEED=0xC0
.equ        INNER135_BRAKESPEED=0xBC
.equ        INNER180_BRAKESPEED=0xC5

.equ        OUTER45_BRAKESPEED=0xA8
.equ        OUTER90_BRAKESPEED=0xC0
.equ        OUTER135_BRAKESPEED=0xBB
.equ        OUTER180_BRAKESPEED=0xC8

.equ        BRAKELENGTH_INNER45=80
.equ        BRAKELENGTH_INNER90=88
.equ        BRAKELENGTH_INNER135=80
.equ        BRAKELENGTH_INNER180=82

.equ        BRAKELENGTH_OUTER45=80
.equ        BRAKELENGTH_OUTER90=95
.equ        BRAKELENGTH_OUTER135=85
.equ        BRAKELENGTH_OUTER180=90


.equ        TURNSPEED_INNER45=0xc7
.equ        TURNSPEED_INNER90=0xa5
.equ        TURNSPEED_INNER135=0xab
.equ        TURNSPEED_INNER180=0xa0

.equ        TURNSPEED_OUTER45=0xc0
.equ        TURNSPEED_OUTER90=0xa5
.equ        TURNSPEED_OUTER135=0xb9
.equ        TURNSPEED_OUTER180=0xa0


.equ        TURNOUT_INNER45=40
.equ        TURNOUT_INNER90=65
.equ        TURNOUT_INNER135=70
.equ        TURNOUT_INNER180=70

.equ        TURNOUT_OUTER45=40
.equ        TURNOUT_OUTER90=80
.equ        TURNOUT_OUTER135=70
.equ        TURNOUT_OUTER180=80

.equ        TURNMAG=7
.equ        TURNMAGOUT=TURNMAG-2

.equ        SLOWSTART=0x15
.equ        MAGNETSTRENGTH=0xff
.equ        MAPPINGSPEED=0x8f
.equ        MAPPINGADJUSTLENGTH=0xc8
.equ        DRIVESPEED=0xff
AUTOMODE:
		ldi		R16, HIGH(RAMEND)       ;THIS IS UGLY
		out		SPH, R16                ;ANOTHER
		ldi		R16, LOW(RAMEND)        ;SOLUTION
		out		SPL, R16                ;IS NEEDED!!
	    sei		
        ldi         R16,HIGH(CarLane)
        sts         LanePointerH,R16
        ldi         R16,LOW(CarLane)
        sts         LanePointerL,R16
        ldi         R16,0x0f
        sts         AutoModeState,R16

;###############################################
;###################INITIATE####################
;###############################################
INITIATE:
        ldi         R16,MAPPINGSPEED-0x15
        out         OCR2,R16
        lds         R19,AutoModeState
        cpi         R19,0x10
        BRSH        AUTOMAP
        rjmp        INITIATE

;###############################################
;###################AUTOMAP#####################
;###############################################

AUTOMAP:
        lds         R19,AutoModeState
        cpi         R19,0x11
        BRSH        DRIVE
        ldi         R20,MAPPINGSPEED
        out         OCR2,R20
        ldi         R20,MAPPINGADJUSTLENGTH
        call        ADJUSTSPEED
        CALL        MakeAverage
        cpi         R20,127+TURNMAG
        BRLO        nu
        CALL        LEFTSWING
        rjmp        AUTOMAP
nu:
        cpi         R20,127-TURNMAG+1
        BRSH        abe
        CALL        RIGHTSWING
        rjmp        AUTOMAP

abe:

        rjmp        AUTOMAP

;#################################################
;####################DRIVE########################
;#################################################

DRIVE:
    ldi     R19,0x11
    sts     AutoModeState,R19
    ldi         R16,HIGH(CarLane)
    sts         LanePointerH,R16
    ldi         R16,LOW(CarLane)
    sts         LanePointerL,R16

DRIVELOOP:
    ldi     R16,DRIVESPEED
    out     OCR2,R16
    ldi     R16,0x00
    out     OCR0,R16

    lds     ZH,LanePointerH
    lds     ZL,LanePointerL
    ld      R16,Z+  ;Turntype
    ld      R17,Z+  ;Motorconter at next turn
    ld      R18,Z+
    ld      R19,Z+
    sts     LanePointerL,ZL
    sts     LanePointerH,ZH
    mov     R23,R17
    mov     R24,R18
    mov     R25,R19

    call    SET_BRAKELENGTH ;   load R20 with brakelength according to turntype
    clr     R21
    sub     R23,R20
    sbc     R24,R21
    sbc     R25,R21
    BRAKELENGTHLOOP:
    lds     R19,AutoModeState
    cpi     R19,0x12
    BRSH    DRIVE
    lds     R20,MotorSensorCount1
    lds     R21,MotorSensorCount2
    lds     R22,MotorSensorCount3
    cp      R23,R20
    cpc     R24,R21
    cpc     R25,R22
    brlo    PC+2
    rjmp    BRAKELENGTHLOOP

    ldi     R20,MAGNETSTRENGTH
    out     OCR0,R20

    call    BRAKE
    call    SET_BRAKESPEED  ;   load R20 with brakespeed according to turntype
    call    ADJUSTSPEED

    call    SET_TURNSPEED   ;   load R20 with turnspeed according to turntype
    out     OCR2,R20
    
    lds     ZH,LanePointerH
    lds     ZL,LanePointerL
    LD      R16,Z+ 
    LD      R17,Z+
    LD      R18,Z+
    LD      R19,Z+
    sts     LanePointerL,ZL
    sts     LanePointerH,ZH

    mov     R23,R17
    mov     R24,R18
    mov     R25,R19
    
    call    SET_TURNOUT     ;   load R20 with turnout according to turntype
    clr     R21
    sub     R23,R20
    sbc     R24,R21
    sbc     R25,R21
    TURNOUTLOOP:
    lds     R20,MotorSensorCount1
    lds     R21,MotorSensorCount2
    lds     R22,MotorSensorCount3
    cp      R23,R20
    cpc     R24,R21
    cpc     R25,R22
    brlo    PC+2
    rjmp    TURNOUTLOOP
    lds     R19,AutoModeState
    cpi     R19,0x12
    BRSH    PC+2
    jmp     DRIVELOOP
    jmp     DRIVE


;###############################################
;##################ADJUSTSPEED##################
;###############################################
ADJUSTSPEED:                ;  Brakes until time between motorinterrupts=R20*256 cycles
 
    push    R15
    push    R16
    push    R17
    push    R18
    push    R19
    push    R21
    
    clr     R21
    CALL    BRAKE
ADJUSTSPEEDLOOP:
    CALL    CALCSPEED
    cp      R21,R15
    cpc     R20,R16
    cpc     R21,R17
    cpc     R21,R18
    cpc     R21,R19
    brsh    ADJUSTSPEEDLOOP
    CALL    CALCSPEED
    cp      R21,R15
    cpc     R20,R16
    cpc     R21,R17
    cpc     R21,R18
    cpc     R21,R19
    brsh    ADJUSTSPEEDLOOP
    
    CALL UNBRAKE
        
    pop     R21
    pop     R19
    pop     R18
    pop     R17
    pop     R16
    pop     R15
ret

;####################################################
;####################LEFTSWING#######################
;####################################################
  
LEFTSWING:
    push        R16
    push        R17
    push        R18
    push        R19
    push        R20
    push        R21
    push        R22
    push        R23
    push        R24
    push        R25
    push        R26
    push        ZL
    push        ZH
    lds         R20,TurnCount
    inc         R20
    sts         TurnCount,R20
    lds         R21,MotorSensorCount1
    lds         R22,MotorSensorCount2
    lds         R23,MotorSensorCount3
    
LEFTSWINGWAIT:
        CALL            MakeAverage
        cpi             R20,127+(TURNMAGOUT)
        BRLO            PC+2
        ;//MAYBE DELAY A BIT HERE AND TEST AGAIN...??
rjmp LEFTSWINGWAIT
        CALL            DELAY
        CALL            MakeAverage
        cpi             R20,127+(TURNMAGOUT)
        BRLO            PC+2
        ;//MAYBE DELAY A BIT HERE AND TEST AGAIN...??
rjmp LEFTSWINGWAIT
        CALL            DELAY
        CALL            MakeAverage
        cpi             R20,127+(TURNMAGOUT)
        BRLO            PC+2
        ;//MAYBE DELAY A BIT HERE AND TEST AGAIN...??
rjmp LEFTSWINGWAIT


    lds         R24,MotorSensorCount1
    lds         R25,MotorSensorCount2
    lds         R26,MotorSensorCount3

    clc
    mov         R17,R24
    mov         R18,R25
    mov         R19,R26
    sub         R17,R21
    sbc         R18,R22
    sbc         R19,R23

    ldi         R16,OUTER180
    cpi         R19,0
    brne        LEFTSWINGSEND
    ldi         R16,OUTER180
    cpi         R18,0
    brne        LEFTSWINGSEND
    ldi         R16,OUTER180
    cpi         R17,OUTER135_180
    brsh        LEFTSWINGSEND
    ldi         R16,OUTER135
    cpi         R17,OUTER90_135
    brsh        LEFTSWINGSEND
    ldi         R16,OUTER90
    cpi         R17,OUTER45_90
    brsh        LEFTSWINGSEND
    ldi         R16,OUTER45

LEFTSWINGSEND:
    lds         ZL,LanePointerL
    lds         ZH,LanePointerH
    st          Z+,R16
    ST          Z+,R21
    ST          Z+,R22
    ST          Z+,R23
    ST          Z+,R16
    ST          Z+,R24
    ST          Z+,R25
    ST          Z+,R26
    sts         LanePointerH,ZH
    sts         LanePointerL,ZL

    CALL        SWINGPING

    pop         ZH
    pop         ZL
    pop         R26
    pop         R25
    pop         R24
    pop         R23
    pop         R22
    pop         R21
    pop         R20
    pop         R19
    pop         R18
    pop         R17
    pop         R16
ret

;#####################################################
;###################RIGHTSWING########################
;#####################################################


RIGHTSWING:
    push        R16
    push        R17
    push        R18
    push        R19
    push        R20
    push        R21
    push        R22
    push        R23
    push        R24
    push        R25
    push        R26
    push        ZL
    push        ZH
    lds         R20,TurnCount
    inc         R20
    sts         TurnCount,R20
    lds         R21,MotorSensorCount1
    lds         R22,MotorSensorCount2
    lds         R23,MotorSensorCount3
    
    RIGHTSWINGWAIT:
        CALL        MakeAverage
        cpi         R20,127-(TURNMAGOUT)+1
        BRSH        PC+2
        ;//MAYBE DELAY A BIT HERE AND TEST AGAIN...??
        
    rjmp        RIGHTSWINGWAIT
        CALL        DELAY
        CALL        MakeAverage
        cpi         R20,127-(TURNMAGOUT)+1
        BRSH        PC+2
        ;//MAYBE DELAY A BIT HERE AND TEST AGAIN...??
        
    rjmp        RIGHTSWINGWAIT
        CALL        DELAY
        CALL        MakeAverage
        cpi         R20,127-(TURNMAGOUT)+1
        BRSH        PC+2
        ;//MAYBE DELAY A BIT HERE AND TEST AGAIN...??
        
    rjmp        RIGHTSWINGWAIT
    

    lds         R24,MotorSensorCount1
    lds         R25,MotorSensorCount2
    lds         R26,MotorSensorCount3

    clc
    mov         R17,R24
    mov         R18,R25
    mov         R19,R26
    sub         R17,R21
    sbc         R18,R22
    sbc         R19,R23

    ldi         R16,INNER180
    cpi         R19,0
    brne        RIGHTSWINGSEND
    ldi         R16,INNER180
    cpi         R18,0
    brne        RIGHTSWINGSEND
    ldi         R16,INNER180
    cpi         R17,INNER135_180
    brsh        RIGHTSWINGSEND
    ldi         R16,INNER135
    cpi         R17,INNER90_135
    brsh        RIGHTSWINGSEND
    ldi         R16,INNER90
    cpi         R17,INNER45_90
    brsh        RIGHTSWINGSEND
    ldi         R16,INNER45

RIGHTSWINGSEND:
    lds         ZL,LanePointerL
    lds         ZH,LanePointerH
    ST          Z+,R16
    ST          Z+,R21
    ST          Z+,R22
    ST          Z+,R23
    ST          Z+,R16
    ST          Z+,R24
    ST          Z+,R25
    ST          Z+,R26
    sts         LanePointerH,ZH
    sts         LanePointerL,ZL

    CALL        SWINGPING

    pop         ZH
    pop         ZL
    pop         R26
    pop         R25
    pop         R24
    pop         R23
    pop         R22
    pop         R21
    pop         R20
    pop         R19
    pop         R18
    pop         R17
    pop         R16
ret

;#####################################################
;#################SET_BRAKELENGTH#####################
;#####################################################
SET_BRAKELENGTH:
    ldi     R20,BRAKELENGTH_OUTER45+SLOWSTART
    cpi     R16,OUTER45
    breq    SET_BRAKELENGTH_END
    ldi     R20,BRAKELENGTH_OUTER90+SLOWSTART
    cpi     R16,OUTER90
    breq    SET_BRAKELENGTH_END
    ldi     R20,BRAKELENGTH_OUTER135+SLOWSTART
    cpi     R16,OUTER135
    breq    SET_BRAKELENGTH_END
    ldi     R20,BRAKELENGTH_OUTER180+SLOWSTART
    cpi     R16,OUTER180
    breq    SET_BRAKELENGTH_END
    ldi     R20,BRAKELENGTH_INNER45+SLOWSTART
    cpi     R16,INNER45
    breq    SET_BRAKELENGTH_END
    ldi     R20,BRAKELENGTH_INNER90+SLOWSTART
    cpi     R16,INNER90
    breq    SET_BRAKELENGTH_END
    ldi     R20,BRAKELENGTH_INNER135+SLOWSTART
    cpi     R16,INNER135
    breq    SET_BRAKELENGTH_END
    ldi     R20,BRAKELENGTH_INNER180+SLOWSTART

SET_BRAKELENGTH_END:
ret

;#####################################################
;#################SET_BRAKESPEED######################
;#####################################################
SET_BRAKESPEED:
    cpi     R16,OUTER45
    brne    PC+2
    ldi     R20,OUTER45_BRAKESPEED+SLOWSTART
    cpi     R16,OUTER90
    brne    PC+2
    ldi     R20,OUTER90_BRAKESPEED+SLOWSTART
    cpi     R16,OUTER135
    brne    PC+2
    ldi     R20,OUTER135_BRAKESPEED+SLOWSTART
    cpi     R16,OUTER180
    brne    PC+2
    ldi     R20,OUTER180_BRAKESPEED+SLOWSTART
    cpi     R16,INNER45
    brne    PC+2
    ldi     R20,INNER45_BRAKESPEED+SLOWSTART
    cpi     R16,INNER90
    brne    PC+2
    ldi     R20,INNER90_BRAKESPEED+SLOWSTART
    cpi     R16,INNER135
    brne    PC+2
    ldi     R20,INNER135_BRAKESPEED+SLOWSTART
    cpi     R16,INNER180
    brne    PC+2
    ldi     R20,INNER180_BRAKESPEED+SLOWSTART

ret

;#####################################################
;###################SET_TURNSPEED#####################
;#####################################################
SET_TURNSPEED:
    cpi     R16,OUTER45
    brne    PC+2
    ldi     R20,TURNSPEED_OUTER45-SLOWSTART
    cpi     R16,OUTER90
    brne    PC+2
    ldi     R20,TURNSPEED_OUTER90-SLOWSTART
    cpi     R16,OUTER135
    brne    PC+2
    ldi     R20,TURNSPEED_OUTER135-SLOWSTART
    cpi     R16,OUTER180
    brne    PC+2
    ldi     R20,TURNSPEED_OUTER180-SLOWSTART
    cpi     R16,INNER45
    brne    PC+2
    ldi     R20,TURNSPEED_INNER45-SLOWSTART
    cpi     R16,INNER90
    brne    PC+2
    ldi     R20,TURNSPEED_INNER90-SLOWSTART
    cpi     R16,INNER135
    brne    PC+2
    ldi     R20,TURNSPEED_INNER135-SLOWSTART
    cpi     R16,INNER180
    brne    PC+2
    ldi     R20,TURNSPEED_INNER180-SLOWSTART
ret

;#####################################################
;###################SET_TURNOUT#####################
;#####################################################
SET_TURNOUT:
    cpi     R16,OUTER45
    brne    PC+2
    ldi     R20,TURNOUT_OUTER45+SLOWSTART
    cpi     R16,OUTER90
    brne    PC+2
    ldi     R20,TURNOUT_OUTER90+SLOWSTART
    cpi     R16,OUTER135
    brne    PC+2
    ldi     R20,TURNOUT_OUTER135+SLOWSTART
    cpi     R16,OUTER180
    brne    PC+2
    ldi     R20,TURNOUT_OUTER180+SLOWSTART
    cpi     R16,INNER45
    brne    PC+2
    ldi     R20,TURNOUT_INNER45+SLOWSTART
    cpi     R16,INNER90
    brne    PC+2
    ldi     R20,TURNOUT_INNER90+SLOWSTART
    cpi     R16,INNER135
    brne    PC+2
    ldi     R20,TURNOUT_INNER135+SLOWSTART
    cpi     R16,INNER180
    brne    PC+2
    ldi     R20,TURNOUT_INNER180+SLOWSTART

ret
