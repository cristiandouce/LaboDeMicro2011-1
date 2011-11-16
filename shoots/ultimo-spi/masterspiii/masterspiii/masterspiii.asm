

.include "inc/m88def.inc"
.equ	LCD_RS	= 1
.equ	LCD_RW	= 2
.equ	LCD_E	= 3

.def	tmp	=r16
.def	arg= r17		
.def	rtn	= r18		
.def    dta = r19
.def 	aux = r24
.def    lowX = r26
.def    highX = r27
.def dta=r20


 ;Defino las variables
 .dseg
 pixel:	.byte	6

 ;Defino el segmento de codigo
 .org 0
 .cseg
 rjmp reset

;Vector de interrupciones
.org 0x011;defino el vector d la interrupcion
 rjmp SPI_STC ; SPI Transfer Complete Handler


;Empiezo el programa principal
reset:
	ldi	tmp, low(RAMEND)
	out	SPL, tmp
	ldi	tmp, high(RAMEND)
	out	SPH, tmp
	ldi	lowX,low(pixel);x apunta a pixel
	ldi	highX,high(pixel)
 
 SPI_m_init:
 ;pongo sck,mosi y ~ss como salidas; miso como entrada
	ldi tmp,0b00101100
	out DDRB,tmp
;habilito spi, como master,frec d cloc es f/16
	ldi tmp,0b01110001
	out SPCR,tmp
;comienzo comunic spi como master
elijo_esclavo:
     cbi PORTB,2
SPI_MasterTransmit:
;empiezo la trasmision
   ldi arg,'m'
   out SPDR,arg
Wait_Transmit:
;espero q la transmision este completa
   in tmp,SPSR
   sbrs tmp,SPIF
   rjmp Wait_Transmit
;mando otro dta, esto podria mejorarse volviendolo una subrutina
;pero solo es para probar
   
SPI_MasterTransmit2:
   ;empiezo la trasmision del segundo dta
   ldi arg,'s';este es el comando para empezar a usar el sensor
   out SPDR,arg
Wait_Transmit2:
;espero q la transmision este completa
   in tmp,SPSR
   sbrs tmp,SPIF
   rjmp Wait_Transmit2
   ;termino el pasaje d dtas
   sbi PORTB,2;termino como master
   ; una vez q lo recibio se supone que se deshabilitaron las interrupciones
   ; entonces habilito las de aca, para que  me mande los pixels que los voy a guardar en una variable llamada
   ;pixels
   
   in tmp,SPDR;pongo spif en cero
   ;set MISO output, all others input
   ldi arg,0x10
   out DDRB,arg
   ; me converti en slave y habilite las interrupciones dl spi
   ldi tmp,0b11100001
   out SPCR,tmp
   sei;habilito las interrupciones
  
fin: rjmp fin


	


;Rutina que realiza la interrupcion

SPI_STC: ; SPI Transfer Complete Handler
        ldi aux,6;
rutina: in dta,SPDR;guardo el byte q me mando
		cpi dta,'l';este es el que dice que termine y lo muestro por el lcd
		breq lcd;aca inicio y mando al display, y me convierto en master dps d mostrar
        st X+,dta;guardo el dato en pixel, y aumento el puntero
        dec aux;
		brne rutina;
final:	reti
		
lcd:	rcall LCD_init
	    rcall	LCD_wait
		ldi aux,2
lcd_pas:ld dta,-X
	   ;write dta to the LCD char data RAM*/
	    rcall	LCD_putchar
    	rcall	LCD_wait
	    rcall LCD_delay
		dec aux
		brne lcd_pas
		cli;paro las interrupciones para q no lo haga mas
		
		rjmp final




 lcd_command8:	;used for init (we need some 8-bit commands to switch to 4-bit mode!)
	in	tmp, DDRD		;we need to set the high nibble of DDRD while leaving
					;the other bits untouched. Using tmp for that.
	sbr	tmp, 0b11110000	;set high nibble in tmp
	out	DDRD, tmp		;write value to DDRD again-> d7-d4 son salidas
	in	tmp, PortD		;then get the port value, aparentemente portd esta en cero x defecto
	cbr	tmp, 0b11110000	;borro the data bits 
	cbr	arg, 0b00001111	;then clear the low nibble of the arg
					;so that no control line bits are overwritten
	or	tmp, arg		;then set the data bits (from the arg) in the
					;Port value
	;/*en arg tengo el argo con el nibble d las variables d control en cero*/
	;/*en tmp tngo los valores dl puerto d, con la parte d dtas borrada*/
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
    push	dta;save the argmuent (it's destroyed in between)
	in	tmp, DDRD	;get data direction bits
	sbr	tmp, 0b11110000	;set the data lines to output
	out	DDRD, tmp		;write value to DDRD
	in	tmp, PortD		;then get the data from PortD
	cbr	tmp, 0b11111110	;clear ALL LCD lines (data and control!)
	cbr	dta, 0b00001111	;we have to write the high nibble of our arg first
					;so mask off the low nibble
	or	tmp, dta		;now set the arg bits in the Port value
	out	PortD, tmp		;and write the port value
	sbi	PortC, LCD_RS		;now take RS high for LCD char data register access
	sbi	PortD, LCD_E		;strobe Enable
	nop
	nop
	nop
	cbi	PortD, LCD_E
	pop	dta	;restore the arg, we need the low nibble now...
	cbr	tmp, 0b11110000	;clear the data bits of our port value
	swap	dta		;we want to write the LOW nibble of the arg to
					;the LCD data lines, which are the HIGH port nibble!
	cbr	dta, 0b00001111	;clear unused bits in arg
	or	tmp, dta		;and set the required arg bits in the port value
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
	pop	arg;saco el argo d la pila
	cbr	tmp, 0b11110000; hago una and con 0F, borro los dl nibble alto dejo los d control en cero
	swap	arg;intercambio el nibble alto con el bajo
	cbr	arg, 0b00001111;hago una and con F0,borro el nibble inferior d arg
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

LCD_getaddr:	;works just like LCD_getchar, but with RS low, rtn.7 is the busy flag
	in	tmp, DDRD
	andi tmp, 0b00001111;esto es al pedo
	out	DDRD, tmp
	cbi	PortC, LCD_RS;pongo en cero para decir q es instruccion
	sbi	PortD, LCD_RW; en uno para leer
	sbi	PortD, LCD_E; seteo enable
	nop
	in	tmp, PinD;guardo lo q estaba en el pin
	andi	tmp, 0b11110000;borro la parte d las variables d control
	mov	rtn, tmp;pongo en rtn ese valor
	cbi	PortD, LCD_E;pongo enable en cero
	nop
	nop;espero
	sbi	PortD, LCD_E;pongo enable en uno
	nop
	in	tmp, PinD; guardo lo q esta en el pin, q es nibble bajo d la direccion, en realidad no lo necesito
	andi	tmp, 0b11110000;borro la parte d las variables d control
	swap	tmp; pongo el nibble alto en el bajo
	or	rtn, tmp;hago un or con rtn,tngo la dire completa
	cbi	PortD, LCD_E;pongo enable en cero
	cbi	PortD, LCD_RW; pongo rw en cero
ret

LCD_wait:				;read address and busy flag until busy flag cleared
	rcall	LCD_getaddr
	andi	rtn, 0x80;hago un and con 10000000
	brne	LCD_wait;sale d aca solo cuando el busy flag es cero
	ret


LCD_delay:;/*este delay dura 197ms*/
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
	ldi		tmp, 0b00001100		;*las lineas de control son salidas y el resto entradas
	out		DDRD, tmp
	sbi		DDRC,1
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

 
 
 
 
 


