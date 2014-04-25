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

    nop ;convert from 0-100 to 0-255 // Not done
    out         OCR2,R18
    jmp         Main ; SET motor speed dependent on R18 value
    
    
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
    SBI PORTB,2
    lds R17,T1_Counter1
    add R16,R17
    WAITLOOP_BRAKETIME:
        lds R17,T1_Counter1
        cp  R16,R17
        brne WAITLOOP_BRAKETIME
    ENDBRAKETIME:
    CBI PORTB,2
    pop R17
ret

;#################################################################
;######################BRAKEDIST##################################
;#################################################################

BRAKEDIST: ;//Brakes for the number of Motor turns  in R16 
                    
    push    R17
    cpi R16,0x00
    breq ENDBRAKEDIST
    SBI PORTB,2
    lds R17,MotorSensorCount1
    add R16,R17
    WAITLOOP_BRAKEDIST:
        lds R17,MotorSensorCount1
        cp  R16,R17
        brne WAITLOOP_BRAKEDIST
    ENDBRAKEDIST:
    CBI PORTB,2
    pop R17
ret

;#################################################################
;######################UNBRAKE####################################
;#################################################################

UNBRAKE:
    CBI PORTB,2
ret

;#################################################################
;######################BRAKE######################################
;#################################################################

BRAKE:
    SBI PORTB,2
ret
    
