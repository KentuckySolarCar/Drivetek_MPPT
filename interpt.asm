;**********************************************************************
;   P R O G R A M M	MPPTnG                                        *
;                                                                     *
;   Traking program for MPPT new generation                           *
;**********************************************************************
;                                                                     *
;    Filename:	    interpt.asm                                       *
;    Date:          30.04.01                                          *
;    Last Update:   30.04.01                                          *
;    File Version:  V3.0                                              *
;                                                                     *
;    Author:        Vezzini A. / M. Lehmann / F. Kaufmann             *
;                                                                     *
;    Company:       HTA-Biel/Bienne Indulab                           *
;                                                                     *
;    Changes:       Introduced separate Interrupt routine with V3.0   *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;    - Main program : mpptng.asm                                      *
;                                                                     *
;**********************************************************************

		ORG	0x04		; interrupt vector

;**********************************************************************
;		INTERRUPT Vector
;
;		Global int bit, GIE, has been reset.
;		W saved in IntSaveW0 or IntSaveW1 depending on the
;		bank selected at the time the interrupt occured.
;		Preserve Status bits (since movf sets Z) is with a 
;		swapf command
;**********************************************************************


		movwf	IntSaveW	; save W
		swapf	STATUS,W        ; Status to W with nibbles swapped
		BANK0
		movwf	IntSaveSt
		movfw	FSR
		movwf	IntSaveFSR	; save FSR
		movf	PCLATH,W 
		movwf	IntSavePCLATH	; interrupt storage for PCLATH
		clrf	PCLATH		; set to page 0

		; --> Must determine source of interrupt

		;SPI Interrupt
		btfsc	PIR1,SSPIF	; test interrupt
		   goto	  IntSPI
		
		;CAN Interrupt
		btfsc	INTCON,INTF	; test interrupt
		   goto	  IntCAN

		;A/D-Converter Interrupt
;		btfsc	PIR1,TMR2IF	; test interrupt
;		   goto	  IntADC

		;all external HW-Interrupts
		btfsc	INTCON,RBIF	; test interrupt
		   goto	  ExtInt
		
		goto	IntReturn

ExtInt		btfsc	INT_UNDV
		   goto	   Main			; RESET /Stack has not to be decremented, due to circular stack architecture!
		btfsc	INT_NOC
		   goto    NCInterupt	; No Load Interrupt

		; restore registers and return

IntReturn	BANK0
		movf	IntSavePCLATH,W	; restore PCLATH
		movwf	PCLATH
		movf	IntSaveFSR,W	; restore FSR
		movwf	FSR
		swapf	IntSaveSt,W	; restore STATUS
		movwf	STATUS
		swapf	IntSaveW,F	; swap original W in place
		swapf	IntSaveW,W
		RETFIE


