; ********************************************
; * Division sub-routine
; ********************************************	
; Calculates division with numerator R20:R19
; and denominator R18 and puts result into
; R20:R19 and divide_remainder into R18
.def divide_counter = R16
.def divide_highbyte = R20
.def divide_lowbyte =R19
.def divide_divisor = R18
.def divide_remainder = R18

divide:
push    R16
push    R21

ldi divide_counter,0x00
divide_loop1:
    inc divide_counter
    sub divide_highbyte,divide_divisor
    brsh divide_loop1
add divide_highbyte,divide_divisor
dec divide_counter
mov R21,divide_counter
ldi divide_counter,0x00
divide_loop2:
        inc divide_counter
        sub divide_lowbyte,divide_divisor
        brsh divide_loop2
    dec divide_highbyte
	   cpi divide_highbyte,0xff
    brne divide_loop2
add divide_lowbyte,divide_divisor
dec divide_counter
mov divide_remainder,divide_lowbyte
mov divide_highbyte,R21
mov divide_lowbyte,divide_counter
end:
pop R21
pop R16
ret

