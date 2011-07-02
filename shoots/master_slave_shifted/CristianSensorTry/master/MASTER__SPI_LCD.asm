/*
 * spilcd_master_.asm
 *
 *  Created: 29/06/2011 19:31:21
 *   Author: alumno
 */ 


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


;defino constantes
	.equ	LCD_RS	= 1
	.equ	LCD_RW	= 2
	.equ	LCD_E	= 3

	.equ	pCSS	=	1
	.equ	pSS		=	2
	.equ	pMOSI	=	3
	.equ	pMISO	=	4
	.equ	pSCK	=	5
	.equ	Cmaster =	0b01110001
	.equ	Cslave =	0b11100000

;defino simbolos
	.def	con		=	r23
	.def	tmp		=	r16
	.def	arg		=	r17		;*	argument for calling subroutines
	.def	rtn		=	r18		;*	return value from subroutines
	.def    dta		=	r19		;*	el q le da el master
	.def	tmt		=	r20
	.def	rcv		=	r21
	.def	usd		=	r22

;defino macros
	.MACRO	SPI_START;*	Elijo el SLAVE con ~SS (PortB,2) en LOW
		cbi PORTB, pSS
	.ENDMACRO
	.MACRO	SPI_STOP;*	Elijo el SLAVE con ~SS (PortB,2) en LOW
		sbi PORTB, pSS
	.ENDMACRO

	.MACRO	SendInstruction
		;* Cargo la instruccion a enviar en 'tmt'
		ldi tmt,@0

		;Transmito instruccion y espero
		SPI_START
		rcall SPI_Mtransmit
		rcall SPI_Wait
		SPI_STOP

		;* Cargo NULL para no afectar Slave
		ldi tmt,0

		;* Transmito, espero y Recibo del buffer
		SPI_START
		rcall SPI_Mtransmit
		rcall SPI_Wait
		rcall SPI_Mreceive
		SPI_STOP

	.ENDMACRO
	

	.dseg
		var:	.byte	6

	.cseg
	.org 0

		rjmp RESET
	

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
		
		;*	Habilito el LCD
		rcall	LCD_init
		;*	Espero la busy flag
	    rcall	LCD_wait
		;*Inicio el SPI como Master
		rcall 	SPI_Minit
		
		;* Ordeno el inicio del sensor
		rcall SlaveSensorInit
	
		;* Busco los datos de la lectura
		rcall PutSensorData

jm:		rjmp jm


SlaveSensorInit:
		;*	Mando al slave para que inicie la lectura del sensor
		SendInstruction 's'

		;*	Espero 1 segundo hasta que termine la lectura
		rcall DELAY
		ret

PutSensorData:
		;* cargo un contador para los 5 datos
		ldi con,5
start:
		;* Mando instruccion de lectura
		;* y levanto el dato
		SendInstruction 'd'
		
		;* Cargo el dato en argumento para llevar al lcd
		mov arg,rcv
		rcall LCD_Putchar
		rcall LCD_Wait

		;* Decremento el contador
		dec con
		brne start
		ret

;*****************************************************************
;*	Configuración de la comunicación SPI en MASTER
;*****************************************************************
SPI_Minit:
		;*	Set de SCK, MOSI y ~SS como salidas y MISO como
		;*	entrada
		sbi	DDRB,pMOSI
		sbi	DDRB,pSCK
		sbi	DDRB,pSS
		;cbi	DDRB,pCSS
		;*	Habilita comunicación SPI como MASTER a frecuencia
		;*	de clock de f/16
		ldi tmp, Cmaster
		out SPCR, tmp
		in tmp, SPSR
		in tmp, SPDR
		ret


;*****************************************************************
;*	Transmisión de 'tmt' por SPI al SLAVE
;*****************************************************************
SPI_Mtransmit:
		out	SPDR, tmt
		ret
;*****************************************************************
;*	Recepcion de 'rcv' por SPI del SLAVE
;*****************************************************************
SPI_Mreceive:
		in	rcv, SPDR
		ret

;*****************************************************************
;*	Espera del fin de la recepción SPI por Slave
;*****************************************************************
SPI_Wait:
		;*	Espera del fin de la recepción
		in tmp, SPSR
		sbrs tmp, SPIF
		rjmp SPI_Wait
		ret


;*****************************************************************
;*	Rutinas para trabajar con el LCD
;*****************************************************************

LCD_init:
	sbi	DDRC,LCD_RS
	sbi DDRD,LCD_RW
	sbi	DDRD,LCD_E
	rcall	LCD_delay				;*esperamos que inicie el lcd
	
	ldi		arg, 0x20			;*Le decimos al lcd que queremos usarlo en modo 4-bit
	rcall	LCD_command8			;*ingreso de comando mientras aun esta en 8-bit
  	rcall	LCD_wait

	

	ldi		arg, 0x28			;*Seteo: 2 lineas, fuente 5*7 ,
	rcall	LCD_command				;
	rcall	LCD_wait

    

	ldi		arg, 0x0C			;*Display on, cursor off
	rcall	LCD_command
	rcall	LCD_wait

    
		
	ldi		arg, 0x01			;*borro display, cursor -> home
	rcall	LCD_command
	rcall	LCD_wait

	

	ldi		arg, 0x06			;*auto-inc cursor
	rcall	LCD_command
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
		push arg;save the argmuent (it's destroyed in between)
		in	tmp, DDRD	;get data direction bits
		sbr	tmp, 0b11110000	;set the data lines to output
		out	DDRD, tmp		;write value to DDRD
		in	tmp, PortD		;then get the data from PortD
		cbr	tmp, 0b11111110	;clear ALL LCD lines (data and control!)
		cbr	arg, 0b00001111	;we have to write the high nibble of our argument first
					;so mask off the low nibble
		or	tmp, arg		;now set the argument bits in the Port value
		out	PortD, tmp		;and write the port value
		sbi	PortC, LCD_RS		;now take RS high for LCD char data register access
		sbi	PortD, LCD_E		;strobe Enable
		nop
		nop
		nop
		cbi	PortD, LCD_E
		pop	arg	;restore the argument, we need the low nibble now...
		cbr	tmp, 0b11110000	;clear the data bits of our port value
		swap	arg		;we want to write the LOW nibble of the argument to
					;the LCD data lines, which are the HIGH port nibble!
		cbr	arg, 0b00001111	;clear unused bits in argument
		or	tmp, arg		;and set the required argument bits in the port value
		out	PortD, tmp		;write data to port
		sbi	PortC, LCD_RS		;again, set RS
		sbi	PortD, LCD_E		;strobe Enable
		nop
		nop
		nop
		cbi	PortD, LCD_E
		cbi	PortC, LCD_RS
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
		cbi	PortC, LCD_RS;pongo en cero para decir q es instruccion
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

;*****************************************************************
;*	Rutina de DELAY
;*	Duracion de 1s aprox
;*****************************************************************
DELAY:
	rcall LCD_delay
	rcall LCD_delay
	rcall LCD_delay
	rcall LCD_delay
	rcall LCD_delay
	ret
	
