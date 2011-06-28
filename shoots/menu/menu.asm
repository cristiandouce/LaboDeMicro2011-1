.include "m88def.inc"

.;*Defino constantes
;-Operativos
	;Menu
	.equ	op1			=	0x00		;opcion1: lectura en menu principal; 'Si' en exportar y calibracion 2
	.equ	op2			=	0x01		;opcion2: calibracion en menu principal: 'No' en exportar y calibracion 2	
	.equ	op3			=	0x02		;opcion3: Lampara on en menu principal: 'Volver' en calibracion 2
	.equ	op4			=	0x03		;opcion4	calibracion1
	.equ	menu1		=	0b00000000	;Menu inicial
	.equ	menu2		=	0b01000000	;Menu exportar
	.equ	menu3		=	0b10000000	;Menu Calibracion 
	.equ	menu4		=	0b11000000	;Menu Medición
	.equ	maskOP		=	0b00000011	;para leer flags
	.equ	flagUP		=	2
	.equ	flagDW		=	3
	.equ	flagRT		=	4
	.equ	flagLmp		=	5
	.equ	maskMN		=	0b11000000
	;LCD
	.equ	fst			=	0x02 			;fin de string
	.equ	sline		=	0xC0
	.equ	lcdclear	=	0x01
	.equ	lcdhome		=	0x02

	;SPI
	.equ	Cmaster 	=	0b01110001
	.equ	Cslave 		=	0b11100000
	;USART

;-PuertoB(pin 0 ?;pines 1-5 SPI, pines 6 y 7 ?)
	.equ	pCSS	=	1
	.equ	pSS		=	2
	.equ	pMOSI	=	3
	.equ	pMISO	=	4
	.equ	pSCK	=	5


;-PuertoC(pin 0 lampara; pin 1 control LCD;pines 3-5 ?;pin 6 reset)
	.equ	lamp		= 0
	.equ	LCD_RS		= 1
	.equ	switchUP	= 2
	.equ	switchDW	= 3
	.equ	switchRT	= 4


;-PuertoD(pines 0y1 para usart;2y3contol LCD;4-7 Data LCD)
	.equ	LCD_RW	= 2
	.equ	LCD_E	= 3


;*Defino Strings
	.cseg
		.org 0x0300 
			strLec:		.db	"Lectura",fst			;opcion lectura
			strCal:		.db	"Calibracion",fst		;opcion calibracion
			strLmpOn:	.db	"Lamp.*On*-Off",fst		;Lampara on
			strLmpOff:	.db	"Lamp.On-*Off*",fst		;Lampara on
			strLmd:		.db	"Ingrese Lambda ",fst
			strCL:		.db	"Lambda:  ",fst	
			strSi:		.db	"Si ",fst
			strNo:		.db "No ",fst
			strBck:		.db	"Volver ",fst
			strBsy:		.db	"Leyendo",fst
			strExp:		.db	"Exportar a PC?"

;*Defino Variables
	.dseg
		string:	.byte	17


;*Defino simbolos
	.def	tmp		=	r16		;Registro para uso general
	.def	arg		=	r17		;Argumentos para pasar a funciones
	.def	opc		=	r18		;Opcion seleccionada
	.def	fla		=	r19		;Registro para flags:b(0-1):Opcion global.b2:switchUPon
								;b3:switchDWon ;b4:switchRTon; b5:on/off; b6-7 tipo de menu
	.def	lmd		=	r20		;digito de lambda
	.def	con		=	r21		;contador
	.def	rtn		=	r22		;valor de retorno de subrutinas
	.def	dta		=	r23		;valor de bayte recivido por SPI
	.def	key		=	r24		;guarda el valor de las teclas precionadas






;*Defino macros
	.MACRO	SPI_START;*	Elijo el SLAVE con ~SS (PortB,2) en LOW
		cbi PORTB, pSS
	.ENDMACRO
	.MACRO	SPI_STOP;*	Elijo el SLAVE con ~SS (PortB,2) en LOW
		sbi PORTB, pSS
	.ENDMACRO

	.MACRO	LoadstringX;*	Cargo string en X
		ldi		Xl,low(@0)
		ldi		Xh,high(@0)
	.ENDMACRO

	.MACRO	ubicar;*	Cargo string en X
		mov		tmp,fla
		cbr		tmp,@1
		sbr		tmp,@0
		mov		fla,tmp
	.ENDMACRO



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
		rcall startup
mainloop:
		mov		tmp,fla
		andi	tmp,maskMN
		cpi		tmp,menu1
		breq	main_menu
		cpi		tmp,menu2
		breq	export_menu
		cpi		tmp,menu3
		breq	calib_menu
		cpi		tmp,menu4
		breq	res_menu
	






;***********************************************************************
;*	Chequeo si se presiono alguna tecla y seteo el flag correspondiente
;***********************************************************************
check_keys:
		;leo el puerto C
		in		tmp,PINC
		;si está presionado un boton va a quedar en 0 ese bit
		sbrs	tmp,switchUP
		rjmp	keyUP
		sbrs	tmp,switchDW
		rjmp	keyDW
		sbrs	tmp,switchUP
		rjmp	keyRT
		;si no se presiono nada me vuelvo a fijar
		mov		key,tmp
		rjmp	check_keys
		
keyUP:
		;se presiono key UP si no estába presionada antes seteo el flag y voy al mainloop, si si vuelvo
		sbrc	key,switchUP
		rjmp	check_keys
		cbr		key,switchUP
		sbr		fla,flagUP
		rjmp	mainloop
keyDW:
		sbrc	key,switchDW
		rjmp	check_keys
		cbr		key,switchDW
		sbr		fla,flagDW
		rjmp	mainloop
keyRT:
		sbrc	key,switchRT
		rjmp	check_keys
		cbr		key,switchRT
		mov		key,tmp
		sbr		fla,flagRT
		rjmp	mainloop



;***********************************************************************
;*	Menu inicial(por defecto entra aqui)
;***********************************************************************
main_menu:
		mov		tmp,fla
		andi	tmp,maskOP
		cpi		tmp,op1
		breq	stepLec
		cpi		tmp,op2
		breq	stepCal
		cpi		tmp,op3
		breq	stepLmp
		rjmp	error

;**************************************************************************
;*	Menu Exportar
;**************************************************************************
export_menu:
		mov		tmp,fla
		andi	tmp,maskOP
		cpi		tmp,op1
		breq	stepExpSi
		cpi		tmp,op2
		breq	stepExpNo
		rjmp	error
;**************************************************************************
;*	Menu Calibrar
;**************************************************************************
calib_menu:
		mov		tmp,fla
		andi	tmp,maskOP
		cpi		tmp,op1
		breq	stepCal2Si
		cpi		tmp,op2
		breq	stepCal2No
		cpi		tmp,op3
		breq	stepCal2Back
		cpi		tmp,op4
		breq	stepCal1
		rjmp	error
;**************************************************************************
;*	Menu Mostrar resultados
;**************************************************************************
res_menu:


;**************************************************************************
;*	Acciones en menues
;**************************************************************************
stepExpSi:
		sbrc	fla,flagUP
		rjmp	display_ExpNo
		;si flagDW:paso de si a no
		sbrc	fla,flagDW
		rjmp	display_ExpNo
		;si flagRT; exporto
		sbrc	fla,flagRT
		rjmp	FN_export
		rjmp	error
stepExpNo:
		sbrc	fla,flagUP
		rjmp	display_ExpSi
		;si flagDW:display_Cal
		sbrc	fla,flagDW
		rjmp	display_ExpSi
		;si flagRT; FN_Lec
		sbrc	fla,flagRT
		rjmp	check_keys
		rjmp	error
stepLec:
		;si flagUP:nada
		sbrc	fla,flagUP
		rjmp	check_keys
		;si flagDW:display_Cal
		sbrc	fla,flagDW
		rjmp	display_Cal
		;si flagRT; FN_Lec
		sbrc	fla,flagRT
		rjmp	FN_Lec
		;si noflag:display_lec
		rjmp	display_Lec
stepCal2SI:
stepCal2No:
stepCal2Back:
stepCal:
		;si flagUP:display_lec
		sbrc	fla,flagUP
		rjmp	display_lec
		;si flagDW:display_Lmp
		sbrc	fla,flagDW
		rjmp	display_Lmp
		;si flagRT; FN_Cal
		sbrc	fla,flagRT
		rjmp	FN_Cal
		;si noflag:no deberia pasar
		rjmp	error
		
stepLmp:
		;si flagUP:display_Cal
		sbrc	fla,flagUP
		rjmp	display_Cal
		;si flagDW:nada
		sbrc	fla,flagDW
		rjmp	check_keys
		;si flagRT; FN_Lmp
		sbrc	fla,flagRT
		rjmp	FN_Lmp
		;si noflag:no deberia pasar
		rjmp	error

stepCal1:
		
		

;*Seleccionada Lectura
display_Lec:
		ubicar	op1,maskOP
		ldi		arg,lcdclear
		rcall	LCD_command		
		ldi		arg,lcdhome
		rcall	LCD_command
		;cargo primerlinea(seleccionada)
		ldi		arg,'-'
		rcall 	lcd_putchar
		LoadstringX strLec
		rcall	LCD_Putstring

		;Cargo segunda linea
		ldi		arg,sline
		rcall	LCD_command
		LoadstringX strCal
		rcall	LCD_Putstring
		rjmp	check_keys

display_Cal:
		ubicar	op2,maskOP
		ldi		arg,lcdclear
		rcall	LCD_command		
		ldi		arg,lcdhome
		rcall	LCD_command
		;cargo primerlinea(seleccionada)
		ldi		arg,'-'
		rcall 	lcd_putchar
		LoadstringX strCal
		rcall	LCD_Putstring

		;Cargo segunda linea
		ldi		arg,sline
		rcall	LCD_command
		sbrs	fla,flagLmp
		LoadstringX strLmpOff
		sbrc	fla,flagLmp
		LoadstringX strLmpOn
		rcall	LCD_Putstring
		rjmp	check_keys
display_Lmp:
		ubicar	op3,maskOP
		;vacio pantalla
		ldi		arg,lcdclear
		rcall	LCD_command		
		ldi		arg,lcdhome
		rcall	LCD_command
		;cargo primerlinea
		LoadstringX strCal
		rcall	LCD_Putstring

		;Cargo segunda linea(seleccionada)
		ldi		arg,'-'
		rcall 	lcd_putchar
		ldi		arg,sline
		rcall	LCD_command
		sbrs	fla,flagLmp
		LoadstringX strLmpOff
		sbrc	fla,flagLmp
		LoadstringX strLmpOn
		rcall	LCD_Putstring
		rjmp	check_keys
display_ExpNo:
		ubicar	op2,maskOP
		ldi		arg,lcdclear
		rcall	LCD_command		
		ldi		arg,lcdhome
		rcall	LCD_command
		;cargo primerlinea(seleccionada)
		LoadstringX strExp
		rcall	LCD_Putstring
		;Cargo segunda linea
		LoadstringX strSi
		rcall	LCD_Putstring
		ldi		arg,'/'
		rcall 	lcd_putchar
		ldi		arg,'*'
		rcall 	lcd_putchar		
		LoadstringX strNo
		rcall	LCD_Putstring
		ldi		arg,'*'
		rcall 	lcd_putchar
		rjmp	check_keys
display_ExpSi:
		ubicar	op1,maskOP
		ldi		arg,lcdclear
		rcall	LCD_command		
		ldi		arg,lcdhome
		rcall	LCD_command
		;cargo primerlinea(seleccionada)
		LoadstringX strExp
		rcall	LCD_Putstring
		;Cargo segunda linea
		ldi		arg,'*'
		rcall 	lcd_putchar
		LoadstringX strSi
		rcall	LCD_Putstring
		ldi		arg,'*'
		rcall 	lcd_putchar
		ldi		arg,'/'
		rcall 	lcd_putchar
		LoadstringX strNo
		rcall	LCD_Putstring
		rjmp	check_keys

;******************************************************************
;*	Funciones
;******************************************************************
FN_export:
FN_Lec:
FN_Cal:
FN_Lmp:
;******************************************************************
;*inicializo perifericos
;******************************************************************
startup:
		;*inicializo Flags
		;*	Habilito el LCD
		rcall	LCD_init
		;*	Espero la busy flag
	    rcall	LCD_wait
		;*Inicio el SPI como Master
		rcall 	SPI_Minit
		;*Inicio el USART
		rcall	USART_Init
		;seteo los switches como entrada con pull up on
		cbi		DDRC,switchUP
		cbi		DDRC,switchDW
		cbi		DDRC,switchRT
		sbi		PORTC,switchUP
		sbi		PORTC,switchDW
		sbi		PORTC,switchRT
		;seteo pin lampara como salida en 0
		sbi		DDRC,lamp
		cbi		PORTC,lamp
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
		cbi	DDRB,pCSS
		;*	Habilita comunicación SPI como MASTER a frecuencia
		;*	de clock de f/16
		ldi tmp, Cmaster
		out SPCR, tmp
		in tmp, SPSR
		in tmp, SPDR
		ret
;******************************************************************
;*	Enviar un String por SPI
;******************************************************************
SPI_Sendstring:								;!
		ldi	con,0x00						;!
ssloop:										;!
		ldi Zl,0x00							;!
		ldi	Zh,0x06							;!			
		add Zl,con							;!						
		lpm	rtn,Z							;!				
		out	spdr,rtn						;!		
		in	dta,spdr						;!HAY QUE ADAPTARLA			
		rcall SPI_Wait						;!						
		ldi	Yl,low(string)					;!						
		ldi	Yh,high(string)					;!						
		add	Yl,con							;!			
		st	Y,dta							;!			
		inc con								;!		
		cpi	rtn,fst							;!	
		brne ssloop							;!					
		ret									;!

;*****************************************************************
;*	Espera del fin de la recepción SPI
;*****************************************************************
SPI_Wait:
		;*	Espera del fin de la recepción
		in tmp, SPSR
		sbrs tmp, SPIF
		rjmp SPI_Wait
		ret


;****************************************************************
;*	Rutinas USART
;****************************************************************

USART_Init:
;seteto el baud rate
ldi Xh,0x00
ldi Xl,0x0C;
sts UBRR0H,Xh
sts UBRR0L,Xl
ldi tmp,0b00100010
sts UCSR0A,tmp
ldi tmp,0b00001000
sts UCSR0B,tmp
ldi tmp,0b00000110
sts UCSR0C,tmp
ret


USART_Transmit:
lds	 tmp,UCSR0A
sbrs tmp,UDRE0
rjmp USART_Transmit
sts UDR0,arg
ret


;*****************************************************************
;* 	Funciones para trabajar con Strings y el lcd
;*****************************************************************

LCD_Putstring:
		ld	arg,X
psloop:	
		push	arg
		rcall LCD_Putchar
		pop		arg
		adiw Xh:Xl,1
		ld	arg,X
		cpi	arg,fst
		brne psloop
		ret


;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;!		Rutinas viejas de LCD solo para simulaciones
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


;*****************************************************************
;*	Rutinas para trabajar con el LCD
;*****************************************************************


LCD_init:
		sbi	DDRC,LCD_RS
		sbi DDRD,LCD_RW
		sbi	DDRD,LCD_E

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


error:
