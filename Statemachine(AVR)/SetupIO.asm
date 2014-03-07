ldi     R16,0xFF
;Port B is output
out     DDRB,R16
;turn On half the diodes
ldi     R16,0b01010101
out     PORTB,R16
