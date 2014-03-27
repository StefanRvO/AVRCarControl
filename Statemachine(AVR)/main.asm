.include "Constants.inc"
.include "m32def.inc"

.org    0x0000
.include "SetupInterrupts.asm"   ;setup Interrupts
.org    0x0060
Reset:
.include "SetupStack.asm"       ;setup the stack
.include "SetupSerial16Mhz.asm"      ;setup serial connection
.include "SetupIO.asm"
.include "SetupTime.asm"
.include "SetupADC.asm"
.Include "RamblkSetup.asm"
    CALL ADCAVGSETUP
    sei
    jmp     Main
.include "ISR's.asm"




;****************************CHANGE STATE
STATESET:
CPI R16,0x55
BRNE    PC+2
CALL     SET
STATESET1:
CPI R16,0xAA
BRNE    PC+2
CALL     GET
STATERET:
RET
;******************

;*************Set mode
SET:	
;call specific loop
CPI R17,0x10
BRNE    PC+2
CALL SETSPEED
CPI R17,0x11
BRNE    PC+2
CALL STOP
CPI R17,0x12
BRNE    PC+2
CALL AUTOMODE
cpi R17,0x13 ;accell loop, continuesly send accelerometer data
BRNE    PC+2
CALL    GetDATALoop
RET
;*********
;****************GETMODE
GET:
cpi R17,0x10 ;Get speed
brne    GETSTOPTEST
CALL GETSPEED
GETSTOPTEST:
cpi R17,0x11 ;Get stop
brne    GETAUTOMODETEST
CALL GETSTOP
GETAUTOMODETEST:
cpi R17,0x12    ;Get automode
brne    GETTIMETEST
CALL GETAUTOMODE
GETTIMETEST:
cpi R17,0x13    ;Get timer status
brne GETACCELTEST
CALL    GETTIME
GETACCELTEST:
cpi R17,0x14
brne GETMOTORCOUNTERTEST
call    GETACCEL
GETMOTORCOUNTERTEST:
cpi R17,0x15
brne GETTPRTEST
call GETMOTORCOUNTER
GETTPRTEST:
cpi R17,0x16
brne ENDGET
call GETTPR
ENDGET:
RET
;******************



CALCADC:	;Read in from ADC, Calc the avg of last ADCAVGSIZE measurements
push R20
lds R20,Counter
inc R20
out PORTB,R20
sts Counter,R20
pop R20
ret



;******
;*MAIN
;******
Main:
MainLoop:
RJMP    MainLoop


GetDATALoop:
sei
CALL GETACCEL
CALL GETTPR
rjmp GetDATALoop

