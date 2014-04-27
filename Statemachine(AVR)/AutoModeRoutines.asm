;//Routines for the AutoMode functionality

.equ        TURNMAG=8
.equ        BRAKELENGHT=10

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
        CPI         R19,0x10
        BREQ        AUTOMODE1
        lds         R19,AutoModeState
        CPI         R19,0x11
        BREQ        AUTOMODE2
        
        
    AutoModeEnd:
        jmp AutoModeLoop
        
    AUTOMODE1:
    CALL        AUTOMAP
    jmp         AutoModeLoop
    AUTOMODE2:
    CALL        DRIVE
    jmp         AutoModeLoop
        
        
        
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
    ldi         R19,0x12
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
        ldi         R16,0xaa
        out         PORTB,R16




        DRIVELOOP:
                    ;Set speed to 80
            ldi         R16,0x80
            out         OCR2,R16
            lds         R22,MotorSensorCount1
            lds         R21,MotorSensorCount2
            lds         R20,MotorSensorCount3
            lds         ZH,LanePointerH
            lds         ZL,LanePointerL

            LD          R16,Z+ ;//ignore turntype atm
                              ;Read in MotorCounter at next turn
            LD          R18,Z+
            LD          R17,Z+
            LD          R16,Z+
            ;// output over serial
            
            sts         TransMSG,R16
            sts         TransMSG+1,R17
            sts         TransMSG+2,R18


            sts         TransMSG+3,R20
            sts         TransMSG+4,R21
            sts         TransMSG+5,R22
            
            ldi         R19,6
            sts         TransNum,R19
            push        R20
            push        R21
            ldi         R20,0xaa
            ldi         R21,0x33
            CALL        TRANSREPLY
            pop         R21
            pop         R20
                            ;Add BRAKELENGHT to current count
            ldi         R19,BRAKELENGHT
            add         R20,R19
            ldi         R19,0x00
            adc         R21,R19
            adc         R22,R19

                            ;Check if the numbers is equal
            cp      R16,R20
            cpc     R17,R21
            cpc     R18,R22
            brsh DRIVELOOP
            CALL    SOONTURN
        rjmp DRIVELOOP


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
    CALL        SWINGPING
    lds         R20,MotorSensorCount1
    lds         R21,MotorSensorCount2
    lds         R22,MotorSensorCount3
    lds         ZL,LanePointerL
    lds         ZH,LanePointerH
    
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
    CALL        SWINGPING
    lds         R20,MotorSensorCount1
    lds         R21,MotorSensorCount2
    lds         R22,MotorSensorCount3
    lds         ZL,LanePointerL
    lds         ZH,LanePointerH

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

;##############################################
;###############SOONTURN#######################
;##############################################


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

