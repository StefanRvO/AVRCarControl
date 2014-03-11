;Enable serial communication and interrupts
		; Enable RX, TX and RX-interrupt
		ldi		R16, (1<<RXEN)|(1<<TXEN)|(1<<RXCIE)	
		out		UCSRB, R16

		; Asynchronous, no parity
		ldi		R16, (1<<URSEL)|(1<<UCSZ1)|(1<<UCSZ0)	
		out		UCSRC, R16

		; 9600 baud (for XTAL=16Mhz)
		ldi		R16,0xcf
		out		UBRRL,R16
		ldi     R16,(1<<U2X)
		out     UCSRA,R16
