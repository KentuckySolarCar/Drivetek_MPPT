;**********************************************************************
;   P R O G R A M M	MPPTnG                                            *
;                                                                     *
;   Traking program for MPPT new generation                           *
;**********************************************************************
;                                                                     *
;    Filename:	    charge.asm                                        * 
;    Date:          16.2.05                                           *
;    Last Update:   16.2.05                                           *
;    File Version:  V1.0                                              *
;                                                                     *
;    Author:        Christoph Raible                                  *
;                                                                     *
;    Company:       drivetek ag                                       *
;                                                                     *
;    Changes:       program part which charges the output capacitor   *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;                                                                     *
;                                                                     *
;**********************************************************************
PreCharge	
		clrwdt					; reset watchdog
		bsf		REDLED
		bsf		NOC
		movlw	0x01
		movwf	Waitboost			;Init Boost-Timer
		movlw	INITDUTY		; PWM2 duty cycle (Sm')
		movwf	DUTY2_H			; init duty variable
		movwf	CCPR2L
MeasStableUs

		call	GetFilteredUin

		jmpFltL UIF0H,MINUINH,CV_UVState1	; jmp, if minimal voltage not reached
		jmpFgtL UIF0H,MINUINH,CV_MeasUout1	; go on, if minimal reached
		jmpFleL	UIF0L,MINUINL,CV_UVState1	; consider L-Byte
		goto	CV_MeasUout1

CV_UVState1	call 	UnderVoltage
CV_MeasUout1
		
	;	call	UpdateCAN
		clrwdt					; reset watchdog
		
		call 	GetFilteredUout
		
		movlw	MINUBATH	     	   	;get 3/4 of MINUBAT
		movwf	Temp0
		movlw	MINUBATL
		movwf	Temp1

		bcf	_C							;divide by 2
		rrf	Temp0,F
		rrf	Temp1,F
		bcf	_C							;divide by 2 (now 4)
		rrf	Temp0,W
		movwf	Temp2		
		rrf	Temp1,W		
		addwf	Temp1,F					;times tree
		btfsc	_C
		   incf	  Temp2,F
		movf	Temp2,W
		addwf	Temp0,F
		
		jmpFltF UOFH,Temp0,BoostALittle		; jmp, if output voltage within limits
		movf	UOFH,W
		jmpWgtF Temp0,Wait4Connect			; go on, if ouput voltage exceeded
		jmpFleF	UOFL,Temp1,BoostALittle		; consider L-Byte
		goto	Wait4Connect	
		
BoostALittle
		call	PWMon						; Precharge the output C during 300us
		movlw	0xFF
		call	wait		
		call	PWMoff	
		call	wait20ms
		goto	MeasStableUs
		
		
Wait4Connect
		clrwdt								; reset watchdog
		call	UpdateCAN
		call 	GetFilteredUout				;MINUBAT<=UOUT<=MAXUOUT
		movlw	MINUBATH
		subwf	UOFH,w
		btfsc	_Z
			goto  	CheckLsb
		btfss	_C							;c set if w=UOFH-MINUBATH >=0
			goto	PreCharge
	
		goto  	CheckMaxuout

CheckLsb	
		movlw	MINUBATL
		subwf	UOFL,W
		btfss	_C							;c set if w=UOFL-MINUBATL >=0	
			goto	PreCharge


CheckMaxuout

		movlw	MAXUOH
		movwf	Temp1
		movf	UOFH,w					
		subwf	Temp1,w
		btfsc	_Z
			goto  	CheckLsb2
		btfss	_C							;c set if w=MAXUOH-UOFH >=0
			goto	PreCharge
	
		goto  	BatConn

CheckLsb2	
		movlw	MAXUOL
		movwf	Temp1
		movfw	UOFL
		subwf	Temp1,W
		btfss	_C							;c set if w=MAXUOL-UOFL >=0
			goto	PreCharge

BatConn	
		clrwdt	

		call	GetFilteredUin

		jmpFltL UIF0H,MINUINH,CV_UVState2	; jmp, if minimal voltage not reached
		jmpFgtL UIF0H,MINUINH,CV_MeasUout2	; go on, if minimal reached
		jmpFleL	UIF0L,MINUINL,CV_UVState2	; consider L-Byte
		goto	CV_MeasUout2

CV_UVState2	call 	UnderVoltage
CV_MeasUout2

		call	GetFilteredUin				;check Uin and transform in to 8bit value
		rrf		UIF0H,F	
		rrf		UIF0L,F
		rrf		UIF0H,F
		rrf		UIF0L,F
		movlw	0x53						;50V @ 8bit ADC
		subwf	UIF0L,w						;UIFOL-50V<0?
		btfss	STATUS,C					; c set if UIF0L-50V>0
			goto	BigPWM					
		movlw	0x74						;70V @ 8bit ADC
		subwf	UIF0L,w						;UIFOL-70V<0?
		btfss	STATUS,C					; c set if UIF0L-70V>0
			goto	MedPWM
		movlw	0x25						;small duty cycle
		movwf	CCPR2L
		goto	StartPWM
MedPWM	
		movlw	0x5b
		movwf	CCPR2L						;medium duty cycle
		goto	StartPWM
BigPWM	
		movlw	0x89						;big duty cycle
		movwf	CCPR2L

StartPWM	
		clrwdt
		call	PWMon
		call	waittoboost
		call	PWMoff
		call	wait20ms

		clrwdt
		movfw	UOFH						;Save old values of UOFH,OUFL
		movwf	Temp0
		movfw	UOFL
		movwf	Temp1

		call GetFilteredUout				;check delta of Uout and dedect Bat. connection
		
		movlw	0xFF						;Twocomplement
		xorwf	UOFL,F		
		xorwf	UOFH,F	
		movlw	0x01
		addwf	UOFL,F
		btfsc	STATUS,C
			Incf	UOFH
 		movfw	UOFL   
 		addwf	Temp1,F     		; compare Uout_old Low Byte to Uout Low Byte Temp1=Temp1-UOFL
   		btfsc 	STATUS, C     		; is result of subtraction negative?
     	  goto 	Overflow    
CheckMSB
		movfw	UOFH				; compare Uout_old High Byte to Uout High Byte Temp0=Temp0-UOFH
		addwf	Temp0,F
		btfss	STATUS,C			;is result of subtraction negativ?
			goto	Twocomplement

Checkdelta
   		movlw 	0x03       		    ; max. allowed difference ca. 0.6V
		movwf	Temp2
		movfw	Temp1
   		subwf 	Temp2,w				;w=Temp2-Temp1 (max. allowed difference-real difference)				
   		btfss 	STATUS, C    		; jump back if difference too big
			goto 	ResetBoosttime
		movlw	0x05				;longer boost-time
		addwf	Waitboost,F
		btfss	STATUS,C
			goto	Wait4Connect		
		goto	RetFromPreCha	    ; Bat. connected?

ResetBoosttime
		movlw	0x01
		movwf	Waitboost
		goto	Wait4Connect

Overflow
		Incf	Temp0	
		goto	CheckMSB

Twocomplement			 
		movlw 	0xFF			 	;invert bits (two's complement)		
		xorwf	Temp1,f
		xorwf	Temp0,f
		movlw	0x01
		addwf	Temp1,f
		btfsc	STATUS,C
			Incf	Temp0
		goto	Checkdelta
		
RetFromPreCha	
		clrwdt
		bcf		REDLED
		bcf		NOC
		call 	UpdateCAN
		movlw	INITDUTY		; PWM2 duty cycle (Sm')
		movwf	DUTY2_H			; init duty variable
		movwf	CCPR2L
		call	wait1s
		RETURN


		
