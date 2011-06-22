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

	.def	temp		=	r16
	.def	transmit	=	r17
	.def	receive		=	r18

	rjmp RESET

;*****************************************************************
;*	Inicialización del Micro luego del RESET
;*****************************************************************
RESET:
		;*	Inicialización del StackPointer
		ldi	temp, low(RAMEND)
		out	SPL, temp
		ldi	temp, high(RAMEND)
		out	SPH, temp


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
		ldi temp, 0b00101100
		out DDRB, temp

		;*	Habilita comunicación SPI como MASTER a frecuencia
		;*	de clock de f/16
		ldi temp, 0b01110001
		out SPCR, temp
		ret

;*****************************************************************
;*	MAIN Program for microcontroller
;*****************************************************************
MAIN:
		;*	Asi es como deberia iniciarse, con un rcall
		rcall SPI_Master_Init

		rcall SPI_START
		ldi transmit, 'h'
		rcall SPI_Master_Transmit
		rcall SPI_Wait_Transmit
		rcall SPI_STOP

		rcall LCD_Delay
		rcall LCD_Delay

		rcall SPI_START
		ldi transmit, 'o'
		rcall SPI_Master_Transmit
		rcall SPI_Wait_Transmit
		rcall SPI_STOP

		rcall LCD_Delay
		rcall LCD_Delay

		rcall SPI_START
		ldi transmit, 'l'
		rcall SPI_Master_Transmit
		rcall SPI_Wait_Transmit
		rcall SPI_STOP

		rcall LCD_Delay
		rcall LCD_Delay

		rcall SPI_START
		ldi transmit, 'a'
		rcall SPI_Master_Transmit
		rcall SPI_Wait_Transmit
		rcall SPI_STOP

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
;*	Transmisión de 'transmit' por SPI al SLAVE
;*****************************************************************
SPI_Master_Transmit:
		out	SPDR, transmit
		ret

;*****************************************************************
;*	Espera del fin de la recepción SPI
;*****************************************************************
SPI_Wait_Transmit:
		;*	Espera del fin de la recepción
		in temp, SPSR
		sbrs temp, SPIF
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
