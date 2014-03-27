ADCAVGSETUP:
push R16
push R17
ldi	ZH,high(ADCAVG+1<<1)	; make high byte of Z point at address of ADCAVG+1
ldi ZL,low(ADCAVG+1<<1)
ldi R16,ADCAVGSIZE

ADCSETUPLOOP:
cpi	R16,0x00
breq ADCSETUPEND
SBI ADCSRA,ADSC ;start conversion
WAITADCSETUP:
SBIS ADCSRA,ADIF ;is adc done?
rjmp    WAITADCSETUP
in R17,ADCH
st Z+,R17
rjmp ADCSETUPLOOP
ADCSETUPEND:
;Enable auto-trigger mode.
pop R17
pop R16
ret
