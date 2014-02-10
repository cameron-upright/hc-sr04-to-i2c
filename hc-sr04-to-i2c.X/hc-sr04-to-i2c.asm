#include <p16f1936.inc>
	list p=16f1936 		; Set the processor
	__CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _MCLRE_OFF & _IESO_OFF & _FCMEN_OFF
	__CONFIG _CONFIG2, _BORV_25 & _LVP_OFF & _PLLEN_OFF



        CBLOCK 0x20
        d1
        d2
        ENDC


        ORG 0x00

    	BANKSEL	PORTB
        CLRF	PORTB			; Set 0 to all pins

    	BANKSEL	TRISB
        CLRF	TRISB			; All outputs

        BANKSEL PORTB

Loop
        ; Send out a 10us trigger pulse
        BSF PORTB, 0
        CALL delay_10us
        BCF PORTB, 0

        ; Wait for 50ms to start again
        CALL delay_50ms
        GOTO Loop






delay_10us
		;46 cycles
        movlw	0x0F
        movwf	d1
delay_10us_0
        decfsz	d1, f
        goto	delay_10us_0

        ;4 cycles (including call)
        return



delay_50ms
        ;249993 cycles
        movlw	0x4E
        movwf	d1
        movlw	0xC4
        movwf	d2
delay_50ms_0
        decfsz	d1, f
        goto	$+2
        decfsz	d2, f
        goto	delay_50ms_0

        ;3 cycles
        goto	$+1
        nop

        ;4 cycles (including call)
        return







        END