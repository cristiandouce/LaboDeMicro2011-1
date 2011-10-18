.include "m88def.inc"
			rjmp	restart


restart:ldi		r16,high(RAMEND)	; Main program start
		out 	SPH,r16 			; Set Stack Pointer to top of RAM
		ldi 	r16,low(RAMEND)
		out 	SPL,r16
	 	ldi		r16,0xFF 			; 8 Ones into the universal register
		out		DDRB,r16
loop:	ldi		r16,0b00000011
		out		PORTB,r16
		rcall	delay
		ldi		r16,0b00000110
		out		PORTB,r16
		rcall	delay
		ldi		r16,0b00001100
		out		PORTB,r16
		rcall	delay
		ldi		r16,0b00001001
		out		PORTB,r16
		rcall	delay
		rjmp 	loop
delay:	ldi		r18,0xFF
loop1:	dec		r18
		ldi		r19,0xFF
loop2:	dec		r19
		ldi		r20,0xFF
loop3:	dec		r20
		brne	loop3
		brne	loop2
		brne	loop1
		ret
