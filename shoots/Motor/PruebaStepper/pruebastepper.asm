 .include "m88def.inc" 
		 rjmp RESET ; Reset Handler


RESET:	ldi		r16,high(RAMEND)	; Main program start
		out 	SPH,r16 			; Set Stack Pointer to top of RAM
		ldi 	r16,low(RAMEND)
		out 	SPL,r16
		ldi		r18,0x00			; mis flags
		ldi		r16,0x00			; 8 zeros in universal register
		out		DDRD,r16			; to data direction register
	 	ldi		r16,0xFF 			; 8 Ones into the universal register
	 	out		PORTD,r16 			; and to port D (these are the pull-ups now!)
		out		DDRB,r16
		ldi		r16,0b00000011			; and to the data direction register
		out		PORTB,r16 			; and to the outputregisters.
loop:	in 		r17,PIND
		sbrs	r17,0 				; Jump if bit 0 in port D input is one
		rcall	setmov				; Relative call to the subroutine named Lampe0
		sbrc	r18,0
		rcall	mover
		rjmp 	loop

setmov:	sbr 	r18,1
		ret
mover:	sbrs	r17,1
		rcall	fini
		sbrs	r17,2
		rcall	find
		sbrs	r18,1
		rcall	movetei
		sbrc	r18,1
		rcall	moveted
		sbrc	r18,2
		rjmp	RESET
		ret


movetei:rcall	delay
		rcall	pasoi
		ret

moveted:rcall	delay
		rcall	pasod
		ret

settest:ldi		r26,0b00001101
		out		PORTB,r26
		ret



fini: 	sbr		r18,2
		ret
find: 	sbr		r18,4
		ret

pasoi:	in		r19,PORTB
		cpi		r19,0b00001001
		breq	paso1i
		cpi		r19,0b00000011
		breq	paso2i
		cpi		r19,0b00000110
		breq	paso3i
		cpi		r19,0b00001100
		breq	paso4i
		ret
paso1i:	ldi		r20,0b00000011
		out		PORTB,r20
		ret
paso2i: ldi		r20,0b00000110
		out		PORTB,r20
		ret
paso3i:	ldi		r20,0b00001100
		out		PORTB,r20
		ret
paso4i:	ldi		r20,0b00001001
		out		PORTB,r20
		ret

pasod:	in		r19,PORTB
		cpi		r19,0b00001001
		breq	paso1d
		cpi		r19,0b00000011
		breq	paso2d
		cpi		r19,0b00000110
		breq	paso3d
		cpi		r19,0b00001100
		breq	paso4d
		ret
paso1d:	ldi		r20,0b00001100
		out		PORTB,r20
		ret
paso2d: ldi		r20,0b00001001
		out		PORTB,r20
		ret
paso3d:	ldi		r20,0b00000011
		out		PORTB,r20
		ret
paso4d:	ldi		r20,0b00000110
		out		PORTB,r20
		ret

delay:	ldi		r21,0xFF
loop1:	dec		r21
		ldi		r22,0x20
loop2:	dec		r22
		brne	loop2
		cpi		r21,0x00
		brne	loop1
		ret












