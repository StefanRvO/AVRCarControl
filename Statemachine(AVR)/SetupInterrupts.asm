.org 0x0000
jmp     Reset
.org 0x0012 ;timer1 overflow
jmp T1_OVFLW

.org 0x001A
jmp     RX_ISR
