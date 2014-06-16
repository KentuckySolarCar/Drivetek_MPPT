;**********************************************************************
;   P R O G R A M M	MPPTnG                                        *
;                                                                     *
;   Traking program for MPPT new generation                           *
;**********************************************************************
;                                                                     *
;    Filename:	    pwm.asm                                           *
;    Date:          15.11.00                                          *
;    Last Update:   03.01.03                                          *
;    File Version:  V3.0                                              *
;                                                                     *
;    Author:        M. Zuercher				              *
;                                                                     *
;    Company:       HTA-Biel/Bienne Indulab                           *
;                                                                     *
;    Changes:       added PWM interrupt to start ADC                  *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;    - Main program : mpptng.asm                                      *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Config:                                                          *
;                                                                     *
;    PWM1 -> CCP1 (pin 36) -> Aux pulse (Sa')                         *
;            Duty cycle : 016h (0000010110b)                          *
;                                                                     *
;    PWM2 -> CCP2 (pin 35) -> Duty cycle (Sm')                        *
;            Duty cycle : 190h (0110010000b)                          *
;                                                                     *
;**********************************************************************


;**********************************************************************
;		INIT PWM MODULES
;**********************************************************************

InitPWM		BANK1
		movlw	PERIODE			; set PWMs period
		movwf	PR2
		BANK0

		movlw	AUX_PW			; PWM1 duty cycle (Sa')
		movwf	CCPR1L
		bsf		CCP1CON,5 		; These are the 2 LSBs of the PWM duty cycle
		bcf		CCP1CON,4

		movlw	INITDUTY		; PWM2 duty cycle (Sm')
		movwf	DUTY2_H			; init duty variable
		movwf	CCPR2L

		bsf 	TRISC,1
		bsf		TRISC,2

		movlw	B'11110100'		; Timer2 on / prescaler is 1 / postscaler is 16
		movwf	T2CON

		BANK1
		bcf		PIE1_P,TMR2IE	; Timer 2 to PR2 match  interrupt disable
		BANK0

		call 	PWMoff

		RETURN

;**********************************************************************
;		Turn PWMs on, HS-FET remains off
;**********************************************************************
PWMon		nop
		bsf	CCP1CON,3	; set PWM1 mode
		bsf	CCP1CON,2
		bsf	CCP2CON,3	; set PWM2 mode
		bsf	CCP2CON,2

		bcf	ENA_FET
		
		RETURN

;**********************************************************************
;		Turn PWMs and HS-FET off
;**********************************************************************
PWMoff		nop
		nop
		bcf	CCP1CON,3	; set PWM1 mode
		bcf	CCP1CON,2
		bcf	CCP2CON,3	; set PWM2 mode
		bcf	CCP2CON,2

		bcf	PORTC,2		; turn off AUX_PUL
		bcf	PORTC,1		; turn off Duty Cycle

		bsf	ENA_FET
		
		RETURN

;**********************************************************************
;		Load duty cycle of PWM2 
;
;		IN: DUTY2_H, DUTY2_L (xxxxxxxx xx000000)
;**********************************************************************

LoadDuty	movf	DUTY2_H,W
		movwf	CCPR2L		; write H-Bite of Duty

		rrf	DUTY2_L,F	; rotate the 2 L-Bits by 2
		rrf	DUTY2_L,W
		rlf	DUTY2_L,F	; restore DUTY2_L
		
		andlw	B'00110000'	; clear all bits except Bit4 and 5

		bcf	CCP2CON,4
		bcf	CCP2CON,5

		iorwf	CCP2CON,F	; write L-Bits of Duty

EndLoad		RETURN


;**********************************************************************
;		Increment / Decrement duty cycle of PWM2
;
;		IN: DUTY2_H, DUTY2_L (xxxxxxxx xx000000)
;**********************************************************************

IncDuty		BANK1
		movf	STEP_L,w
		BANK0
		addwf	DUTY2_L,W
		andlw	B'11000000'	; mask L-Byte
		movwf	DUTY2_L
		btfsc	_C
		  incf	DUTY2_H,F	; skip if flag C (carry) = 0 
		BANK1
		movf	STEP_H,w
		BANK0
		addwf	DUTY2_H,F	; DUTY2_H:DUTY2_L = DUTY2_H:DUTY2_L + STEP_H:STEP_L

		call    LoadDuty

		RETURN

;----------------------------------------------------------------------

DecDuty		BANK1
		movf	STEP_L,w
		BANK0
		subwf	DUTY2_L,W

		andlw	B'11000000'	; mask L-Byte
		movwf	DUTY2_L

		btfss	_C
		  decf	DUTY2_H,F	; skip if flag C (borrow) = 1
		BANK1
		movf	STEP_H,w
		BANK0
		subwf	DUTY2_H,F	; DUTY2_H:DUTY2_L = DUTY2_H:DUTY2_L - STEP_H:STEP_L

		; lower limitat of duty
		jmpFgtL DUTY2_H,DUTY2_MIN_H,WhitinLimit		; don't limit, if greater
		jmpFltL DUTY2_H,DUTY2_MIN_H,LimitIt		; limit, if lower
		jmpFgeL DUTY2_L,DUTY2_MIN_L,WhitinLimit		; consider L-Bytes

LimitIt		movlw	DUTY2_MIN_H
		movwf	DUTY2_H
		movlw	DUTY2_MIN_L
		andlw	B'11000000'	; mask L-Byte
		movwf	DUTY2_L		; duty = duty_max

WhitinLimit	call 	LoadDuty

		RETURN

