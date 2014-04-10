;ADC converter
cbi     DDRA,0 ;Set PA0 to input
ldi R16, (1<<ADEN) | (1<<ADSC) |(1<<ADATE) |(1<<ADPS2)|(1<<ADPS1)| (1<<ADPS0) ;128xprescale (125Khz@16Mhz),Autotrigger
out ADCSRA,R16
ldi R16,0b01100000 ;ADC from port PA0, vcc reference
out ADMUX,R16
