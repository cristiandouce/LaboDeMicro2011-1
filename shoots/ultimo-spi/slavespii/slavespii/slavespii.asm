

 .include "inc/m88def.inc"
.def	tmp	= r16
.def	arg = r17		;argument for calling subroutines
.def	rtn	= r18		;return value from subroutines
.def    dta = r19;el q le da el master
;/******************************************************************************/
;Defino las variables
 .dseg
 var:	.byte	6
 ;/*******************************************************************************/
 ;Defino el segmento de codigo
.org 0
.cseg
		rjmp main
;/********************************************************************************/
;Vector de interrupciones
.org 0x011;defino el vector d la interrupcion
		rjmp SPI_STC ; SPI Transfer Complete Handler
;/*********************************************************************************/
;Programa principal
main:	ldi	tmp, low(RAMEND)
	    out	SPL, tmp
	    ldi	tmp, high(RAMEND)
	    out	SPH, tmp
	    ldi	r26,low(var);x apunta a var
	    ldi	r27,high(var)
SPI_SlaveInit:
;set MISO output, all others input
		ldi r17,0x10
		out DDRB,r17
;habilito SPI,interrupciones d spi, como slave,lsb primero, f=fosc/16
		ldi r17,0b11100001
		out SPCR,r17
comienzo:
;habilito las interrupciones
	    ldi r18,'a'
		ldi r19,5
cargo:	st X+,r18
		dec r19
		brne cargo
		ldi r18,'l'
		st X+,r18
		sei
fin:    rjmp fin;espero hasta q el master me mande el msj
;/*********************************************************************************************/
;Rutina que realiza la interrupcion
SPI_STC:
        in dta,SPDR;guardo el byte q me mando
		cpi dta,'s';me fijo si fue la orden 's'
		breq desactivar;y voy a hacer la rutina dl sensor
		cpi dta,'p';me fijo si es p
		breq mostrar;hago otra cosa x el momento no es nada,pero podria ser prender la lampara
final:    reti
desactivar: 
        cli;desactivo todas las interrupciones
	;pongo sck,mosi y ~ss como salidas; miso como entrada
		ldi r16,0b00101100
		out DDRB,r16
		;desactivo las interrupciones x spi y me convierto en master
		ldi r17,0b01110001
	    out SPCR,r17
		;rcall sensor,esto seria idealmente
		in r16,SPSR;leo esto para que se borre el flag spif
		in dta,SPDR;esto tb es para q se borre hay q hacer las dos cosas
elijo_esclavo:
        cbi PORTB,2;comienzo la comunicacion y le mando lo q esta en var
		ldi r23,6;inicializo contador
		ldi	r26,low(var);vuelvo a hacer q apunte al comienzo
	    ldi	r27,high(var)
pasar:	ld r17,X+
		out SPDR,r17
Wait_Transmit_slave:
;espero q la transmision este completa
		in r16,SPSR
		sbrs r16,SPIF
		rjmp Wait_Transmit_slave
		dec r23
		brne pasar
		sbi PORTB,2;finalizo comunacion
		rjmp final
mostrar:ret
;Hasta es el codigo lo demas quedo porq si

