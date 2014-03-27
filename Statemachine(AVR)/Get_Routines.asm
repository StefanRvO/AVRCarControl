GETSPEED:
push R20
push R21
ldi	ZH,high(TransMSG<<1)	; make high byte of Z point at address of msg
ldi ZL,low(TransMSG<<1)
in  R20,OCR2
ST  Z+,R20
ldi R20,1
sts  TransNum,R20
ldi R20,0xBB
ldi R21,0x10
call TRANSREPLY
pop R21
pop R22
ret

GETTPR: ;Send ticks between last two motor rotations7
push R16
push R17
push R20
push R21
;push R22
lds R16,TickTime1
lds R17,TickTime2
lds R20,TickTime3
lds R21,TickTime4
;lds R22,TickTime5
ldi	ZH,high(TransMSG<<1)	; make high byte of Z point at address of msg
ldi ZL,low(TransMSG<<1)
ST Z+,R16
ST Z+,R17
ST Z+,R20
ST Z+,R21
;ST Z+,R22
ldi R16,0x04
sts TransNum,R16
ldi R20,0xbb
ldi R21,0x16
CALL TRANSREPLY
;pop R22
pop R21
pop R20
pop R17
pop R16
RET

GETSTOP:
nop ;Does nothing ATM
ret

GETAUTOMODE:
nop ;Does nothing ATM
ret

GETACCEL: ;Read adc at PA0
SBI ADCSRA,ADSC ;start conversion
push R20
push R21
ldi	ZH,high(TransMSG<<1)	; make high byte of Z point at address of msg
ldi ZL,low(TransMSG<<1)
WAITADC:
SBIS ADCSRA,ADIF ;is adc done?
rjmp    WAITADC
in R20,ADCL
in R21,ADCH
;out PORTB,R21 ;Put value (first 8 bit) on port b (for debugging..?)
ST  Z+,R21 
ST  Z+,R20         ;         ; Put in RAM for transfer
ldi R20,2        ;
sts  TransNum,R20          ;
ldi R20,0xBB ;Response headers
ldi R21,0x14
CALL TRANSREPLY
pop R21
pop R20
RET


GETTIME: ;Send the speed
    push R20
    push R21
    push R22
    push R23
    push R24
    CLC     ;Clear carry flag
    ;fetch clock
    in   R20,TCNT1L ;Timer 1 low
    lds  R22,T1_Counter1     ;what if timer overflows while in interrupt?
    lds  R23,T1_Counter2
    lds  R24,T1_Counter3
    in  R21,TIFR
    SBRS    R21,TOV1 ;Increment R22 if we have a overflow
    inc R22
    cpi R22,0x00
    BRNE    END_INC_GETTIME
    inc R23
    cpi R23,0x00
    BRNE    END_INC_GETTIME
    inc R24
    END_INC_GETTIME: 
    in   R21,TCNT1H ;Timer 1 high 
    ;fetch done
    ;Put Time in TransMSG
    ldi	ZH,high(TransMSG<<1)	; make high byte of Z point at address of msg
    ldi ZL,low(TransMSG<<1)
    ST  Z+,R24
    ST  Z+,R23
    ST  Z+,R22
    ST  Z+,R21
    ST  Z+,R20
    ldi  R20,5
    sts  TransNum,R20
    ldi  R20,0xBB ;Respond header
    ldi  R21,0x13
    call    TRANSREPLY
    pop R24
    pop R23
    pop R22
    pop R21
    pop R20
    ret

GETMOTORCOUNTER: ;Send the motor counter
    push R20
    push R21
    push R22
    ;fetch motor counter
    lds  R22,MotorSensorCount1
    lds  R21,MotorSensorCount2
    lds  R20,MotorSensorCount3
    ;Put counter in TransMSG
    ldi	ZH,high(TransMSG<<1)	; make high byte of Z point at address of msg
    ldi ZL,low(TransMSG<<1)
    ST  Z+,R20
    ST  Z+,R21
    ST  Z+,R22
    ldi  R20,3
    sts  TransNum,R20
    ldi  R20,0xBB ;Respond header
    ldi  R21,0x15
    call    TRANSREPLY
    pop R22
    pop R21
    pop R20
    ret
