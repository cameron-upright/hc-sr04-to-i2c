#include <p16f1936.inc>
	list p=16f1936 		; Set the processor
	__CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _MCLRE_OFF & _IESO_OFF & _FCMEN_OFF
	__CONFIG _CONFIG2, _BORV_25 & _LVP_OFF & _PLLEN_OFF



        CBLOCK 0x70
        ; Delay routine variables
        d1
        d2

        ; PWM measurement CCP variables
        captureFalling
        risingTimeH
        risingTimeL
        fallingTimeH
        fallingTimeL
        diffH
        diffL
        lowBorrow
        timeout

        ENDC


CaptureRising	equ	b'00000101'
CaptureFalling	equ	b'00000100'










        ; Starting point
        ORG 0x000
        GOTO Init

        ; Interrupt
        ORG 0x004


        BTFSS   captureFalling, 0   ; Go to the rising or falling pahse code
        GOTO    RisingPulsePhase
        GOTO    FallingPulsePhase

RisingPulsePhase

    	MOVF	CCPR1H, W		;
    	MOVWF	risingTimeH		;
    	MOVF	CCPR1L, W		;
    	MOVWF	risingTimeL		; Capture the time of the rising pulse


        BANKSEL CCP3CON
        MOVLW   CaptureFalling
        MOVWF   CCP3CON             ; Switch to capture falling mode

        BSF     captureFalling, 0   ; Switch to falling pulse detection

        GOTO    EndInterrupt


FallingPulsePhase

    	MOVF	CCPR1H, W		;
    	MOVWF	fallingTimeH	;
    	MOVF	CCPR1L, W		;
    	MOVWF	fallingTimeL    ; Capture the time of the raise


    	;; Perform subtraction of [fallingTimeH|fallingTimeL] - [risingTimeH|risingTimeL]
    	CLRF	lowBorrow		; Clear out the variable that tracks if the low resulted in a carry
    	MOVF	risingTimeL, W
    	SUBWF	fallingTimeL, F		; fallingTimeL -= risingTimeL
    	BTFSS	STATUS, C		; !borrow
    	INCF	lowBorrow, F		; if (borrowed), increment low borrow (set to 1)
    	MOVF	risingTimeH, W
    	SUBWF	fallingTimeH, F		; fallingTimeH -= risingTimeH
    	MOVF	lowBorrow, W
    	SUBWF	fallingTimeH, F		; fallingTimeH -= lowBorrow

    	MOVF	fallingTimeH, W
    	MOVWF	diffH
    	MOVF	fallingTimeL, W
    	MOVWF	diffL



        BANKSEL PORTB
        BTFSS   timeout, 0
        BSF     PORTB, 1


        BANKSEL CCP3CON
        MOVLW   CaptureRising
        MOVWF   CCP3CON             ; Switch to rising pulse detection

        BCF     captureFalling, 0

        GOTO    EndInterrupt


EndInterrupt


        BANKSEL PIR3
        BCF     PIR3, CCP3IF    ; Clear the intterupt


        RETFIE


Init
        CALL InitPins
        CALL InitCCP

        BANKSEL PORTB


Loop

        CALL trigger_pulse
        CALL wait_for_and_record_pwm

        GOTO Loop





InitPins
    	BANKSEL	PORTB
        CLRF	PORTB			; Set 0 to all pins

    	BANKSEL	TRISB
        MOVLW   b'00100000'
        MOVWF   TRISB			; All outputs, except RB5 which is an input

        BANKSEL ANSELB
        CLRF    ANSELB

        BANKSEL APFCON
        BSF     APFCON, CCP3SEL ; Make sure CCP3 is on RB5

        RETURN


InitCCP
        BANKSEL T1CON
        MOVLW   b'00100001'
        MOVWF   T1CON           ; 1:4 prescale, instruction clock, timer1 on

        BANKSEL T1GCON
        CLRF    T1GCON          ; No gate stuff

        BANKSEL INTCON          ; Enable global and periferal interrupts
        MOVLW   b'11000000'
        MOVWF   INTCON



        RETURN


trigger_pulse

        BANKSEL PORTB
        BSF PORTB, 0            ; Send out a 10us trigger pulse

        CALL delay_10us

        BANKSEL PORTB
        BCF PORTB, 0            ; Stop the trigger pulse

        RETURN

wait_for_and_record_pwm


        ; Get ready to receive the pulse, switch to start capture rising
        ;  and reset the timeout
        CLRF    timeout         ; Initialize our timeout variable


        BCF     captureFalling, 0

        BANKSEL CCP3CON
        MOVLW   CaptureRising
        MOVWF   CCP3CON         ; Capture rising edges

        BANKSEL PIE3
        BSF     PIE3, CCP3IE    ; Enable CCP3 interrupt


        CALL delay_30ms         ; Wait for 30ms

        BSF     timeout, 0      ; It took too long, ignore any falling edge

        CALL delay_20ms         ; Finish the waiting until the next trigger


        BANKSEL PIE3
        BCF     PIE3, CCP3IE    ; Disable CCP3 interrupt


        BANKSEL PORTB
        BCF     PORTB, 1

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




delay_20ms
			;99993 cycles
	movlw	0x1E
	movwf	d1
	movlw	0x4F
	movwf	d2
delay_20ms_0
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	delay_20ms_0

			;3 cycles
	goto	$+1
	nop

			;4 cycles (including call)
	return



delay_30ms
			;149993 cycles
	movlw	0x2E
	movwf	d1
	movlw	0x76
	movwf	d2
delay_30ms_0
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	delay_30ms_0

			;3 cycles
	goto	$+1
	nop

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