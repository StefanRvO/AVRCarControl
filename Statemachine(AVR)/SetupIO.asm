ldi     R16,0xFF
;Port B is output
out     DDRB,R16
cbi     DDRA,0 ;Set PA0 to input
;turn On half the diodes
;ldi     R16,0b01010101
;out     PORTB,R16
;Set MOTOR pin as output
SBI     DDRD,7
;Set Magnet pin as output
SBI     DDRB,3
;Set brake pin as output
SBI DDRB,1
ldi     R19,0       ;Turn motor off
out     OCR2,R19
;out     OCR0,R19
ldi     R19, 1<<6 | 1<<COM01 | 0<<CS02 | 1<<CS01 | 0<<CS00
out     TCCR2,R19   ;Phase corrected PWM, 8x prescaler ;Timer2+Timer0
ldi     R19, 1<<6 | 1<<COM01 | 0<<CS02 | 1<<CS01 | 1<<CS00
out     TCCR0,R19
;interrupt on falling edge
ldi	R16,(1<<ISC01) | (1<<ISC00) | (1<<ISC11) | (1<<ISC10) 
out	MCUCR,R16
;Enable PD2 and PD3, pullup
SBI	PORTD,2
SBI	PORTD,3
;Enable external interrupt 1 (PD2)
ldi	R16,(1<<INT0) | (1<<INT1)
out	GICR,R16
