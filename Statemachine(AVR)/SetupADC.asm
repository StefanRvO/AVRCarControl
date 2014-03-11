;ADC converter
cbi     DDRA,0 ;Set PA0 to input
ldi R16,0b10000111 ;128xprescale (125Khz@16Mhz),no interrupt
out ADCSRA,R16
ldi R16,0b01100000 ;ADC from port PA0, vcc reference
out ADMUX,R16
