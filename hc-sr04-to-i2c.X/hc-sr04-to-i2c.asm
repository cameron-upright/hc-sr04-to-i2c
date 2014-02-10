#include <p16f1936.inc>
	list p=16f1936 		; Set the processor
	__CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _MCLRE_OFF & _IESO_OFF & _FCMEN_OFF
	__CONFIG _CONFIG2, _BORV_25 & _LVP_OFF & _PLLEN_OFF


        ORG 0x00

    	BANKSEL	PORTB
        CLRF	PORTB			; Set 0 to all pins

    	BANKSEL	TRISB
        CLRF	TRISB			; All outputs

        BANKSEL PORTB

Loop
        BSF PORTB, 0
        NOP
        NOP
        NOP
        BCF PORTB, 0
        NOP
        GOTO Loop

        END