/*
 * shift_slave.asm
 *
 *  Created: 29/06/2011 21:56:43
 *   Author: alumno
 */ 


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
	
	.equ sclk=4
	.equ sdin=1
	.equ sdout=0
	.equ control=PORTD
;defino simbolos
	.def	tmp		=	r16
	.def	arg		=	r17		;*	argument for calling subroutines
	.def	rtn		=	r18		;*	rtn value from subroutines
	.def    dta		=	r19		;*	el q le da el master
	.def	tmt		=	r20
	.def	rcv		=	r21
	.def	usd		=	r22
	.def delay=r23
	.def pixel=r24

/******************************************************************************/
;Defino las variables
 .dseg
 .org 0x200
 var:	.byte	6


	.cseg
		.org 0x0000
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
		ldi	r26,low(var);x apunta a var
	    ldi	r27,high(var)
		ldi tmp,'a'
		st X+,tmp
		ldi tmp,'h'
		st X+,tmp
		ldi tmp,'o'
		st X+,tmp
		ldi tmp,'r'
		st X+,tmp
		ldi tmp,'a'
		st X+,tmp
		ldi	r26,low(var);x apunta a var
	    ldi	r27,high(var)
		cbi DDRD, 0;configuro RX como entrada
		sbi	DDRD, 1; TX como salida
		sbi DDRD,4; XCK como salida,master mode


		rjmp MAIN



;*****************************************************************
;*	MAIN Program for microcontroller
;*****************************************************************
MAIN:	rcall	SPI_Sinit
		rjmp   idle	
		
idle:
		sei
jm:
		rjmp jm





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
;*	Operaciones de las Interrupciones
;*****************************************************************
SPI_STC:
		in dta,SPDR;guardo el byte q me mando
		cpi dta,'s';me fijo si fue la orden 's'
		breq SENSOR_Init1;y voy a hacer la rutina dl sensor
		cpi dta,'d'
		breq SENSOR_Data
return_interrupt:
		reti

SENSOR_Init1:
		ldi tmp,'w'
		out	SPDR,tmp

		;rcall sensor
		ldi	r26,low(var);vuelvo a hacer q apunte al comienzo
	    ldi	r27,high(var)
		rjmp	return_interrupt

SENSOR_Data:
		ld tmp,X+
		out SPDR,tmp
		rjmp	return_interrupt	
		
sensor:
		rcall sensor_init
		rcall sensor_configuracion
		ldi delay,0xE2
		rcall timer;hago un delay d como minimo un milisegundo
		;Start integration
		ldi dta,0x08
		rcall send
		ldi delay,0xEA;pulso sclk 22 veces
		rcall timer

		ldi delay,0xF6;uso un tiempo d integracion d 2560us
		rcall timer
		;Detengo la integracion
		ldi dta,0x10
		rcall send
		ldi delay,0xFB;pulso el sckl 5 veces
		rcall timer

		;Start Pixel Readout
		;To initiate readout from the TSL3301, send the Start Read command and wait for a start bit on SDOUT:
		ldi dta,0x02
		rcall send
		;ahora recibo los pixeles por la usart
		ldi tmp,5;en realidad deberian ser 102
        
;mejorar esta parte
recibir:
		rcall USART_Receive
	    st X+,pixel;guardo el pixel en la variable var
	    dec tmp
	    brne recibir

		ldi tmp,'l'
		st X,tmp
		ret

			
		/***********************************************************/
;Inicio el sensor con la usart apagada para poder controlar el valor de sdin
;IMPORTANTE!
;en la datasheet esta al reves, tal vez sea importante
;cualquier cosa si no funciona lo doy vuelta

sensor_init:
           cbi control,sclk
	       cbi control,sdin
		   ldi tmp,0x04
	       out TCCR0B,r20;divido la frecuencia por 256
		   ldi tmp,0xE2
	       out TCNT0,r20; pongo el timer en -30
	       rcall clockmanual
		   ldi tmp,0x04
	       out TCCR0B,r20;divido la frecuencia por 256
		   ldi tmp,0xF6;pongo el timer en -10
		   out TCNT0,tmp
		   sbi control,sdin
		   rcall clockmanual
		   rcall USART_Init;de ahora en mas no uso mas el clock manual sino el d la usart
		   rcall sensor_reset
		   ldi delay,0xFB; va a contar 5 clock
		   rcall timer
		   ;IMPORTANTE en la datasheet dice 1F,mientras q en el informe 5F,cualquier cosa se cambia
		   ldi dta,0x1F;Write to mode register command;
		   rcall send
		   ldi dta,0x00;Clear mode register
		   rcall send
		   ret

/********************************************************************************************************/
;Esta rutina sirve sòlo para la inicializacion del sensor
;porque despues se usa la señal xck d la usart
;uso el timer ya pre escalado por 256
;para que tenga una frecuencia similar a la que va a tener el sensor
;cuando la usart le pase los dtas

clockmanual: sbi control,sclk
             cbi control,sclk  
             sbis TIFR0,0
             rjmp clockmanual
			 cbi TIFR0,0;pongo d nuevo el flag en cero
			 ldi arg,0x00
	         out TCCR0B,arg;apago el timer
			 ret
/**************************************************************************************************************/

USART_Init:
;seteo el baud rate
;importante:cuando lo uso en modo sincronico la frecuencia en xck
;esta relacionada con el baud rate, xq por cada pulso d clock en 
;xck se transmite un bit, x lo tanto una manera d saber el periodo
;en xck es hacer 1/baudrate
;Por eso es que cuando cuento los pulsos d sclk==xck,preescalo el timer por 256
;ya que da una frecuencia parecida a la de la usart
	ldi r17,0x00
	ldi r16,0x0C; un baud rate de 4800 fosc=1MHz 
	sts UBRR0H,r17
	sts UBRR0L,r16
	ldi r18,0b00100000; seteo el udre0
	sts UCSR0A,r18
	ldi r18,0b00011000;activo receptor y emisor
	sts UCSR0B,r18
	ldi r18,0b01000110;modo sincronico, 8 bits, sin bit d paridad
	sts UCSR0C,r18;con 1 solo bit d stop
	ret

/************************************************************************************************************/
;Rutina que realiza el reset
;Lo puse aparte porque en el informe que presentaron tiene un delay extra,y ya que es la unica vez que lo presenta
;preferi hacer una subrutina especial

sensor_reset: ldi dta,0x1B;codigo dl reset
              rcall USART_Transmit
			  ldi delay,0xFA;espero 6 pulsos de clock
			  rcall timer
			  ret


/*******************************************************************************************************************/
;Rutina que envia un byte por la usart

USART_Transmit:
		;Wait for empty transmit buffer
		lds	 r17,UCSR0A
		sbrs r17,UDRE0
		rjmp USART_Transmit
		; Put data into buffer, sends the data
		sts UDR0,dta
		ret
	
/********************************************************************************************************************/

USART_Receive:
; Wait for data to be received
	lds	 r17,UCSR0A
	sbrs r17,RXC0
	rjmp USART_Receive
; Get and return received data from buffer
	lds pixel, UDR0
	ret

/*************************************************************************************************************/
;Utilizo el timer con una frecuencia aproximada a la de la usart para poder contar los pulsos de la señal
;que va por sclk

timer:ldi r20,0x04
	  out TCCR0B,r20;divido la frecuencia por 256 y prendo el timer
      out TCNT0,delay;digo cuanto voy a contar
	  rcall contador
	  ldi r20,0x00
	  out TCCR0B,r20;apago el timer
	  cbi TIFR0,0;pongo d nuevo el flag en cero
	  ret

/***************************************************************************************************************/
;Contador espera a que se termine d contar y vuelve a la subrutina timer 	

contador: sbis TIFR0,0
          rjmp contador
		  ret

/*******************************************************************************************************************/
;Rutina que envia dtas al sensor
;ya incluye los pulsos de clock que necesita
;el sensor para procesar las instrucciones

send:    rcall USART_Transmit
		 ldi delay,0xFA
		 rcall timer;espera 6 clock para q se procese la instruccion
		 ret

/**********************************************************************************************************************/
;Subrutina que sirve para configurar la ganancia y el offset
;por las dudas voy a poner los valores normales

sensor_configuracion:
;In this example, we will set the gain to 0 and the offset to 0:
        ;Left offset
		ldi dta,0x40
		rcall send
		ldi dta,0x00;
		rcall send
		;Left gain
		ldi dta,0x41 
		rcall send
		ldi dta,0x00
		rcall send
		;Middle offset
		ldi dta,0x42
		rcall send
		ldi dta,0x00;
		rcall send
		;Middle gain
		ldi dta,0x43
		rcall send
		ldi dta,0x00
		rcall send
		;Right offset
		ldi dta,0x44
		rcall send
		ldi dta,0x00
		rcall send
		;Right gain
		ldi dta,0x45
		rcall send
        ldi dta,0x00
        rcall send
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


