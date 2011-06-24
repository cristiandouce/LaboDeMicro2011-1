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
;defino constantes
	.equ	pCSS	=	1
	.equ	pSS		=	2
	.equ	pMOSI	=	3
	.equ	pMISO	=	4
	.equ	pSCK	=	5
	.equ	Cslave =	0b11100000
;defino simbolos
	.def	tmp		=	r16
	.def	arg		=	r17		;*	argument for calling subroutines
	.def	rtn		=	r18		;*	return value from subroutines
	.def    dta		=	r19		;*	el q le da el master
	.def	tmt		=	r20
	.def	rcv		=	r21
	.def	usd		=	r22
	


	.org 0x0000
	.cseg
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
MAIN:	rcall	SPI_Sinit
		rcall   idle	
		


idle:	sei
		rjmp idle





;*****************************************************************
;*	Configuración de la comunicación SPI en SLAVE
;*****************************************************************
SPI_Sinit:
		;*	Set MISO output, all others input
		sbi DDRB,pMISO
		sbi	DDRB,pCSS
		;*	Habilita SPI, como SLAVE
		ldi r17,Cslave
		out SPCR,r17
		in	tmp,SPSR
		in	tmp,SPDR
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
		inc dta
		out	SPDR,dta
		reti
