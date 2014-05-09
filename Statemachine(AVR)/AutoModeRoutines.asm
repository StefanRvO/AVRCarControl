;//Routines for the AutoMode functionality
;//List of turn types:
;//RIGHT45, START 01
;//RIGHT90, START 02
;//RIGHT135, START 03
;//RIGHT180, START 04
;//RIGHT, STOP  0A
;//LEFT45,  START 05
;//LEFT90,  START 06
;//LEFT135,  START 07
;//LEFT180,  START 08
;//LEFT,  STOP  0B


.equ        TURNMAG=7
.equ        TURNMAGOUT=TURNMAG-2
.equ        BRAKELENGHT=105
.equ        TURNENDPREV=140
.equ        MAPPINGSPEED=0x8f
.equ        TURNSPEED=0x90
.equ        LEFT45_90=75
.equ        LEFT90_135=103
.equ        LEFT135_180=137
.equ        RIGHT45_90=80
.equ        RIGHT90_135=129
.equ        RIGHT135_180=159

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
    CALL        SWINGPING
    CALL        GETSPEEDTIME
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

    CALL        SWINGPING

    lds         R24,MotorSensorCount1
    lds         R25,MotorSensorCount2
    lds         R26,MotorSensorCount3

    clc
    mov         R17,R24
    mov         R18,R25
    mov         R19,R26
    sub         R17,R21
    sbc         R18,R22
    sub         R19,R23

    ldi         R16,0x08
    cpi         R19,0
    brne        LEFTSWINGSEND
    ldi         R16,0x08
    cpi         R18,0
    brne        LEFTSWINGSEND
    ldi         R16,0x08
    cpi         R17,LEFT135_180
    brge        LEFTSWINGSEND
    ldi         R16,0x07
    cpi         R17,LEFT90_135
    brge        LEFTSWINGSEND
    ldi         R16,0x06
    cpi         R17,LEFT45_90
    brge        LEFTSWINGSEND
    ldi         R16,0x05

LEFTSWINGSEND:
    lds         ZL,LanePointerL
    lds         ZH,LanePointerH
    st          Z+,R16
    ST          Z+,R21
    ST          Z+,R22
    ST          Z+,R23
    ldi         R16,0x0B
    ST          Z+,R16
    ST          Z+,R24
    ST          Z+,R25
    ST          Z+,R26
    sts         LanePointerH,ZH
    sts         LanePointerL,ZL


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
    CALL        SWINGPING
    CALL        GETSPEEDTIME
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
    
    CALL        SWINGPING

    lds         R24,MotorSensorCount1
    lds         R25,MotorSensorCount2
    lds         R26,MotorSensorCount3

    clc
    mov         R17,R24
    mov         R18,R25
    mov         R19,R26
    sub         R17,R21
    sbc         R18,R22
    sub         R19,R23

    ldi         R16,0x04
    cpi         R19,0
    brne        RIGHTSWINGSEND
    ldi         R16,0x04
    cpi         R18,0
    brne        RIGHTSWINGSEND
    ldi         R16,0x04
    cpi         R17,RIGHT135_180
    brge        RIGHTSWINGSEND
    ldi         R16,0x03
    cpi         R17,RIGHT90_135
    brge        RIGHTSWINGSEND
    ldi         R16,0x02
    cpi         R17,RIGHT45_90
    brge        RIGHTSWINGSEND
    ldi         R16,0x01

RIGHTSWINGSEND:
    lds         ZL,LanePointerL
    lds         ZH,LanePointerH
    ST          Z+,R16
    ST          Z+,R21
    ST          Z+,R22
    ST          Z+,R23
    ldi         R16,0x0B
    ST          Z+,R16
    ST          Z+,R24
    ST          Z+,R25
    ST          Z+,R26
    sts         LanePointerH,ZH
    sts         LanePointerL,ZL


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
    ldi     R21,0xCA
    ldi     R22,0x00
    ldi     R23,0x00
    ldi     R24,0x00
    CALL    BRAKE
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
    ldi  R23,0xff
    out  OCR0,R23
    ;CALL        CALCBREAKTIME
    
    CALL        BREAKWAIT
    
    

    TurnLoop:
        ldi         R16,TURNSPEED
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
        
        ldi         R23,TURNENDPREV
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

