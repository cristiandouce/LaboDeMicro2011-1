;*****************************************************************
;*	File: EFCmicro1.asm
;*	
;*	Espectrofotocolorimetro Microcontrolador 1
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
		;*	Inicialización del StackPointer
		ldi	tmp, low(RAMEND)
		out	SPL, tmp
		ldi	tmp, high(RAMEND)
		out	SPH, tmp


		;*	Si en lugar de hacer continua la configuracion SPI
		;*	se la llama por rcall, entonces se corre el valor 
		;*	del primer byte un bit hacia MSB

		rjmp MAIN

;*****************************************************************
;*	Configuración de la comunicación SPI en MASTER
;*****************************************************************
SPI_Master_Init:
		;*	Set de SCK, MOSI y ~SS como salidas y MISO como
		;*	entrada
		ldi tmp, 0b00101100
		out DDRB, tmp

		;*	Habilita comunicación SPI como MASTER a frecuencia
		;*	de clock de f/16
		ldi tmp, 0b01110001
		out SPCR, tmp
		ret

;*****************************************************************
;*	MAIN Program for microcontroller
;*****************************************************************
MAIN:
		;*	Asi es como deberia iniciarse, con un rcall
		rcall SPI_Master_Init

		rcall SPI_START
		ldi tmt, 'h'
		rcall SPI_Master_Transmit
		rcall SPI_Wait_Transmit
		sei
		sleep
		rcall SPI_STOP
		
		rcall SPI_START
		ldi tmt, 'o'
		rcall SPI_Master_Transmit
		rcall SPI_Wait_Transmit
		rcall SPI_STOP
		sei
		sleep

		rcall SPI_START
		ldi tmt, 'l'
		rcall SPI_Master_Transmit
		rcall SPI_Wait_Transmit
		rcall SPI_STOP
		sei
		sleep


		rcall SPI_START
		ldi tmt, 'a'
		rcall SPI_Master_Transmit
		rcall SPI_Wait_Transmit
		rcall SPI_STOP
		sei
		sleep

		rjmp END_PROGRAM


END_PROGRAM:
		rjmp END_PROGRAM


;*****************************************************************
;*	Rutinas START/STOP del SPI
;*****************************************************************
SPI_START:
		;*	Elijo el SLAVE con ~SS (PortB,2) en LOW
		cbi PORTB, 2
		ret

SPI_STOP:
		;*	Elijo el SLAVE con ~SS (PortB,2) en HIGH
		sbi PORTB, 2
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
;*	Rutina de delay para no pisar los bytes enviados
;*****************************************************************
	;*	Duracion de 197ms
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



;------------------------------------------------------------------------------------------------------------------------------------





;*****************************************************************
;*	Operaciones de las Interrupciones
;*****************************************************************
SPI_STC:
		in dta,SPDR
		reti
