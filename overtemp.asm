;**********************************************************************
;   P R O G R A M M	MPPTnG                                       	  *
;                                                                     *
;   Undervoltage routine			                      			  *
;**********************************************************************
;                                                                     *
;    Filename:	    underv.asm                                        *
;    Date:          21.09.01                                          *
;    Last Update:   28.09.01                                          *
;    File Version:  V3.0                                              *
;                                                                     *
;    Author:        Michael Zürcher                                   *
;                                                                     *
;    Company:       HTA-Biel/Bienne Indulab                           *
;                                                                     *
;    Changes:       program part which decreases current, due to      *
;		    excessive temperature			     					 *
;		         					      *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;    - Main program : mpptngv4.asm                                    *
;                                                                     *
;**********************************************************************

OverTemp
		btfsc	INT_OVH	
			bsf		OVT

		btfss	OVT	
			goto	Shortexit

		
		call 	PWMoff
		bsf		REDLED
		call	UpdateCAN
		call	wait20ms        			; to obtain an approximate tracking frequency of 50Hz
						
		call	GetFilteredUin
		jmpFltL UIF0H,MINUINH,OT_UVState	; jmp, if minimal voltage not reached
		jmpFgtL UIF0H,MINUINH,OT_MeasTemp	; go on, if minimal reached
		jmpFleL	UIF0L,MINUINL,OT_UVState	; consider L-Byte
		goto	OT_MeasTemp

OT_UVState	call 	UnderVoltage

OT_MeasTemp	call	GetTCooler				; test if temp. is within limits

		movlw	0x00						;reset value, is max. temp for reset reached?
		subwf	TCH,w
		btfsc	_Z
			goto  	OVT_CheckLsb
		goto	OverTemp

OVT_CheckLsb	
		movlw	0xE8						; 0.90V or 88 C
		subwf	TCL,W
		btfsc	_C							;c set if w=TCL-ED >=0	
			goto	OverTemp

ExitOverTemp
		bcf		OVT			;Reset OVH-Flag
		bcf		RES_OVH		;Reset OVH-Flip-Flop
		call	wait20ms
		bsf		RES_OVH
		bcf 	REDLED
		call 	PWMon
Shortexit		
		RETURN

;**********************************************************************
