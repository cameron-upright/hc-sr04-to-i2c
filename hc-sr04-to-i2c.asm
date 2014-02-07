#include <p16f1936.inc>
	list p=16f1936 		; Set the processor
	__CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _MCLRE_OFF & _IESO_OFF & _FCMEN_OFF
	__CONFIG _CONFIG2, _BORV_25 & _LVP_OFF & _PLLEN_OFF

CBLOCK 0x20
	d1
	d2
	count
ENDC

; Program load
	ORG 	0x000
	GOTO 	Init


	
; Interrupt
	ORG	0x004

	BCF	INTCON, T0IF

	BSF	PORTB, 1
	BCF	PORTB, 1

	RETFIE


	
Init
	BANKSEL	PORTA
	CLRF	PORTA

	BANKSEL	PORTB
	CLRF	PORTB			; Set 0 to all pins

	BANKSEL	LATB
	CLRF	LATB

	BANKSEL	ANSELB
	CLRF	ANSELB
	
	BANKSEL	TRISA
	CLRF	TRISA			; All outputs

	BANKSEL	TRISB
	CLRF	TRISB			; All outputs

	
	BANKSEL	TMR0
	CLRF	TMR0

	BANKSEL	OPTION_REG
	MOVLW	b'11010111'
	MOVWF	OPTION_REG		; Timer0 timer mode, w/ 256x prescalar

	BANKSEL	INTCON
	MOVLW	b'10000000'		; Enable global interrupts
	MOVWF	INTCON



	


Main

	BANKSEL	PORTB
	BSF	PORTB, 0		; Set the trigger
	CALL	delay_10us		; Wait for 10us

	BANKSEL TMR0			; Setup timer0 to go off in approximately 39ms
	CLRF	TMR0
	MOVLW	d'03'
	MOVWF	count

	BANKSEL	INTCON			; Turn on interrupts for timer0
	BSF	TMR0IF


	BANKSEL	PORTB
	BCF	PORTB, 0		; Clear the trigger



	CALL	delay_60ms		; Wait 60ms

	GOTO	Main			; start again








delay_10us
			;46 cycles
	movlw	0x0F
	movwf	d1
delay_10us_0
	decfsz	d1, f
	goto	delay_10us_0

			;4 cycles (including call)
	return


	
; Delay = 0.06 seconds
; Clock frequency = 20 MHz

; Actual delay = 0.06 seconds = 300000 cycles
; Error = 0 %

delay_60ms
			;299993 cycles
	movlw	0x5E
	movwf	d1
	movlw	0xEB
	movwf	d2
delay_60ms_0
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	delay_60ms_0

			;3 cycles
	goto	$+1
	nop

			;4 cycles (including call)
	return


	END
