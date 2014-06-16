;**********************************************************************
;   P R O G R A M M	MPPTnG                                            *
;                                                                     *
;   Traking program for MPPT new generation                           *
;**********************************************************************
;                                                                     *
;    Filename:	     adc.asm                                          *
;    Date:          15.11.00                                          *
;    Last Update:   19.09.02                                          *
;    File Version:  V4.0                                              *
;                                                                     *
;    Author:        Michael Zürcher, Christoph Raible			      *
;                                                                     *
;    Company:       HTA-Biel/Bienne Indulab, drivetek ag              *
;                                                                     *
;    Changes:       Content routines for A/D Converter                *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;                                                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Ports config:                                                    *
;                                                                     *
;    an7 an6 an5 an4 an3 an2 an1 an0                                  *
;     -   A   -   A  ref  A   A   A                                   *
;                                                                     *
;    A/D result justification right                                   *
;                                                                     *
;**********************************************************************

;**********************************************************************
;		ADC synchronize routine Loop
;
;		IN: w register = w * 1us
;		temporary register = time
;**********************************************************************
waitforedge	MACRO	
		
		btfss	PORTC,1		; Trigger on negative edge to eliminate
		  goto $-1		    ; the influece of the current commutation 
					        ; in the converter module
		btfsc	PORTC,1
		  goto $-1

		ENDM

;**********************************************************************
;		WAIT Loop
;
;		IN: w register = w * 1us
;		temporary register = time
;**********************************************************************

wait		movwf	COUNTERA
w5		nop
		nop
		nop
		decfsz  COUNTERA,1
		  goto    w5
		nop
		RETURN

waittoboost
		movlw	0xff
		movwf	COUNTERA
		movfw	Waitboost
		Movwf	COUNTERB

wb		
		decfsz  COUNTERA,1
		  goto   wb
		movlw	0x4f
		movwf	COUNTERA		
		decfsz  COUNTERB,1
		  goto   wb
	    nop
		RETURN

wait20ms	movlw	0x04E
		movwf	COUNTERB
		movwf	COUNTERA

w4		nop
		btfsc	CANTxRq		; Test if CAn interrupt has occured during the waiting time
		   call    CANRqTest
		nop
		decfsz  COUNTERA,1
		  goto   w4
		decfsz  COUNTERB,1
		  goto   w4
		nop
		RETURN

wait1s		movlw	0x0F
		movwf	COUNTERC
		movlw	0x5A
		movwf	COUNTERB
		movwf   COUNTERA
	
w2		nop
		btfsc	CANTxRq		; Test if CAn interrupt has occured during the waiting time
		   call    CANRqTest
		nop
		decfsz COUNTERA,1
		  goto   w2
		decfsz  COUNTERB,1
		  goto   w2
		clrwdt			; reset watchdog
		decfsz  COUNTERC,1
		  goto   w2
		nop
		RETURN

;**********************************************************************
;		INIT A/D Converter
;**********************************************************************

InitADC		clrf	UI0H
		clrf	UI0L
		clrf	UO0H
		clrf	UO0L

		clrf	II0H
		clrf	II0L
	
		clrf	TAMBH
		clrf	TAMBL
		clrf	USENSEH
		clrf	USENSEL
		clrf	TCH
		clrf	TCL
		clrf	PI0H
		clrf	PI0M
		clrf	PI0L
		clrf	PI1H
		clrf	PI1M
		clrf	PI1L

		BANK1
		clrf	VSF		; Clear all voltage signum Flags
		clrf	PSF		; Clear all power signum Flags
		BANK0

		clrf	ADCON0
		bsf	ADCON0,7	; Tad = 32 * Tosc = 1.6us

		BANK1
		movlw	INIT_IO_AD	; init analog pins
		movwf	ADCON1
		BANK0

		RETURN


;**********************************************************************
;		Get the value of ADChannel 0 (Umes_in)
;
;		ADRESH,ADRESL - Result register (000000xx xxxxxxxx)
;		OUT: UI0H,UI0L
;**********************************************************************
GetUin		movlw	CHANNEL0	; select channel 0, clock=Fosc/32
		movwf	ADCON0

		btfss	CCP2CON,3	; Test if PWM is running
		  goto UnsyncUin
		
		waitforedge
		
UnsyncUin	bsf	ADCON0,0	; AD turn on
		movlw	Tacq
		call	wait		; wait Tacq in us

		bsf	ADCON0,GO	; start conversion
WaitADC0C	btfsc	ADCON0,GO
		  goto WaitADC0C	; wait until conversion finished
		
		movf	UI2H,W
		movwf	UI3H
		movf	UI1H,W
		movwf	UI2H
		movf	UI0H,W
		movwf	UI1H		; shift former H-values by 1 place

		movf	ADRESH,W
		movwf	UI0H		; store high value

		movf	UI2L,W
		movwf	UI3L
		movf	UI1L,W
		movwf	UI2L
		movf	UI0L,W
		movwf	UI1L		; shift former L-values

		BANK1
		movf	ADRESL,W
		BANK0
		movwf	UI0L		; store low value
		bcf	ADCON0,0	; AD shutoff
		RETURN


;**********************************************************************
;		Get the value of ADChannel 1 (Umes_out)
;
;		ADRESH,ADRESL - Result register (000000xx xxxxxxxx)
;		OUT: UO0H,UO0L
;**********************************************************************
GetUout		movlw	CHANNEL1	; select channel 1, clock=Fosc/32
		movwf	ADCON0

		btfss	CCP2CON,3	; Test if PWM is running
		  goto UnsyncUout		

		waitforedge

UnsyncUout	bsf	ADCON0,0	; AD turn on
		movlw	Tacq
		call	wait		; wait Tacq in us

		bsf	ADCON0,GO	; start conversion
WaitADC1C	btfsc	ADCON0,GO
		  goto WaitADC1C	; wait until conversion ha been finished

		movf	UO2H,W
		movwf	UO3H
		movf	UO1H,W
		movwf	UO2H
		movf	UO0H,W
		movwf	UO1H		; shift former H-values
		
		movf	ADRESH,W
		movwf	UO0H		; store new high value

		movf	UO2L,W
		movwf	UO3L
		movf	UO1L,W
		movwf	UO2L
		movf	UO0L,W
		movwf	UO1L		; shift former L-values

		BANK1
		movf	ADRESL,W
		BANK0
		movwf	UO0L		; store low value
		bcf	ADCON0,0		; AD shutoff
		RETURN


;**********************************************************************
;		Get the value of ADChannel 2 (Imes_in)
;
;		ADRESH,ADRESL - Result register (000000xx xxxxxxxx)
;		OUT: II0H,II0L
;**********************************************************************
GetIin		movlw	CHANNEL2	; select channel 2, clock=Fosc/32
		movwf	ADCON0

		btfss	CCP2CON,3	; Test if PWM is running
		  goto UnsyncIin

		waitforedge

UnsyncIin	bsf	ADCON0,0	; AD turn on
		movlw	Tacq
		call	wait		; wait Tacq in us

		bsf	ADCON0,GO	; start conversion
WaitADC2C	btfsc	ADCON0,GO
		  goto WaitADC2C	; wait until conversion has been finished

		movf	II2H,W
		movwf	II3H
		movf	II1H,W
		movwf	II2H
		movf	II0H,W
		movwf	II1H		; shift former H-values

		movf	ADRESH,W
		movwf	II0H		; store new high value

		movf	II2L,W
		movwf	II3L
		movf	II1L,W
		movwf	II2L
		movf	II0L,W
		movwf	II1L		; shift former L-values

		BANK1
		movf	ADRESL,W
		BANK0

		movwf	II0L		; store L-Value
		bcf	ADCON0,0	; AD shutoff

		return


;**********************************************************************
;		Get the value of ADChannel 4 (Tamb)
;
;		ADRESH,ADRESL - Result register (000000xx xxxxxxxx)
;		OUT: Tamb_H,Tamb_L
;**********************************************************************
GetTamb		movlw	CHANNEL4	; select channel 4, clock=Fosc/32
		movwf	ADCON0

		btfss   CCP2CON,3	; Test if PWM is running
		  goto  UnsyncTamb
	
		waitforedge
			
UnsyncTamb	bsf	ADCON0,0	; AD turn on
		movlw	Tacq
		call	wait		; wait Tacq

		bsf	ADCON0,GO	; start conversion
WaitADC4C	btfsc	ADCON0,GO	; wait until conversion has been finished
		  goto WaitADC4C

		movf	ADRESH,W
		movwf	TAMBH		; store high value
		BANK1
		movf	ADRESL,W
		BANK0
		movwf	TAMBL		; store low value
		bcf	ADCON0,0	; AD shutoff
		RETURN

;**********************************************************************
;		Get the value of ADChannel 5 (Usense)
;
;		ADRESH,ADRESL - Result register (000000xx xxxxxxxx)
;		OUT: Usense_H,Usense_L
;**********************************************************************
;GetUsense	movlw	CHANNEL5	; select channel 5, clock=Fosc/32
;		movwf	ADCON0

;		btfss	CCP2CON,3	; test is PWM is running
;		  goto  UnsyncUsense
		
;		waitforedge
	
;UnsyncUsense	bsf	ADCON0,0	; AD turn on
;		movlw	Tacq
;		call	wait		; wait Tacq

;		bsf	ADCON0,GO	; start conversion
;WaitADC5C	btfsc	ADCON0,GO	; wait until conversion has been finished
;		  goto WaitADC5C

;		movf	ADRESH,W
;		movwf	USENSEH		; store high value
;		BANK1
;		movf	ADRESL,W
;		BANK0
;		movwf	USENSEL		; store low value
;		bcf	ADCON0,0	; AD shutoff
;		RETURN

;**********************************************************************
;		Get the value of ADChannel 6 (Tcooler)
;
;		ADRESH,ADRESL - Result register (000000xx xxxxxxxx)
;		OUT: Tcooler_H,Tcooler_L
;**********************************************************************
GetTCooler	movlw	CHANNEL6	; select channel 6, clock=Fosc/32
		movwf	ADCON0

		btfss	CCP2CON,3	; Test if PWM is running
		  goto  UnsyncTcooler
	
		waitforedge

UnsyncTcooler	bsf	ADCON0,0	; AD turn on
		movlw	Tacq
		call	wait		; wait Tacq

		bsf	ADCON0,GO	; start conversion
WaitADC6C	btfsc	ADCON0,GO	; wait until conversion has been finished
		  goto WaitADC6C

		movf	ADRESH,W
		movwf	TCH	; store high value
		BANK1
		movf	ADRESL,W
		BANK0
		movwf	TCL	; store low value
		bcf	ADCON0,0	; AD shutoff
		RETURN


;**********************************************************************
;		Double (10 bits) Precision Multiplication
;
;		PI0H:PI0M:PI0L = UI0H:UI0L * II0H:II0L
;
; 		IN:	UI0H:UI0L	number 10bit-integer (MSB/LSB)
;			II0H:II0L	factor 16bit-integer (MSB/LSB)
;		OUT:	Power_n		result 64bit-integer
;		TEMP:	mTemp3, mTemp2, mTemp1, mTemp0
;
;		NOTES:	runtime worst case: 295 clock cycles
;			standard shift and add.
;
;			input value format (10 bits) - 000000xx xxxxxxxx
;
;			Power range : 00:00:00:00 -> 00:0F:F8:01
;**********************************************************************

CalcNewPower	movf	PI0H,W
		movwf	PI1H
		movf	PI0M,W
		movwf	PI1M
		movf	PI0L,W
		movwf	PI1L		; store old power values
		
		movf	UIF0L,W
		movwf	Temp0
		movf	UIF0H,W
		movwf	Temp1
		movf	IIF0L,W
		movwf	Temp2
		movf	IIF0H,W
		movwf	Temp3

;		movf	UI0L,W
;		movwf	Temp0
;		movf	UI0H,W
;		movwf	Temp1
;		movf	II0L,W
;		movwf	Temp2
;		movf	II0H,W
;		movwf	Temp3

		clrf	PI0H
		clrf	PI0M
		clrf	PI0L

		bcf	_C
		rlf	Temp2,F		; right align operator
		rlf	Temp3,F
		bcf	_C
		rlf	Temp2,F
		rlf	Temp3,F

		bsf	PI0M,1		; placed to stop after 10 turns

m_jump1		bcf	_C
		rrf	Temp1,F
		rrf	Temp0,F		; test wheater LSB was 0 or 1
		btfss	_C
		   goto	m_jump2		; 0 -> skip this decimal place
		movf	Temp2,W		
		addwf	PI0M,F		; add LSBs
		btfsc	_C
		   incfsz   PI0H,F
		movf	Temp3,W		; add MSBs
		addwf	PI0H,F

m_jump2		bcf	_C
		rrf	PI0H,F
		rrf	PI0M,F
		rrf	PI0L,F
		
		btfss	_C
		   goto m_jump1

		RETURN

;**********************************************************************
;		Get a filtered value of (UIN)
;
;		- Result register (000000xx xxxxxxxx)
;		OUT: UIF0H,UIF0L
;**********************************************************************
GetFilteredUin	call    GetUin		; Measure current value of Uin
		call    GetUin		; Measure current value of Uin
		call    GetUin		; Measure current value of Uin
		call    GetUin		; Measure current value of Uin		

		movf	UIF0H,W		; Shift new filtered value into old value
		movwf	UIF1H
		movf	UIF0L,W
		movwf	UIF1L

		clrf	UIF0H
		movf	UI0L,W

		addwf	UI1L,W		; Add it to former value
		btfsc   _C	; If a carry occured...
		   incf	UIF0H,F		; ...then consider it 
		addwf   UI2L,W
		btfsc	_C	; If a carry occured...
		   incf UIF0H,F
		addwf	UI3L,W	
		btfsc	_C		;If a carry occured...
		   incf	UIF0H,F
		movwf	UIF0L		; save L-sum in UIFL
		
		movf	UI0H,W		; get H-Bite of last measuring
		addwf	UI1H,W
		addwf   UI2H,W
		addwf	UI3H,W
		addwf   UIF0H,F		;save H-sum in UIFH

		;devide 16Bit by 4


		bcf	_C
		rrf	UIF0H,F		;rotate H-Byte through carry
		rrf	UIF0L,F		;rotate L-Byte and insert a ev. carry
		bcf	_C
		rrf	UIF0H,F		;rotate H-Byte through carry
		rrf	UIF0L,F		;rotate L-Byte and insert a ev. carry
;*******************************************
;   if Uin > Umpp, then decrease stepwidth
;*******************************************
		
		jmpFgtL	UIF0H, UmppH, SmallDelta
		jmpFltL	UIF0H, UmppH, BigDelta
		jmpFgtL UIF0L, UmppL, SmallDelta

BigDelta	BANK1
		movlw	BIGSTEP_H
		movwf	STEP_H
		movlw	BIGSTEP_L
		movwf	STEP_L
		BANK0
		RETURN

SmallDelta	BANK1
		movlw	SMALLSTEP_H
		movwf	STEP_H
		movlw	SMALLSTEP_L
		movwf	STEP_L
		BANK0
		RETURN

;**********************************************************************
;		Get a filtered value of (UOUT)
;
;		- Result register (000000xx xxxxxxxx)
;		OUT: UOFH,UOFL
;**********************************************************************
GetFilteredUout	call    GetUout		; Measure current value of Uout
		call    GetUout		; Measure current value of Uout		
		call    GetUout		; Measure current value of Uout
		call    GetUout		; Measure current value of Uout

		clrf	UOFH
		movf	UO0L,W

		addwf	UO1L,W		; Add it to former value
		btfsc   _C		; If a carry occured...
		   incf	UOFH,F		; ...then consider it 
		addwf   UO2L,W
		btfsc	_C		; If a carry occured...
		   incf UOFH,F
		addwf	UO3L,W	
		btfsc	_C		; If a carry occured...
		   incf	UOFH,F
		movwf	UOFL		; save L-sum in UOFL
		
		movf	UO0H,W		; get H-Bite of last measuring
		addwf	UO1H,W
		addwf   UO2H,W
		addwf	UO3H,W
		addwf   UOFH,F		;save H-sum in UIOFH

		;devide 16Bit by 4
		bcf	_C
		rrf	UOFH,F		;rotate H-Byte through carry
		rrf	UOFL,F		;rotate L-Byte and insert a ev. carry
		bcf	_C
		rrf	UOFH,F		;rotate H-Byte through carry
		rrf	UOFL,F		;rotate L-Byte and insert a ev. carry

		RETURN


;**********************************************************************
;		Get a filtered value of (IIN)
;
;		- Result register (000000xx xxxxxxxx)
;		OUT: IIFH,IIFL
;**********************************************************************
GetFilteredIin	call    GetIin		; Measure current value of Iin
		call    GetIin		; Measure current value of Iin
		call    GetIin		; Measure current value of Iin
		call    GetIin		; Measure current value of Iin
				
		movf	IIF0H,W		; Shift new filtered value into old value
		movwf	IIF1H
		movf	IIF0L,W
		movwf	IIF1L

		clrf	IIF0H
		movf	II0L,W

		addwf	II1L,W		; Add it to former value
		btfsc   _C		; If a carry occured...
		   incf	IIF0H,F		; ...then consider it 
		addwf   II2L,W
		btfsc	_C		; If a carry occured...
		   incf IIF0H,F
		addwf	II3L,W	
		btfsc	_C		; If a carry occured...
		   incf	IIF0H,F
		movwf	IIF0L		; save L-sum in IIFL
		
		movf	II0H,W		; get H-Bite of last measuring
		addwf	II1H,W
		addwf   II2H,W
		addwf	II3H,W
		addwf   IIF0H,F		;save H-sum in IIFH

		;devide 16Bit by 4
		bcf	_C
		rrf	IIF0H,F		;rotate H-Byte through carry
		rrf	IIF0L,F		;rotate L-Byte and insert a ev. carry
		bcf	_C
		rrf	IIF0H,F		;rotate H-Byte through carry
		rrf	IIF0L,F		;rotate L-Byte and insert a ev. carry

		RETURN


;**********************************************************************
;		INTADC (ADC interrupt)
;
;		Occurs every 16 PWM period from PWM module to start ADC
;
;**********************************************************************

IntADC		bcf	PIR1,TMR2IF	; clear interrupt flag

		goto	IntReturn


;**********************************************************************
;		UpdateCAN 
;
;		Updates IIFH,IIFL,UOFH,UOFL,UIF0H,UIF0L,TCL,TCH,TAMBH,TAMBL
;
;**********************************************************************
UpdateCAN
		clrwdt
		call	CANRqTest					; if requested send values over CAN
		Return
