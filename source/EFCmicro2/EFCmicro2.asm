;*****************************************************************
;*	File: EFCmicro2.asm
;*	
;*	Espectrofotocolorimetro Microcontrolador 2
;*	
;*	Autores:
;*			- Rodriguez Cañete, Macarena
;*			- Pepe, Ezequiel Ignacio
;*			- Douce Suárez, Cristian Gabriel
;*
;*	
;*
;*
;*
;*
	.include "m88def.inc"

	.org 0

	.equ	LCD_RS	= 1
	.equ	LCD_RW	= 2
	.equ	LCD_E	= 3

	.equ	pCSS	=	1
	.equ	pSS		=	2
	.equ	pMOSI	=	3
	.equ	pMISO	=	4
	.equ	pSCK	=	5
	
	.def	tmp		=	r16
	.def	arg		=	r17		;*	argument for calling subroutines
	.def	rtn		=	r18		;*	return value from subroutines
	.def    dta		=	r19		;*	el q le da el master
	.def	tmt		=	r20
	.def	rcv		=	r21



		rjmp RESET
	


;*****************************************************************
;*	Defino los vectores de interrupcion
;*****************************************************************
	.org 0x011
		rjmp SPI_STC ; SPI Transfer Complete Handler



;*****************************************************************
;*	Inicialización del Micro luego del RESET
;*****************************************************************
RESET:
		ldi	tmp, low(RAMEND)
		out	SPL, tmp
		ldi	tmp, high(RAMEND)
		out	SPH, tmp
		rjmp MAIN


;*****************************************************************
;*	MAIN Program for microcontroller
;*****************************************************************
MAIN:
		;*	Asi es como deberia funcionar
		rcall SPI_SlaveInit
		
		;*	Habilito el LCD
		rcall	LCD_init

		;*	Espero la busy flag
	    rcall	LCD_wait

		;*	Habilito las interrupciones

		rjmp END_PROGRAM


END_PROGRAM:
		sei
		rjmp END_PROGRAM



;*****************************************************************
;*	Configuración de la comunicación SPI en MASTER
;*****************************************************************
SPI_Master_Init:
		;*	Set de SCK, MOSI y ~SS como salidas y MISO como
		;*	entrada

		cbi DDRB,pMISO
		sbi	DDRB,pMOSI
		sbi	DDRB,pSCK
		sbi	DDRB,pSS
		sbi	DDRB,pCSS
		;*	Habilita comunicación SPI como MASTER a frecuencia
		;*	de clock de f/16
		ldi tmp, 0b01110001
		out SPCR, tmp
		ret



;*****************************************************************
;*	Configuración de la comunicación SPI en SLAVE
;*****************************************************************
SPI_SlaveInit:
		;*	Set MISO output, all others input
		sbi DDRB,pMISO
		cbi	DDRB,pMOSI
		cbi	DDRB,pSCK
		cbi	DDRB,pSS
		sbi	DDRB,pCSS
		;*	Habilita SPI, como SLAVE
		ldi r17,0b11100000
		out SPCR,r17
		ret


;*****************************************************************
;*	Operaciones de las Interrupciones
;*****************************************************************
SPI_STC:
		;*	Con transferencia completa leo el dato
		in dta,SPDR;guardo el byte q me mando

		;*	Escribo el dato en el LCD
		rcall	LCD_putchar
		rcall	LCD_wait
		
		;*	Busco iniciar comunicacion con MASTER
		rcall	SPI_Master_Init
		rcall	SPI_START
		ldi	tmt, 0x01
		rcall 	SPI_Master_Transmit
		rcall	SPI_Wait_Transmit
		rcall	SPI_STOP
		rcall	SPI_SlaveInit
		;*	Habilito nuevamente las interrupciones
		reti




;*****************************************************************
;*	Rutinas START/STOP del SPI
;*****************************************************************
SPI_START:
		;*	Elijo el SLAVE con ~SS (PortB,2) en LOW
		cbi PORTB, pCSS
		ret

SPI_STOP:
		;*	Elijo el SLAVE con ~SS (PortB,2) en HIGH
		sbi PORTB, pCSS
		ret



;*****************************************************************
;*	Transmisión de 'tmt' por SPI al SLAVE
;*****************************************************************
SPI_Master_Transmit:
		out	SPDR, tmt
		ret



;*****************************************************************
;*	Espera del fin de la recepción SPI
;*****************************************************************
SPI_Wait_Transmit:
		;*	Espera del fin de la recepción
		in tmp, SPSR
		sbrs tmp, SPIF
		rjmp SPI_Wait_Transmit
		ret



























;*****************************************************************
;*	Rutinas para trabajar con el LCD
;*****************************************************************
LCD_init:
		; cargo ese valor en el registro tmporal
		ldi	tmp, 0b00001110

		; lo pongo en DDRD,con eso las lineas d control son salidas, y el resto entradas
		out	DDRD, tmp

		;hago un delay d 197ms 
		rcall	LCD_delay

		; configuro en modo 4 bits
		ldi	arg, 0x20

		;LCD is still in 8-BIT MODE while writing this command!!!
		rcall LCD_command8
		rcall LCD_wait

		;NOW: 2 lines, 5*7 font, 4-BIT MODE!
		ldi	arg, 0x2C
		rcall LCD_command
		rcall LCD_wait

		;now proceed as usual: Display on, cursor on, blinking
		ldi	arg, 0x0F
		rcall LCD_command
		rcall LCD_wait

		;clear display, cursor -> home
		ldi	arg, 0x01
		rcall LCD_command
		rcall LCD_wait

		;auto-inc cursor
		ldi	arg, 0x06
		rcall LCD_command
		ret

;*	Used for init (we need some 8-bit commands to switch to 4-bit mode!)
lcd_command8:
		;we need to set the high nibble of DDRD while leaving
		in	tmp, DDRD
	
		;the other bits untouched. Using tmp for that.
		;set high nibble in tmp
		sbr	tmp, 0b11110000
		out	DDRD, tmp		;write value to DDRD again-> d7-d4 son salidas
		in	tmp, PortD		;then get the port value, aparentemente portd esta en cero x defecto
		cbr	tmp, 0b11110000	;borro the data bits 
		cbr	arg, 0b00001111	;then clear the low nibble of the argument
		;so that no control line bits are overwritten
		or	tmp, arg		;then set the data bits (from the argument) in the
		;Port value
		/*en argument tengo el argumento con el nibble d las variables d control en cero*/
		/*en tmp tngo los valores dl puerto d, con la parte d datos borrada*/
		out	PortD, tmp		;and write the port value.
		sbi	PortD, LCD_E		;now strobe E
		nop
		nop
		nop
		cbi	PortD, LCD_E
		in	tmp, DDRD		;get DDRD to make the data lines input again
		cbr	tmp, 0b11110000	;clear data line direction bits
		out	DDRD, tmp		;and write to DDRD
		ret

lcd_putchar:
		push dta;save the argmuent (it's destroyed in between)
		in	tmp, DDRD	;get data direction bits
		sbr	tmp, 0b11110000	;set the data lines to output
		out	DDRD, tmp		;write value to DDRD
		in	tmp, PortD		;then get the data from PortD
		cbr	tmp, 0b11111110	;clear ALL LCD lines (data and control!)
		cbr	dta, 0b00001111	;we have to write the high nibble of our argument first
					;so mask off the low nibble
		or	tmp, dta		;now set the argument bits in the Port value
		out	PortD, tmp		;and write the port value
		sbi	PortD, LCD_RS		;now take RS high for LCD char data register access
		sbi	PortD, LCD_E		;strobe Enable
		nop
		nop
		nop
		cbi	PortD, LCD_E
		pop	dta	;restore the argument, we need the low nibble now...
		cbr	tmp, 0b11110000	;clear the data bits of our port value
		swap	dta		;we want to write the LOW nibble of the argument to
					;the LCD data lines, which are the HIGH port nibble!
		cbr	dta, 0b00001111	;clear unused bits in argument
		or	tmp, dta		;and set the required argument bits in the port value
		out	PortD, tmp		;write data to port
		sbi	PortD, LCD_RS		;again, set RS
		sbi	PortD, LCD_E		;strobe Enable
		nop
		nop
		nop
		cbi	PortD, LCD_E
		cbi	PortD, LCD_RS
		in	tmp, DDRD
		cbr	tmp, 0b11110000	;data lines are input again
		out	DDRD, tmp
		ret

lcd_command:	;same as LCD_putchar, but with RS low!
		push	arg;guardo la instruccion
		in	tmp, DDRD;copio en tmp 00001110
		sbr	tmp, 0b11110000; hago un or, entonces pongo en 1 el nibble alto
		out	DDRD, tmp;pongo este valor en DDRD x lo tanto d7-d4 son salidas
		in	tmp, PortD;guardo el valor dl puerto
		cbr	tmp, 0b11111110;hago una and con 01,borro todos los bits
		cbr	arg, 0b00001111;hago una and con F0, borro los 4 bits d control
		or	tmp, arg;hago una or me quedan los 4 bits altos d la instruccion y cero debajo
		out	PortD, tmp; lo cargo en el puerto
		sbi	PortD, LCD_E
		nop
		nop
		nop
		cbi	PortD, LCD_E
		pop	arg;saco el argumento d la pila
		cbr	tmp, 0b11110000; hago una and con 0F, borro los dl nibble alto dejo los d control en cero
		swap	arg;intercambio el nibble alto con el bajo
		cbr	arg, 0b00001111;hago una and con F0,borro el nibble inferior d argument
		or	tmp, arg;hago or con tmp
		out	PortD, tmp;cargo en el puerto 
		sbi	PortD, LCD_E
		nop
		nop
		nop
		cbi	PortD, LCD_E
		in	tmp, DDRD
		cbr	tmp, 0b11110000; vuelvo a poner el nibble alto en cero para q sea entrada.
		out	DDRD, tmp
		ret

LCD_getaddr:	;works just like LCD_getchar, but with RS low, return.7 is the busy flag
		in	tmp, DDRD
		andi tmp, 0b00001111;esto es al pedo
		out	DDRD, tmp
		cbi	PortD, LCD_RS;pongo en cero para decir q es instruccion
		sbi	PortD, LCD_RW; en uno para leer
		sbi	PortD, LCD_E; seteo enable
		nop
		in	tmp, PinD;guardo lo q estaba en el pin
		andi	tmp, 0b11110000;borro la parte d las variables d control
		mov	rtn, tmp;pongo en return ese valor
		cbi	PortD, LCD_E;pongo enable en cero
		nop
		nop;espero
		sbi	PortD, LCD_E;pongo enable en uno
		nop
		in	tmp, PinD; guardo lo q esta en el pin, q es nibble bajo d la direccion, en realidad no lo necesito
		andi	tmp, 0b11110000;borro la parte d las variables d control
		swap	tmp; pongo el nibble alto en el bajo
		or	rtn, tmp;hago un or con return,tngo la dire completa
		cbi	PortD, LCD_E;pongo enable en cero
		cbi	PortD, LCD_RW; pongo rw en cero
		ret

;*****************************************************************
;*	Rutina de BUSY FLAG
;*****************************************************************
LCD_wait:				;read address and busy flag until busy flag cleared
		rcall	LCD_getaddr
		andi	rtn, 0x80;hago un and con 10000000
		brne	LCD_wait;sale d aca solo cuando el busy flag es cero
		ret


;*****************************************************************
;*	Rutina de DELAY
;*	Duracion de 197ms
;*****************************************************************
LCD_delay:
		clr	r2;pongo r2 en cero
LCD_delay_outer:
		clr	r3;pongo r3 en cero
LCD_delay_inner:
		dec r3;decremento r3
		brne LCD_delay_inner; sale del ciclo si r3 es igual a cero
		dec	r2;cuando ya hizo 255us decremento r2
		brne LCD_delay_outer;sale dl ciclo si r2 es igual a cero
		ret
