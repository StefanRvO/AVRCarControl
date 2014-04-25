;//Routines for the AutoMode functionality

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
        
        
;###############################################
;###################AUTOMAP#####################
;###############################################

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

;###############################################
;###################CALCULATE###################
;###############################################

CALCULATE:      ;//Does nothing
    push        R19
    lds         R19,AutoModeState
    inc         R19
    sts         AutoModeState,R19
    pop R19
ret


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

ret         


;####################################################
;####################LEFTSWING#######################
;####################################################
  
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

;#####################################################
;###################RIGHTSWING########################
;#####################################################


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

;##############################################
;####################STRAIGHT##################
;##############################################


STRAIGHT:
ret
