;//Routines for the adc and things related to it


;################################################
;#############ADCSAMPLE##########################
;################################################


ADCSAMPLE: ;Get an ADC Sample and Put it into a ring buffer
    push        R19
    push        R18
    push        R17
    push        ZL
    push        ZH

    ;Read In ADC
    in          R19,ADCH
    ldi         R18,ACCELADJUST ;//Adjust for 0g error on accel
    ADD         R19,R18
    ;out        PORTB,R19 ;Debug

    ;ANDI       R19,0b00001111
    ;out        PORTB,R19 ;Debug
    ldi	        ZH,high(Readings)	; make high byte of Z point at the Readings list
    ldi         ZL,low(Readings)

    ldi         R18,0x00
    lds         R17,CurReading
    sub         R18,R17

    Loop:
        cpi         R18,0x00
        breq        STOPINC
        inc         R18
        ADIW        ZL,1
        rjmp        Loop

    STOPINC:
    st          Z,R19
    inc         R17
    cpi         R17,BUFFERSIZE
    brne        ENDT1
    ldi         R17,0x00
    ENDT1:
    sts         CurReading,R17
    pop         ZH
    pop         ZL
    pop         R17
    pop         R18
    pop         R19
    ret
    
;#######################################################
;#################MakeAverage###########################
;#######################################################


MakeAverage: ;//Read in from the Readings circle buffer, calculate the average. Put in R20

    push        R18
    push        R19
    push        R23
    push        R21
    push        ZH
    push        ZL
    ldi         R20,0x00 ;Here we hold the sum
    ldi         R21,0x00
    
    ldi	        ZH,high(Readings)	; make high byte of Z point at the Readings list
    ldi         ZL,low(Readings)
    ldi         R18,0x00
    ldi         R19,0x00
    AverageLoop:
    inc         R18
    LD	        R23,Z+
    add         R20,R23
    adc         R21,R19
    cpi         R18,BUFFERSIZE
    brne        AverageLoop
                    ;//Divide the sum //This doesn't adjust according to BUFFERSIZE. do it yourself!
    LSR         R21
    ROR         R20
    LSR         R21
    ROR         R20
    LSR         R21
    ROR         R20
    LSR         R21
    ROR         R20 //We have divided by 16
    LSR         R21
    ROR         R20
    LSR         R21
    ROR         R20
    
    pop         ZL
    pop         ZH
    pop         R21
    pop         R23
    pop         R19
    pop         R18
ret


