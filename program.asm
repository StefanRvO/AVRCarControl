;indicator LEDS: { PA0: DATA RECIEVED       ///!!!CONNECT LEDS THROUGH 
;                  PA1: DATA TRANSMITTED    ///!!!CURRENT LIMITING
;                  PA2: MOTOR PWM CHANGED   ///!!!RESISTOR,EG. 100 OHM
;                }
;
;
.include "m32def.inc"
.org 0x0000
    rjmp    Reset
    
.org    0x0020
Reset:  
LDI     R16,HIGH(RAMEND) ;Stack Setup
OUT     SPH,R16
ldi     R16,LOW(RAMEND)
out     SPL,R16

;Setup Serial Communication with BT-module
LDI     R16,(1<<TXEN) | (1<<RXEN)   ;enable transmitter and reciver
OUT     UCSRB,R16
LDI     R16,(1<<UCSZ1) | (1<<UCSZ0) |(1<<URSEL) ;8-bit data
out     UCSRC,R16   ;no parity,1 stop bit
LDI     R16,0xcf    ;9600 baud
out     UBRRL,R16   ;for XTAL=16mhz
ldi     R16,(1<<U2X) ;double baud rate (needed for 9600 baud at 16 mhz)
out     UCSRA,R16

;setup PWM
SBI     DDRD,7      ;Set OC2 (PD7-motor pin) as output
SBI     DDRA,0      ;set PA0 out
SBI     DDRA,1      ;set PA1 out
SBI     DDRA,2      ;Set PA2 out
ldi     R19,0       ;Turn motor off
out     OCR2,R19
ldi     R19,0x00      ;turn LEDS off
out     PORTA,R19     
ldi     R19,0x61
out     TCCR2,R19   ;Phase corrected PWM, no prescale


RECIVE:
SBIS    UCSRA,RXC      ;Check if UDR is empty(is there something to recive)
RJMP    RECIVE
IN      R18,UDR     ;SEND RECIVED TO R18
ldi     R20,0x01    ;turn on recive led
out     PORTA,R20
mov     R19,R18
CALL    SETPWM
ldi     R20,0x00    ;turn off recive led
CALL    DELAY             ;wait a bit
out     PORTA,R20    
ldi     R17,'S'
CALL    TRANSMIT
ldi     R17,'E'
CALL    TRANSMIT
ldi     R17,'T'
CALL    TRANSMIT
ldi     R17,' '
CALL    TRANSMIT
mov     R17,R18     ;Move recived to R17
CALL    TRANSMIT
RJMP    RECIVE

TRANSMIT: ;sends char in reg17
ldi     R20,0x02    ;turn on transmit led
out     PORTA,R20
SBIS    UCSRA,UDRE  ;is UDR empty?
RJMP    TRANSMIT    ;if not, wait
OUT     UDR,R17
ldi     R20,0x00    ;turn off transmit led
out     PORTA,R20
RET                    ;Return

SETPWM: ;Set PWM on PD7 to value in R19
out     OCR2,R19
ldi     R20,0x04    ;PWM diode view
out     PORTA,R20
CALL    DELAY
ldi     R20,0x00
out     PORTA,R20
RET

DELAY:
ldi     R21,0xFF 
DELAY2:
        DEC R21
        nop
BRNE    DELAY2
RET
