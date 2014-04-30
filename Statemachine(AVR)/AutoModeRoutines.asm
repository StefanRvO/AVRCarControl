;//Routines for the AutoMode functionality
;//List of turn types:
;//RIGHT, START 01
;//RIGHT, STOP  02
;//LEFT,  START 03
;//LEFT,  STOP  04


.equ        TURNMAG=7
.equ        BRAKELENGHT=140

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
        ldi R16,0x65
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
        
        
        
;###############################################
;###################AUTOMAP#####################
;###############################################

AUTOMAP:
    
    push        R18
    push        R20
    AUTOMAPLOOP:
    lds         R16,AutoModeState
    cpi         R16,0x10
    brne        AUTOMAPEND
    ldi         R18,0x65
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
            
            ;sts         TransMSG,R16
            ;sts         TransMSG+1,R17
            ;sts         TransMSG+2,R18


            ;sts         TransMSG+3,R20
            ;sts         TransMSG+4,R21
            ;sts         TransMSG+5,R22
            
            ;ldi         R19,6
            ;sts         TransNum,R19
            ;push        R20
            ;push        R21
            ;ldi         R20,0xaa
            ;ldi         R21,0x33
            ;CALL        TRANSREPLY
            ;pop         R21
            ;pop         R20
                            ;Add BRAKELENGHT to current count
            ldi         R23,BRAKELENGHT
            ldi         R19,0x00
            add         R22,R23
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
    
    ldi         R16,0x03
    ST          Z+,R16
    
    ST          Z+,R20
    ST          Z+,R21
    ST          Z+,R22
    
LEFTSWINGWAIT:
        CALL            MakeAverage
        cpi             R20,127+(TURNMAG/2)
        BRLO            PC+2
        ;//MAYBE DELAY A BIT HERE AND TEST AGAIN...??
rjmp LEFTSWINGWAIT

    lds         R20,MotorSensorCount1
    lds         R21,MotorSensorCount2
    lds         R22,MotorSensorCount3
    
    ldi         R16,0x04
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

    ldi         R16,0x01
    ST          Z+,R16
    
    ST          Z+,R20
    ST          Z+,R21
    ST          Z+,R22
    
    RIGHTSWINGWAIT:
        CALL        MakeAverage
        cpi         R20,127-(TURNMAG/2)+1
        BRSH        PC+2
        ;//MAYBE DELAY A BIT HERE AND TEST AGAIN...??
    rjmp        RIGHTSWINGWAIT
    lds         R20,MotorSensorCount1
    lds         R21,MotorSensorCount2
    lds         R22,MotorSensorCount3
    
    ldi         R16,0x02
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
;####################BREAKWAIT#################
;##############################################


BREAKWAIT: ;//Break untill the car got a specified speed
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
    
    ldi     R20,0x00
    ldi     R21,0xE3
    ldi     R22,0x00
    ldi     R23,0x00
    ldi     R24,0x00
    CALL    BRAKE
    BREAKWAITLOOP:
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
    
    cpi         R20,127-(TURNMAG/2)+1
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
    
    cpi             R20,127+(TURNMAG/2)
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

    ;CALL        CALCBREAKTIME
    
    CALL        BREAKWAIT
    
    

    TurnLoop:
        ldi         R16,0x65
        out         OCR2,R16
        
        lds         R22,MotorSensorCount1
        lds         R21,MotorSensorCount2
        lds         R20,MotorSensorCount3
        push ZL
        push ZH

        LD          R16,Z+ ;//ignore turntype atm
                              ;Read in MotorCounter at next turn
        LD          R18,Z+
        LD          R17,Z+
        LD          R16,Z+
        pop         ZH
        pop         ZL
        
        ldi         R23,30
        ldi         R19,0x00
        SUB         R22,R23
        SBC         R21,R19
        SBC         R20,R19
                           ;Check if the numbers is equal
        cp      R22,R18
        cpc     R21,R17
        cpc     R20,R16
        brlo    TurnLoop

 
    TURNEND:
    ADIW ZL,4
    sts         LanePointerL,ZL
    sts         LanePointerH,ZH
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

