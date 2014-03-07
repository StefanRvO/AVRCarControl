;Sets up the stack to start from largest RAM adress
		ldi		R16, HIGH(RAMEND)
		out		SPH, R16
		ldi		R16, LOW(RAMEND)
		out		SPL, R16				
