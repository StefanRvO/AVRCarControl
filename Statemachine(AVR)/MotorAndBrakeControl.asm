;//Code for controlling the motor and brake system


;#################################################################
;######################SETSPEED###################################
;################################################################# 
SETSPEED:
;GET OUT OF INTERRUPT MODE, clear the stack 
		ldi		R16, HIGH(RAMEND)       ;THIS IS UGLY
		out		SPH, R16                ;ANOTHER
		ldi		R16, LOW(RAMEND)        ;SOLUTION
		out		SPL, R16                ;IS NEEDED!!
	    sei		
;*********

    ; SET motor speed dependent on R18 value
    ;//Multiply R18 with 255 and divide with 100
    ldi         R17,255
    MUL         R18,R17
    mov         R20,R1
    mov         R19,R0
    ldi         R18,100
    CALL        divide
    
    out         OCR2,R19
    jmp         Main 
    
    
;#################################################################
;######################STOP#######################################
;#################################################################    
        
    
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
    jmp         Main
    
    
;#################################################################
;######################BRAKETIME##################################
;#################################################################


BRAKETIME: ;//Brakes for the number of Timer 1 overflows in R16 //Max inaccuracy=2^16 cycles≃4,096ms
                    ;Max Braketime≃1s //Just loop if more is needed
    push    R17
    cpi R16,0x00
    breq ENDBRAKETIME
    SBI portb,1
    lds R17,T1_Counter1
    add R16,R17
    WAITLOOP_BRAKETIME:
        lds R17,T1_Counter1
        cp  R16,R17
        brne WAITLOOP_BRAKETIME
    ENDBRAKETIME:
    CBI portb,1
    pop R17
ret

;#################################################################
;######################BRAKEDIST##################################
;#################################################################

BRAKEDIST: ;//Brakes for the number of Motor turns  in R16 
                    
    push    R17
    cpi R16,0x00
    breq ENDBRAKEDIST
    SBI portb,1
    lds R17,MotorSensorCount1
    add R16,R17
    WAITLOOP_BRAKEDIST:
        lds R17,MotorSensorCount1
        cp  R16,R17
        brne WAITLOOP_BRAKEDIST
    ENDBRAKEDIST:
    CBI portb,1
    pop R17
ret

;#################################################################
;######################UNBRAKE####################################
;#################################################################

UNBRAKE:
    CBI portb,1
ret

;#################################################################
;######################BRAKE######################################
;#################################################################

BRAKE:
    SBI portb,1
ret


;################################################
;##################CALCSPEED#####################
;################################################
CALCSPEED: ;//Calculate tihe time between the two most recent motor events
;//put it into R15:R19
    push    R10
    push    R11
    push    R12
    push    R13
    push    R14
    
    lds     R10,MotorTime1
    lds     R11,MotorTime1+1
    lds     R12,MotorTime1+2
    lds     R13,MotorTime1+3
    lds     R14,MotorTime1+4
    
    lds     R19,MotorTime2
    lds     R18,MotorTime2+1
    lds     R17,MotorTime2+2
    lds     R16,MotorTime2+3
    lds     R15,MotorTime2+4
    
    sub    R15,R14
    sbc    R16,R13
    sbc    R17,R12
    sbc    R18,R11
    sbc    R19,R10
    
    pop     R10
    pop     R11
    pop     R12
    pop     R13
    pop     R14
ret
    
