;******************
;***********INT0,MOTOR SENSOR
;******************
INT0_ISR:
push R16
in R16,SREG
push R17
push R18
;counter
lds R16,MotorSensorCount1 ;Read in motor counter
lds R17,MotorSensorCount2 ;Read in motor counter
lds R18,MotorSensorCount3 ;Read in motor counter
inc R16 ;Increase it
brne INT0_Counter_Done
inc R17
brne INT0_Counter_Done
inc R18
INT0_Counter_Done:
sts MotorSensorCount1,R16
sts MotorSensorCount2,R17
sts MotorSensorCount3,R18
INT0_ISR_END:
pop R18
pop R17
pop R16
out SREG,R16
pop R16
RETI

;*******************
;****INT1, Line sensor
INT1_ISR:
CALL 	GETMOTORCOUNTER
ldi 	R16,0x00
sts MotorSensorCount1,R16
sts MotorSensorCount2,R16
sts MotorSensorCount3,R16
reti 	




;******************* RECIVE INTERRUPT
RX_ISR: ;We always recive 3 bytes, put them in R16:R18
push    R16 ;Push  to stack
in      R16,SREG
push    R16
push    R17
push    R18
in      R16,UDR ;read recived into R16
;wait for new byte
RX_WAIT1:
SBIS    UCSRA,RXC
RJMP    RX_WAIT1
in  R17,UDR     ;Read into R17
RX_WAIT2:
SBIS    UCSRA,RXC
RJMP    RX_WAIT2
in    R18,UDR   ;Read into R18
CALL STATESET
pop     R18
pop     R17
pop     R16
out      SREG,R16
pop     R16
RETI
