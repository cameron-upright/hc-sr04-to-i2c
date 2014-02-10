#include <p16f1936.inc>
	list p=16f1936 		; Set the processor
	__CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _MCLRE_OFF & _IESO_OFF & _FCMEN_OFF
	__CONFIG _CONFIG2, _BORV_25 & _LVP_OFF & _PLLEN_OFF



        CBLOCK 0x70
        ; Delay routine variables
        d1
        d2

        ; PWM measurement CCP variables
        captureRising
        risingTimeH
        risingTimeL
        fallingTimeH
        fallingTimeL

        ENDC


CaptureRising	equ	b'00000101'
CaptureFalling	equ	b'00000100'



        ; Starting point
        ORG 0x000
        GOTO Init

        ; Interrupt
        ORG 0x004

        BANKSEL PIR3
        BCF     PIR3, CCP3IF    ; Clear the intterupt

        RETFIE


Init

InitPins
    	BANKSEL	PORTB
        CLRF	PORTB			; Set 0 to all pins

    	BANKSEL	TRISB
        MOVLW   b'00100000'
        MOVWF   TRISB			; All outputs, except RB5 which is an input

        BANKSEL APFCON
        BSF     APFCON, CCP3SEL ; Make sure CCP3 is on RB5


InitCCP
        BANKSEL T1CON
        MOVLW   b'00000001'
        MOVWF   T1CON           ; 1:1 prescale, instruction clock, timer1 on

        BANKSEL T1GCON
        CLRF    T1GCON          ; No gate stuff

        BANKSEL INTCON          ; Enable global and periferal interrupts
        MOVLW   b'11000000'
        MOVWF   INTCON




Loop

        CALL trigger_pulse

        CALL wait_for_and_record_pwm

        GOTO Loop



trigger_pulse

        BANKSEL PORTB
        BSF PORTB, 0            ; Send out a 10us trigger pulse

        CALL delay_10us

        BANKSEL PORTB
        BCF PORTB, 0            ; Stop the trigger pulse

        RETURN

wait_for_and_record_pwm
        BANKSEL CCP3CON
        MOVLW   CaptureRising
        MOVWF   CCP3CON         ; Capture rising edges

        BANKSEL PIE3
        BSF     PIE3, CCP3IE    ; Enable CCP3 Interrupt

        CALL delay_50ms         ; Wait for 50ms to start again

        BANKSEL PIE3
        BCF     PIE3, CCP3IE    ; Disable CCP3 interrupt

        RETURN




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