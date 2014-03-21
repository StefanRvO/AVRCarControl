;Enable serial communication and interrupts
		; Enable RX, TX and RX-interrupt
		ldi		R16, (1<<RXEN)|(1<<TXEN)|(1<<RXCIE)	
		out		UCSRB, R16

		; Asynchronous, no parity
		ldi		R16, (1<<URSEL)|(1<<UCSZ1)|(1<<UCSZ0)	
		out		UCSRC, R16

		; 9600 baud (for XTAL=8Mhz)
		ldi		R16,HIGH(51)
		out		UBRRH,R16		
		ldi		R16,LOW(51)
		out		UBRRL,R16
		
