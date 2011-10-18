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
	.def	usd		=	r22


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
;*	MAIN Program for microcontroller
;*****************************************************************
MAIN:
		;*	Inicio Micro1 como master
		rcall SPI_Master_Init
		rcall LCD_delay
		rcall LCD_delay
		rcall SPI_START
		ldi tmt, 'h'
		rcall SPI_Master_Transmit
		rcall SPI_Wait_Transmit
		rcall SPI_STOP
		rcall SPI_SlaveInit
		rcall wait_interrupt
		
		rcall SPI_Master_Init
		rcall SPI_START
		ldi tmt, 'o'
		rcall SPI_Master_Transmit
		rcall SPI_Wait_Transmit
		rcall SPI_STOP
		rcall SPI_SlaveInit
		rcall wait_interrupt
		rcall SPI_Master_Init
		rcall SPI_START
		ldi tmt, 'l'
		rcall SPI_Master_Transmit
		rcall SPI_Wait_Transmit
		rcall SPI_STOP
		rcall SPI_SlaveInit
		rcall wait_interrupt
		rcall SPI_Master_Init
		rcall SPI_START
		ldi tmt, 'a'
		rcall SPI_Master_Transmit
		rcall SPI_Wait_Transmit
		rcall SPI_STOP
		rcall SPI_SlaveInit
		rcall wait_interrupt
		rcall SPI_Master_Init
		rjmp END_PROGRAM


END_PROGRAM:
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
		cbi	DDRB,pSS
		sbi	DDRB,pCSS
		;*	Habilita comunicación SPI como MASTER a frecuencia
		;*	de clock de f/16
		ldi tmp, 0b01110001
		out SPCR, tmp
		ret


;*****************************************************************
;*Espero una interrupcion
;*****************************************************************
wait_interrupt:
isit:	sei
		cpi		 usd,0xF0
		brne	isit
		cli
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



;*****************************************************************
;*	Operaciones de las Interrupciones
;*****************************************************************
SPI_STC:
		in dta,SPDR
		ldi 	usd,0xF0
		reti
