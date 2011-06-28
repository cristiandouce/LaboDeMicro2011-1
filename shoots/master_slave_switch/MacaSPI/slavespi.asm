/*
 * slavespi.asm
 *
 *  Created: 27/06/2011 17:50:37
 *   Author: Maca?
 */ 

 .include "m88def.inc"
.equ	LCD_RS	= 1
.equ	LCD_RW	= 2
.equ	LCD_E	= 3

.def	temp	= r16
.def	argument= r17		;argument for calling subroutines
.def	return	= r18		;return value from subroutines
.def    dato = r19;el q le da el master
/******************************************************************************/
;Defino las variables
 .dseg
 var:	.byte	6
 /*******************************************************************************/
 ;Defino el segmento de codigo
.org 0
.cseg
		rjmp main
/********************************************************************************/
;Vector de interrupciones
.org 0x011;defino el vector d la interrupcion
		rjmp SPI_STC ; SPI Transfer Complete Handler
/*********************************************************************************/
;Programa principal
main:	ldi	temp, low(RAMEND)
	    out	SPL, temp
	    ldi	temp, high(RAMEND)
	    out	SPH, temp
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
	    sei
fin:    rjmp fin;espero hasta q el master me mande el msj
/*********************************************************************************************/
;Rutina que realiza la interrupcion
SPI_STC:
        in dato,SPDR;guardo el byte q me mando
		st X+,dato;Lo guardo tb en var
		cpi dato,'s';me fijo si fue la orden 's'
		breq desactivar;y voy a hacer la rutina dl sensor
		cpi dato,'p';me fijo si es p
		breq mostrar;hago otra cosa x el momento no es nada,pero podria ser prender la lampara
	    reti
desactivar: 
	;pongo sck,mosi y ~ss como salidas; miso como entrada
		ldi r16,0b00101100
		out DDRB,r16
		;desactivo las interrupcionesy me convierto en master
		ldi r17,0b01110001
	    out SPCR,r17
		;rcall sensor,esto seria idealmente
			
		in r16,SPSR;leo esto para que se borre el flag spif
		in dato,SPDR;esto tb es para q se borre hay q hacer las dos cosas
elijo_esclavo:
        cbi PORTB,2
		ldi r17,'y'
		out SPDR,r17
Wait_Transmit_slave:
;espero q la transmision este completa
		in r16,SPSR
		sbrs r16,SPIF
		rjmp Wait_Transmit_slave
		ret
mostrar:ret
;Hasta es el codigo lo demas quedo porq si
////////////////////////////////////////////////////////////////////////////////////////////
		
		
	   ;write dato to the LCD char data RAM
	    
	    /*rcall	LCD_putchar
    	rcall	LCD_wait
	    rcall LCD_delay*/
		
		ret
lcd_command8:	;used for init (we need some 8-bit commands to switch to 4-bit mode!)
	in	temp, DDRD		;we need to set the high nibble of DDRD while leaving
					;the other bits untouched. Using temp for that.
	sbr	temp, 0b11110000	;set high nibble in temp
	out	DDRD, temp		;write value to DDRD again-> d7-d4 son salidas
	in	temp, PortD		;then get the port value, aparentemente portd esta en cero x defecto
	cbr	temp, 0b11110000	;borro the data bits 
	cbr	argument, 0b00001111	;then clear the low nibble of the argument
					;so that no control line bits are overwritten
	or	temp, argument		;then set the data bits (from the argument) in the
					;Port value
	/*en argument tengo el argumento con el nibble d las variables d control en cero*/
	/*en temp tngo los valores dl puerto d, con la parte d datos borrada*/
	out	PortD, temp		;and write the port value.
	sbi	PortD, LCD_E		;now strobe E
	nop
	nop
	nop
	cbi	PortD, LCD_E
	in	temp, DDRD		;get DDRD to make the data lines input again
	cbr	temp, 0b11110000	;clear data line direction bits
	out	DDRD, temp		;and write to DDRD
ret

lcd_putchar:
	push	dato;save the argmuent (it's destroyed in between)
	in	temp, DDRD	;get data direction bits
	sbr	temp, 0b11110000	;set the data lines to output
	out	DDRD, temp		;write value to DDRD
	in	temp, PortD		;then get the data from PortD
	cbr	temp, 0b11111110	;clear ALL LCD lines (data and control!)
	cbr	dato, 0b00001111	;we have to write the high nibble of our argument first
					;so mask off the low nibble
	or	temp, dato		;now set the argument bits in the Port value
	out	PortD, temp		;and write the port value
	sbi	PortD, LCD_RS		;now take RS high for LCD char data register access
	sbi	PortD, LCD_E		;strobe Enable
	nop
	nop
	nop
	cbi	PortD, LCD_E
	pop	dato	;restore the argument, we need the low nibble now...
	cbr	temp, 0b11110000	;clear the data bits of our port value
	swap	dato		;we want to write the LOW nibble of the argument to
					;the LCD data lines, which are the HIGH port nibble!
	cbr	dato, 0b00001111	;clear unused bits in argument
	or	temp, dato		;and set the required argument bits in the port value
	out	PortD, temp		;write data to port
	sbi	PortD, LCD_RS		;again, set RS
	sbi	PortD, LCD_E		;strobe Enable
	nop
	nop
	nop
	cbi	PortD, LCD_E
	cbi	PortD, LCD_RS
	in	temp, DDRD
	cbr	temp, 0b11110000	;data lines are input again
	out	DDRD, temp
ret

lcd_command:	;same as LCD_putchar, but with RS low!
	push	argument;guardo la instruccion
	in	temp, DDRD;copio en tmp 00001110
	sbr	temp, 0b11110000; hago un or, entonces pongo en 1 el nibble alto
	out	DDRD, temp;pongo este valor en DDRD x lo tanto d7-d4 son salidas
	in	temp, PortD;guardo el valor dl puerto
	cbr	temp, 0b11111110;hago una and con 01,borro todos los bits
	cbr	argument, 0b00001111;hago una and con F0, borro los 4 bits d control
	or	temp, argument;hago una or me quedan los 4 bits altos d la instruccion y cero debajo
	out	PortD, temp; lo cargo en el puerto
	sbi	PortD, LCD_E
	nop
	nop
	nop
	cbi	PortD, LCD_E
	pop	argument;saco el argumento d la pila
	cbr	temp, 0b11110000; hago una and con 0F, borro los dl nibble alto dejo los d control en cero
	swap	argument;intercambio el nibble alto con el bajo
	cbr	argument, 0b00001111;hago una and con F0,borro el nibble inferior d argument
	or	temp, argument;hago or con tmp
	out	PortD, temp;cargo en el puerto 
	sbi	PortD, LCD_E
	nop
	nop
	nop
	cbi	PortD, LCD_E
	in	temp, DDRD
	cbr	temp, 0b11110000; vuelvo a poner el nibble alto en cero para q sea entrada.
	out	DDRD, temp
ret

LCD_getaddr:	;works just like LCD_getchar, but with RS low, return.7 is the busy flag
	in	temp, DDRD
	andi temp, 0b00001111;esto es al pedo
	out	DDRD, temp
	cbi	PortD, LCD_RS;pongo en cero para decir q es instruccion
	sbi	PortD, LCD_RW; en uno para leer
	sbi	PortD, LCD_E; seteo enable
	nop
	in	temp, PinD;guardo lo q estaba en el pin
	andi	temp, 0b11110000;borro la parte d las variables d control
	mov	return, temp;pongo en return ese valor
	cbi	PortD, LCD_E;pongo enable en cero
	nop
	nop;espero
	sbi	PortD, LCD_E;pongo enable en uno
	nop
	in	temp, PinD; guardo lo q esta en el pin, q es nibble bajo d la direccion, en realidad no lo necesito
	andi	temp, 0b11110000;borro la parte d las variables d control
	swap	temp; pongo el nibble alto en el bajo
	or	return, temp;hago un or con return,tngo la dire completa
	cbi	PortD, LCD_E;pongo enable en cero
	cbi	PortD, LCD_RW; pongo rw en cero
ret

LCD_wait:				;read address and busy flag until busy flag cleared
	rcall	LCD_getaddr
	andi	return, 0x80;hago un and con 10000000
	brne	LCD_wait;sale d aca solo cuando el busy flag es cero
	ret
LCD_delay1:
    clr	r3;pongo r3 en cero
LCD_delay_inne:
	dec	r3;decremento r3
	brne	LCD_delay_inne; sale del ciclo si r3 es igual a cero
	ret

LCD_delay:/*este delay dura 197ms*/
	clr	r2;pongo r2 en cero
LCD_delay_outer:
	clr	r3;pongo r3 en cero
LCD_delay_inner:
	dec	r3;decremento r3
	brne	LCD_delay_inner; sale del ciclo si r3 es igual a cero
	dec	r2;cuando ya hizo 255us decremento r2
	brne	LCD_delay_outer;sale dl ciclo si r2 es igual a cero
    ret

LCD_init:
	
	ldi	temp, 0b00001110; cargo ese valor en el registro temporal
	out	DDRD, temp; lo pongo en DDRD,con eso las lineas d control son salidas, y el resto entradas
	rcall	LCD_delay;hago un delay d 197ms 
	ldi	argument, 0x20; configuro en modo 4 bits
	rcall	LCD_command8;LCD is still in 8-BIT MODE while writing this command!!!
	rcall	LCD_wait
	ldi	argument, 0x28		;NOW: 2 lines, 5*7 font, 4-BIT MODE!
	rcall	LCD_command		;
	rcall	LCD_wait
	ldi	argument, 0x0F		;now proceed as usual: Display on, cursor on, blinking
	rcall	LCD_command
	rcall	LCD_wait
	ldi	argument, 0x01		;clear display, cursor -> home
	rcall	LCD_command
	rcall	LCD_wait
	ldi	argument, 0x06		;auto-inc cursor
	rcall	LCD_command
ret