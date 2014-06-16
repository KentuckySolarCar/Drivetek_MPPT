;**********************************************************************
;   P R O G R A M M	MPPTnG                                            *
;                                                                     *
;   Undervoltage routine			                                  *
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
;    Changes:       program part which waits for sufficient input     *
;		   		    voltage					     		 			  *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;    - Main program : mpptngv4.asm                                    *
;                                                                     *
;**********************************************************************
UnderVoltage	;call	PWMoff

		call	UpdateCAN
		call	GetFilteredUin
	
		jmpFltL UIF0H,MINUINH,UnderVoltageloop	; jmp, if minimal voltage not reached
		jmpFgtL UIF0H,MINUINH,EnoughVin		; go on, if minimal reached
		jmpFleL	UIF0L,MINUINL,UnderVoltageloop	; consider L-Byte
		goto	EnoughVin

UnderVoltageloop

		bsf		UNDV
		bsf		REDLED				; in this state, the red LED is blinking
		call	wait20ms
		bcf		REDLED
		call	wait1s
		call	DecDuty	
		goto	UnderVoltage
	

EnoughVin	bcf 	UNDV
		;call	PWMon
		RETURN
