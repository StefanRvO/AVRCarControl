# Makefile for programming ATmega32 using assembler
PROJECT=main
PROGRAMMER=-c avrispmkII -P usb # For the large blue AVR MKII
#PROGRAMMER=-c stk500v1 -P /dev/ttyUSB0 # For the small green programmer

default:
	avra $(PROJECT).asm
	sudo avrdude -p m32 $(PROGRAMMER) -U flash:w:$(PROJECT).hex 

clean:
	rm -f $(PROJECT).obj $(PROJECT).hex $(PROJECT).cof $(PROJECT).eep.hex
	
fuse:
	sudo avrdude -p m32 $(PROGRAMMER) -U hfuse:w:0x9E:m -U lfuse:w:0x3f:m  -U lock:w:0x3f:m
