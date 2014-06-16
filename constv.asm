;**********************************************************************
;   P R O G R A M M	MPPTnG                                        	  *
;                                                                     *
;   Undervoltage routine			                      			  *
;**********************************************************************
;                                                                     *
;    Filename:	    underv.asm                                        *
;    Date:          21.09.01                                          *
;    Last Update:   28.09.01                                          *
;    File Version:  V3.0                                              *
;                                                                     *
;    Author:        Michael Zuercher                                  *
;                                                                     *
;    Company:       HTA-Biel/Bienne Indulab                           *
;                                                                     *
;    Changes:       program part which decreases current	          *
;		         					      							  *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;    - Main program : mpptngv4.asm                                    *
;                                                                     *
;**********************************************************************

ConstVMode	
		call	PWMoff
		call	wait20ms
Wait4Connect1								;is bat. still connected?
		call	UpdateCAN
		clrwdt								; reset watchdog
		call 	GetFilteredUout				;UOUT<=MAXUOUT+2V
CheckMaxuout1
		movlw	0x10						;add 2V to MAXOUT
		movwf	Temp4
		movlw	MAXUOH
		movwf	Temp5
		movlw	MAXUOL
		addwf	Temp4,f
		btfsc	STATUS,C
			incf	Temp5
		
		movfw	Temp5
		movwf	Temp1
		movf	UOFH,w					
		subwf	Temp1,w
		btfsc	_Z
			goto  	CheckLsb21
		btfss	_C							;c set if w=MAXUOH-UOFH >=0
			goto	NoBatConnected
		goto  	ConstVMode2

CheckLsb21	
		movfw	Temp4
		movwf	Temp1
		movfw	UOFL
		subwf	Temp1,W
		btfsc	_C							;c set if w=MAXUOL-UOFL >=0
			goto	ConstVMode2

NoBatConnected
		bsf		REDLED
		bsf		NOC
		bcf		BVLR
		call 	PWMoff

DeCharge1
		call	wait20ms		; wait for capacitor to be discharged
		call	UpdateCAN
		call	GetFilteredUin

		jmpFltL UIF0H,MINUINH,CV_UVState3	; jmp, if minimal voltage not reached
		jmpFgtL UIF0H,MINUINH,CV_MeasUout3	; go on, if minimal reached
		jmpFleL	UIF0L,MINUINL,CV_UVState3	; consider L-Byte
		goto	CV_MeasUout3

CV_UVState3	call 	UnderVoltage
CV_MeasUout3

		call 	GetFilteredUout

		jmpFltL UOFH,MAXUOH,ClearNOC	; jmp, if minimal voltage not reached
		jmpFgtL UOFH,MAXUOH,DeCharge1	; go on, if minimal reached
		jmpFleL	UOFL,MAXUOL,ClearNOC	; consider L-Byte

		goto	DeCharge1	
	
ClearNOC
		bcf 	NOC			
		bcf		REDLED
;------------------------------------------------------------------------		
ConstVMode2
		bsf	BVLR
		bsf	REDLED
		call	DecDuty				; decrement duty cycle
		call	PWMon
		call	wait20ms        		; to obtain an approximate tracking frequency of 50Hz
		
		call 	UpdateCAN				
		call	GetFilteredUin

		jmpFltL UIF0H,MINUINH,CV_UVState	; jmp, if minimal voltage not reached
		jmpFgtL UIF0H,MINUINH,CV_MeasUout	; go on, if minimal reached
		jmpFleL	UIF0L,MINUINL,CV_UVState	; consider L-Byte
		goto	CV_MeasUout

CV_UVState	call 	UnderVoltage
	
		call 	UpdateCAN
		
CV_MeasUout	call	GetFilteredUout			; test if battery reached full level
		call	UpdateCAN


		jmpFltL UOFH,MAXUOH,MPPTtracking	; jmp, if output voltage within limits
		jmpFgtL UOFH,MAXUOH,CheckBatCon		; go on, if ouput voltage exceeded
		jmpFleL	UOFL,MAXUOL,MPPTtracking	; consider L-Byte
		goto	Wait4Connect1
CheckBatCon
		goto	Wait4Connect1
	
;**********************************************************************
