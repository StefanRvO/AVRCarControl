ldi ZL,LOW(Readings)
ldi ZH,HIGH(Readings)
ldi R18,0x00
InitADCLoop:
cpi R18,BUFFERSIZE
breq ENDINITADC
in  R16,ADCH
st  Z+,R16
inc R18
rjmp InitADCLoop

ENDINITADC:
