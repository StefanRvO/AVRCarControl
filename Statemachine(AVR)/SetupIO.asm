ldi     R16,0xFF
;Port B is output
out     DDRB,R16
cbi     DDRA,0 ;Set PA0 to input
;turn On half the diodes
ldi     R16,0b01010101
out     PORTB,R16
;Set MOTOR pin as output
SBI     DDRD,7
ldi     R19,0       ;Turn motor off
out     OCR2,R19
ldi     R19,0x61
out     TCCR2,R19   ;Phase corrected PWM, no prescale ;We use timer 2
;interrupt on falling edge
ldi	R16,(1<<ISC01) | (1<<ISC00) | (1<<ISC11) | (1<<ISC10) 
out	MCUCR,R16
;Enable PD2 pullup
SBI	PORTD,2
SBI	PORTD,3
;Enable external interrupt 1 (PD2)
ldi	R16,(1<<INT0) | (1<<INT1)
out	GICR,R16
