TRANSREPLY:  ;Sends the data in R20:R21 (header), followed by data starting from 0x301 and forward the number of bytes in 0x300
SBIS    UCSRA,UDRE
RJMP    TRANSREPLY
out     UDR,R20
TRANSREPLY1:
SBIS    UCSRA,UDRE
RJMP    TRANSREPLY1
out     UDR,R21
ldi	ZH,high(TransMSG<<1)	; make high byte of Z point at address of msg
ldi ZL,low(TransMSG<<1)
push R22
push R23
lds R23,TransNum
inc R23 ;Need to inc to get correct count
TRANSREPLYloop:
SBIS    UCSRA,UDRE
RJMP    TRANSREPLYloop
dec    R23
BREQ   TRANSREPLYEXIT
ld     R22,Z+
out     UDR,R22
rjmp    TRANSREPLYloop
TRANSREPLYEXIT:
pop R23
pop R22
RET
