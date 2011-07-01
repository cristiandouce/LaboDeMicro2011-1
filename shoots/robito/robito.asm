;**********************************************************
;**********************************************************
;*	Codigo para controlar un LCD
;**********************************************************
;**********************************************************


;**********************************************************
;*	Inclusion de librerias
;**********************************************************
.include "m88def.inc"

;**********************************************************
;*	Definiciones
;**********************************************************
.equ	LCD_RS	= 1
.equ	LCD_RW	= 2
.equ	LCD_E	= 3
.equ		Cero		=	0x30		;* Cero en hexa
.equ		CeroO	=	0x48		;* Cero en ascii


.def	temp	= r16
.def	argument= r17				;*argumento para subrutinas
.def	return	= r18				;*valor de retorno de subrutinas

;**********************************************************
;*	Codigo de inicializacion
;**********************************************************
.org 0
	rjmp inicio

inicio:
	ldi		temp,	low(RAMEND)
	out		SPL,	temp
	ldi		temp,	high(RAMEND)
	out		SPH,	temp

;**********************************************************
;*	Inicializacion del LCD
;**********************************************************
	rcall	LCD_init

;**********************************************************
;*	Envio "Funciona!" al Display del LCD
;**********************************************************


ldi		argument,0x02
ldi		r30,Cero
add		argument,r30
rcall	LCD_putchar

ldi	argument,0x03
ldi		r30,CeroO
add		argument,r30
rcall LCD_putchar
jm: rjmp jm
	rcall	LCD_wait
	ldi		argument, 'F'
	rcall	LCD_putchar	
	ldi		argument, 'u'
	rcall	LCD_putchar
	ldi		argument, 'n'
	rcall	LCD_putchar
	ldi		argument, 'c'
	rcall	LCD_putchar	
	ldi		argument, 'i'
	rcall	LCD_putchar
	ldi		argument, 'o'
	rcall	LCD_putchar
	ldi		argument, 'n'
	rcall	LCD_putchar	
	ldi		argument, 'a'
	rcall	LCD_putchar
	ldi		argument, ' '
	rcall	LCD_putchar
	ldi		argument,0xC0
	rcall	LCD_command
	rcall	LCD_wait
	ldi		argument, 'J'
	rcall	LCD_putchar
	ldi		argument, 'o'
	rcall	LCD_putchar
	ldi		argument, 'a'
	rcall	LCD_putchar
	ldi		argument, 'q'
	rcall	LCD_putchar
	ldi		argument, 'u'
	rcall	LCD_putchar
	ldi		argument, 'i'
	rcall	LCD_putchar
	ldi		argument, 'n'
	rcall	LCD_putchar
	ldi		argument, '!'
	rcall	LCD_putchar
	ldi		argument, '!'
	rcall	LCD_putchar
	ldi		argument, '!'
	rcall	LCD_putchar
	ldi		argument, '!'
	rcall	LCD_putchar

;**********************************************************
;*	Fin del programa
;**********************************************************
fin:
	rjmp	fin


;**********************************************************
;**********************************************************
;*	RUTINAS DEL PROGRAMA
;**********************************************************
;**********************************************************

;**********************************************************
;*	Rutina de inicializacion
;**********************************************************
LCD_init:	
	ldi		temp, 0b00001100		;*las lineas de control son salidas y el resto entradas
	out		DDRD, temp
	sbi		DDRC,1
	rcall	LCD_delay				;*esperamos que inicie el lcd
	
	ldi		argument, 0x20			;*Le decimos al lcd que queremos usarlo en modo 4-bit
	rcall	LCD_command8			;*ingreso de comando mientras aun esta en 8-bit
  	rcall	LCD_wait

	

	ldi		argument, 0x28			;*Seteo: 2 lineas, fuente 5*7 ,
	rcall	LCD_command				;
	rcall	LCD_wait

    

	ldi		argument, 0x0C			;*Display on, cursor off
	rcall	LCD_command
	rcall	LCD_wait

    
		
	ldi		argument, 0x01			;*borro display, cursor -> home
	rcall	LCD_command
	rcall	LCD_wait

	

	ldi		argument, 0x06			;*auto-inc cursor
	rcall	LCD_command
	ret

;**********************************************************
;*	Rutina para setear 4 bits mientras es de 8 bits
;**********************************************************
lcd_command8:						;*usado para inicializar
	in		temp, DDRD				;*seteamos el nibble alto de DDRD sin tocar nada mas
	sbr		temp, 0b11110000		;*seteo nibble alto en temp
	out		DDRD, temp				;*reemplazo DDRD
	in		temp, PortD				;*recupero el valor del puerto
	cbr		temp, 0b11110000		;*seteo los bits de datos
	cbr		argument, 0b00001111	;*y borro el nibble bajo del argumento para
	or		temp, argument			;no sobreescribir los bits de control
	out		PortD, temp				;*y escribo en el puerto.
	sbi		PortD, LCD_E			;*hago un pulso en E
	nop
	nop
	nop
	cbi		PortD, LCD_E
	in		temp, DDRD				;*vuelvo a dejar el DDRD con los bits de datos en entrada
	cbr		temp, 0b11110000
	out		DDRD, temp		
	ret

;**********************************************************
;*	Rutina para enviar caracter
;**********************************************************
lcd_putchar:
	push	argument				;*guardo el argumento
	in		temp, DDRD				;*guardo los bits de address de datos
	sbr		temp, 0b11110000		;*seteo los bits de datos en salida
	out		DDRD, temp		
	in		temp, PortD				;*recupero los datos de PortD
	cbr		temp, 0b11111110		;*borro todas las lineas de LCD
	cbr		argument, 0b00001111	;*escondo el nibble bajo del argumento
	or		temp, argument			;*seteo los bits del argumento en temp
	out		PortD, temp				;*y escribo el valor del puerto
	sbi		PortC, LCD_RS			;*seteo RS
	sbi		PortD, LCD_E			;*hago un pulso en E
	nop
	nop
	nop
	cbi		PortD, LCD_E
	pop		argument				;*recupero el argumento para usar el nibble bajo
	cbr		temp, 0b11110000		;*borro los bits de address de datos
	swap	argument				;*swapeo para poner el bit bajo en el alto
	cbr		argument, 0b00001111	;*borro los bits no usados en el argumento
	or		temp, argument			;*y los seteo en el puerto
	out		PortD, temp		
	sbi		PortC, LCD_RS			;*vuelvo a setear RS
	sbi		PortD, LCD_E			;*y poner un pulso en E
	nop
	nop
	nop
	cbi	PortD, LCD_E
	cbi	PortD, LCD_RS
	in	temp, DDRD
	cbr	temp, 0b11110000			;*las lineas de datos vuelven a ser salida
	out	DDRD, temp
	rcall	LCD_wait
	ret

;**********************************************************
;*	Rutina de commando 4 bits
;**********************************************************
lcd_command:						;*mismo que LCD_putchar, pero con RS bajo
	push	argument
	in		temp, DDRD
	sbr		temp, 0b11110000
	out		DDRD, temp
	in		temp, PortD
	cbr		temp, 0b11111110
	cbr		argument, 0b00001111
	or		temp, argument

	out		PortD, temp
	sbi		PortD, LCD_E
	nop
	nop
	nop
	cbi		PortD, LCD_E
	pop		argument
	cbr		temp, 0b11110000
	swap	argument
	cbr		argument, 0b00001111
	or		temp, argument
	out		PortD, temp
	sbi		PortD, LCD_E
	nop
	nop
	nop
	cbi		PortD, LCD_E
	in		temp, DDRD
	cbr		temp, 0b11110000
	out		DDRD, temp
	ret

;**********************************************************
;*	Rutina para obtener caracter
;**********************************************************
LCD_getchar:
	in		temp, DDRD				;*me aseguro que las lineas de dato sean entradas
	andi	temp, 0b00001111
	out		DDRD, temp
	sbi		PortC, LCD_RS			;*pongo RS alto
	sbi		PortD, LCD_RW			;*y RW
	sbi		PortD, LCD_E			;*seteo E
	nop
	in		temp, PinD				;*necesitamos el nibble alto
	andi	temp, 0b11110000		;*escondo los datos de comando
	mov		return, temp			;*y guardo el nibble alto en return
	cbi		PortD, LCD_E			;*y vuelvo a dejar E en 0
	nop								;*espero para volver a usar E
	nop	
	sbi		PortD, LCD_E			;*mismo que antes pero con el nibble bajo
	nop
	in		temp, PinD		
	andi	temp, 0b11110000
	swap	temp					;*swapeo
	or		return, temp			;*y junto con el anterior
	cbi		PortD, LCD_E			;*dejo en 0 las lineas de control
	cbi		PortC, LCD_RS
	cbi		PortD, LCD_RW
	ret								;*el caracter leido está en return

;**********************************************************
;*	Rutina para obtener direccion
;**********************************************************
LCD_getaddr:						;*funciona como LCD_getchar, pero con RS en 0, return.7 es la flag busy
	in		temp, DDRD
	andi	temp, 0b00001111
	out		DDRD, temp
	cbi		PortC, LCD_RS
	sbi		PortD, LCD_RW
	sbi		PortD, LCD_E
	nop
	nop
	nop
	nop
	nop
	in		temp, PinD
	andi	temp, 0b11110000
	mov		return, temp
	cbi		PortD, LCD_E
	nop
	nop
	sbi		PortD, LCD_E
	nop
	in		temp, PinD
	andi	temp, 0b11110000
	swap	temp
	or		return, temp
	cbi		PortD, LCD_E
	cbi		PortD, LCD_RW
	ret

;**********************************************************
;*	Rutina de espera de la BUSY FLAG
;**********************************************************
LCD_wait:							;*leer address y busy flags hasta que esté en 0 busy
	rcall	LCD_getaddr
	andi	return, 0x80
	brne	LCD_wait
	ret

;**********************************************************
;*	Rutina de Delay triple
;**********************************************************
LCD_delay:
	clr		r2
LCD_delay_externo:
	clr		r3
LCD_delay_interno:
	dec		r3
	brne	LCD_delay_interno
	dec		r2
	brne	LCD_delay_externo
	ret

delay40: ldi r25,11
ciclo:   dec r25
         brne ciclo
		 ret
