ldi R16,0
out TCCR1A,R16
ldi R16, (1<<CS11) 
out TCCR1B,R16 ;Timer 1, normal mode, 8x prescale
ldi R16,(1<<TOIE1) ;Enable timer 1 interrupt
out TIMSK,R16
