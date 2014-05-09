;//Routines for the AutoMode functionality



.equ        OUTER45=0x01
.equ        OUTER90=0x02
.equ        OUTER135=0x03
.equ        OUTER180=0x04

.equ        INNER45=0x05
.equ        INNER90=0x06
.equ        INNER135=0x07
.equ        INNER180=0x08

.equ        TURNSPEED=0x90
.equ        INNER45_90=75
.equ        INNER90_135=103
.equ        INNER135_180=137

.equ        OUTER45_90=80
.equ        OUTER90_135=129
.equ        OUTER135_180=159

.equ        INNER45_BREAKSPEED=0xDD
.equ        INNER90_BREAKSPEED=0xDD
.equ        INNER135_BREAKSPEED=0xDD
.equ        INNER180_BREAKSPEED=0xDD

.equ        OUTER45_BREAKSPEED=0xDD
.equ        OUTER90_BREAKSPEED=0xDD
.equ        OUTER135_BREAKSPEED=0xDD
.equ        OUTER180_BREAKSPEED=0xDD

.equ        BRAKELENGHT_INNER45=160
.equ        BRAKELENGHT_INNER90=160
.equ        BRAKELENGHT_INNER135=160
.equ        BRAKELENGHT_INNER180=160

.equ        BRAKELENGHT_OUTER45=160
.equ        BRAKELENGHT_OUTER90=160
.equ        BRAKELENGHT_OUTER135=160
.equ        BRAKELENGHT_OUTER180=160


.equ        TURNSPEED_INNER45=0xa0
.equ        TURNSPEED_INNER90=0xa0
.equ        TURNSPEED_INNER135=0xa0
.equ        TURNSPEED_INNER180=0xa0

.equ        TURNSPEED_OUTER45=0xa0
.equ        TURNSPEED_OUTER90=0xa0
.equ        TURNSPEED_OUTER135=0xa0
.equ        TURNSPEED_OUTER180=0xa0


.equ        TURNOUT_INNER45=20
.equ        TURNOUT_INNER90=20
.equ        TURNOUT_INNER135=20
.equ        TURNOUT_INNER180=20

.equ        TURNOUT_OUTER45=20
.equ        TURNOUT_OUTER90=20
.equ        TURNOUT_OUTER135=20
.equ        TURNOUT_OUTER180=20

.equ        TURNMAG=7
.equ        TURNMAGOUT=TURNMAG-2

.equ        BRAKELENGHT=160
.equ        TURNENDPREV=20

.equ        MAPPINGSPEED=0x8f



;##################################################
;###############AUTOMODE MAINLOOP##################
;##################################################

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
    ldi         R16,0x0f
    sts         AutoModeState,R16

    AutoModeLoop:
        lds         R19,AutoModeState
        CPI         R19,0x0f
        BREQ        AUTOMODE0
        lds         R19,AutoModeState
        CPI         R19,0x10
        BREQ        AUTOMODE1
        lds         R19,AutoModeState
        CPI         R19,0x11
        BREQ        AUTOMODE2
        lds         R19,AutoModeState
        CPI         R19,0x12
        BREQ        AUTOMODE3
        
        
    AutoModeEnd:
        jmp AutoModeLoop
        
    AUTOMODE0:
        ldi R16,MAPPINGSPEED
        out OCR2,R16
        jmp AutoModeLoop
        
    AUTOMODE1:
    CALL        AUTOMAP
    jmp         AutoModeLoop
    AUTOMODE2:
    CALL        DRIVE
    jmp         AutoModeLoop
    AUTOMODE3:
    CALL        DRIVERESET
    jmp         AutoModeLoop
        
        
ADJUSTAUTOMAPSPEED:       
 
 
    push    R15
    push    R16
    push    R17
    push    R18
    push    R19
    push    R20
    push    R21
    push    R22
    push    R23
    push    R24
    
    ldi     R20,0x08
    ldi     R21,0xCF
    ldi     R22,0x00
    ldi     R23,0x00
    ldi     R24,0x00
    CALL    BRAKE
    ADJUSTAUTOMAPSPEEDLOOP:
        CALL    CALCSPEED
        cp      R20,R15
        cpc     R21,R16
        cpc     R22,R17
        cpc     R23,R18
        cpc     R24,R19
        brsh    ADJUSTAUTOMAPSPEEDLOOP
    
    CALL UNBRAKE
        
ADJUSTAUTOMAPSPEEDEND:
    pop     R24
    pop     R23
    pop     R22
    pop     R21
    pop     R20
    pop     R19
    pop     R18
    pop     R17
    pop     R16
    pop     R15
ret
;###############################################
;###################AUTOMAP#####################
;###############################################

AUTOMAP:
    
    push        R18
    push        R20
    AUTOMAPLOOP:
    CALL        ADJUSTAUTOMAPSPEED
    lds         R16,AutoModeState
    cpi         R16,0x10
    brne        AUTOMAPEND
    ldi         R18,MAPPINGSPEED
    out         OCR2,R18
    CALL        MakeAverage
    cpi         R20,127+TURNMAG
    BRLO        PC+4
    CALL        LEFTSWING
    rjmp        AUTOMAPLOOP
    cpi         R20,127-TURNMAG+1
    BRSH        PC+4
    CALL        RIGHTSWING
    rjmp        AUTOMAPLOOP
    
    CALL        STRAIGHT
    rjmp        AUTOMAPLOOP
    
    AUTOMAPEND:
    pop         R20
    pop         R18
ret

;###############################################
;###################CALCULATE###################
;###############################################

CALCULATE:      ;//Does nothing
    push        R19
    ldi         R19,0x12
    sts         AutoModeState,R19
    pop R19
ret

DRIVERESET:
        push        R16
        ldi         R16,HIGH(CarLane)
        sts         LanePointerH,R16
        ldi         R16,LOW(CarLane)
        sts         LanePointerL,R16
        ldi         R16,0x11
        sts         AutoModeState,R16
        pop         R16

;#################################################
;####################DRIVE########################
;#################################################

DRIVE:
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
        push        ZH
        push        ZL
        ldi         R16,HIGH(CarLane)
        sts         LanePointerH,R16
        ldi         R16,LOW(CarLane)
        sts         LanePointerL,R16




        DRIVELOOP:
            lds         R16,AutoModeState
            cpi         R16,0x11
            brne        DRIVELOOPEND
                    ;Set speed to 80
            ldi         R16,0xff
            out         OCR2,R16
            ldi         R16,0x00
            out         OCR0,R16
            lds         R22,MotorSensorCount1
            lds         R21,MotorSensorCount2
            lds         R20,MotorSensorCount3
            lds         ZH,LanePointerH
            lds         ZL,LanePointerL

            LD          R24,Z+ ;//ignore turntype atm
                              ;Read in MotorCounter at next turn
            LD          R18,Z+
            LD          R17,Z+
            LD          R16,Z+


            cpi         R24,INNER45
            brne        PC+2
            ldi         R25,BRAKELENGHT_INNER45
            
            cpi         R24,INNER90
            brne        PC+2
            ldi         R25,BRAKELENGHT_INNER90
            
            cpi         R24,INNER135
            brne        PC+2
            ldi         R25,BRAKELENGHT_INNER135
            
            cpi         R24,INNER180
            brne        PC+2
            ldi         R25,BRAKELENGHT_INNER180
            
            cpi         R24,OUTER45
            brne        PC+2
            ldi         R25,BRAKELENGHT_OUTER45
            
            cpi         R24,OUTER90
            brne        PC+2
            ldi         R25,BRAKELENGHT_OUTER90
            
            cpi         R24,OUTER135
            brne        PC+2
            ldi         R25,BRAKELENGHT_OUTER135
            
            cpi         R24,OUTER180
            brne        PC+2
            ldi         R25,BRAKELENGHT_OUTER180
            
            ldi         R19,0x00
            add         R22,R25
            adc         R21,R19
            adc         R20,R19

                            ;Check if the numbers is equal
            cp      R22,R18
            cpc     R21,R17
            cpc     R20,R16
            brlo    DRIVELOOP
            
            CALL    SOONTURN
        rjmp DRIVELOOP


    DRIVELOOPEND:
    pop         ZL
    pop         ZH
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

;##############################################
;####################STRAIGHT##################
;##############################################

STRAIGHT:
ret


;##############################################
;####################BREAKWAIT#################
;##############################################


BREAKWAIT: ;//Break untill the car got a specified speed ; the turntype is defined in R16

    push    R15
    push    R16
    push    R17
    push    R18
    push    R19
    push    R20
    push    R21
    push    R22
    push    R23
    push    R24
    push    R25
    CALL    BRAKE
    
    cpi     R16,INNER45
    brne    PC+12
    ldi     R20,0x00
    ldi     R21,INNER45_BREAKSPEED
    ldi     R22,0x00
    ldi     R23,0x00
    ldi     R24,0x00
    rjmp    BREAKWAITLOOP
    cpi     R16,INNER90
    brne    PC+12
    ldi     R20,0x00
    ldi     R21,INNER90_BREAKSPEED
    ldi     R22,0x00
    ldi     R23,0x00
    ldi     R24,0x00
    rjmp    BREAKWAITLOOP
    
    cpi     R16,INNER135
    brne    PC+12
    ldi     R20,0x00
    ldi     R21,INNER135_BREAKSPEED
    ldi     R22,0x00
    ldi     R23,0x00
    ldi     R24,0x00
    rjmp    BREAKWAITLOOP
    
    cpi     R16,INNER180
    brne    PC+12
    ldi     R20,0x00
    ldi     R21,INNER180_BREAKSPEED
    ldi     R22,0x00
    ldi     R23,0x00
    ldi     R24,0x00
    
    cpi     R16,OUTER45
    brne    PC+12
    ldi     R20,0x00
    ldi     R21,OUTER45_BREAKSPEED
    ldi     R22,0x00
    ldi     R23,0x00
    ldi     R24,0x00
    
    cpi     R16,OUTER90
    brne    PC+12
    ldi     R20,0x00
    ldi     R21,OUTER90_BREAKSPEED
    ldi     R22,0x00
    ldi     R23,0x00
    ldi     R24,0x00
    rjmp    BREAKWAITLOOP
    
    cpi     R16,OUTER135
    brne    PC+12
    ldi     R20,0x00
    ldi     R21,OUTER135_BREAKSPEED
    ldi     R22,0x00
    ldi     R23,0x00
    ldi     R24,0x00
    rjmp    BREAKWAITLOOP
    
    cpi     R16,OUTER180
    brne    PC+12
    ldi     R20,0x00
    ldi     R21,OUTER180_BREAKSPEED
    ldi     R22,0x00
    ldi     R23,0x00
    ldi     R24,0x00
    rjmp    BREAKWAITLOOP
    
    BREAKWAITLOOP:
        CALL    GETSPEEDTIME
        CALL    CALCSPEED
        cp      R20,R15
        cpc     R21,R16
        cpc     R22,R17
        cpc     R23,R18
        cpc     R24,R19
        brsh    BREAKWAITLOOP
    
    CALL UNBRAKE
        
BREAKWAITEND:
    pop     R25
    pop     R24
    pop     R23
    pop     R22
    pop     R21
    pop     R20
    pop     R19
    pop     R18
    pop     R17
    pop     R16
    pop     R15
ret


;###################################
;#########CALCBREAKTIME#############
;###################################

CALCBREAKTIME:      ;/CALCULATE THE TIME WE WANT TO BREAK, PUT IT INTO R16
    push    R15
    push    R17
    push    R18
    push    R19
    push    R20
    push    R21
    push    R22
    push    R23
    push    R24
    CALL    CALCSPEED
    ldi     R20,0x00
    ldi     R21,0xE3
    ldi     R22,0x00
    ldi     R23,0x00
    ldi     R24,0x00
    cp      R20,R15
    cpc     R21,R16
    cpc     R22,R17
    cpc     R23,R18
    cpc     R24,R19
    brsh    PC+6
    CALL    GETSPEEDTIME
    ldi     R16,0x01
    rjmp    CALCBREAKTIMEEND
    
    ldi     R16,0x5f
CALCBREAKTIMEEND:
    pop     R24
    pop     R23
    pop     R22
    pop     R21
    pop     R20
    pop     R19
    pop     R18
    pop     R17
    pop     R15
ret
    

;AutoMapAdjust

AutoMapAdjust: ;//Try to adjust the logged data while in drive mode
    push R19
    push R20
    push R21
    
    CALL MakeAverage
    
    LD    R21,Z
    cpi   R21,0x01
    breq  AutoMapAdjust01
    cpi   R21,0x02
    breq  AutoMapAdjust02    
    cpi   R21,0x03
    breq  AutoMapAdjust03    
    cpi   R21,0x04
    breq  AutoMapAdjust04
    
    rjmp  AUTOMAPADJUSTEND
    
    
    AutoMapAdjust01:
    

    cpi         R20,127-TURNMAG+1
    BRSH        AUTOMAPADJUSTEND
    ldi         R19,0x01
    CALL        SAVEMOTOR
    rjmp        AUTOMAPADJUSTEND
    AutoMapAdjust02:
    
    cpi         R20,127-(TURNMAGOUT)+1
    BRSH        PC+2
    rjmp        AUTOMAPADJUSTEND
    ldi         R19,0x02
    CALL        SAVEMOTOR
    rjmp        AUTOMAPADJUSTEND
    AutoMapAdjust03:
    
    cpi     R20,127+TURNMAG
    BRLO    AUTOMAPADJUSTEND
    ldi         R19,0x03
    CALL        SAVEMOTOR
    rjmp        AUTOMAPADJUSTEND
    AutoMapAdjust04:
    
    cpi             R20,127+(TURNMAGOUT)
    BRLO            PC+2
    rjmp            AUTOMAPADJUSTEND
    ldi         R19,0x04
    CALL        SAVEMOTOR
    rjmp        AUTOMAPADJUSTEND
    AUTOMAPADJUSTEND:
    pop  R19
    pop  R21
    pop  R20
ret

SAVEMOTOR: ;//Saves the current motor counter and a number in R19 to ram.
    push        ZH
    push        ZL
    push        R20
    push        R21
    push        R22
    lds         ZH,LanePointerH
    lds         ZL,LanePointerL

        lds         R20,MotorSensorCount1
        lds         R21,MotorSensorCount2
        lds         R22,MotorSensorCount3
        
        ST          Z+,R19
        
        ST          Z+,R20
        ST          Z+,R21
        ST          Z+,R22
        
    pop         ZL
    pop         ZH
    pop         R22
    pop         R21
    pop         R22

ret
;##############################################
;###############SOONTURN#######################
;##############################################


SOONTURN: ;//Prepare for the turn in a sec
    push R16
    push ZL
    push ZH
    push R22
    push R21
    push R20
    push R17
    push R18
    push R19
    push R23
    push R16
    ldi R23,0xff
    out OCR0,R23
   
    LD  R16,Z 
    CALL BREAKWAIT
    
    

    TurnLoop:
        ldi R16,TURNSPEED
        out OCR2,R16
        
        lds R22,MotorSensorCount1
        lds R21,MotorSensorCount2
        lds R20,MotorSensorCount3
        push ZL
        push ZH

        LD R16,Z+ ;//ignore turntype atm
                              ;Read in MotorCounter at next turn
        LD R18,Z+
        LD R17,Z+
        LD R16,Z+
        pop ZH
        pop ZL
        
        ldi R23,TURNENDPREV
        ldi R19,0x00
        SUB R22,R23
        SBC R21,R19
        SBC R20,R19
                           ;Check if the numbers is equal
        cp R22,R18
        cpc R21,R17
        cpc R20,R16
        brlo TurnLoop
        

 
    TURNEND:
    ADIW ZL,4
    sts LanePointerL,ZL
    sts LanePointerH,ZH
    pop R23
    pop R19
    pop R18
    pop R17
    pop R20
    pop R21
    pop R22
    pop ZH
    pop ZL
    pop R16
ret



