;**********************************************************************
;   P R O G R A M M	MPPTnG                                        *
;                                                                     *
;   Traking program for MPPT new generation                           *
;**********************************************************************
;                                                                     *
;    Filename:	    noload.asm                                        *
;    Date:          30.04.01                                          *
;    Last Update:   23.09.01                                          *
;    File Version:  V3.0                                              *
;                                                                     *
;    Author:        Michael Zürcher                                   *
;                                                                     *
;    Company:       HTA-Biel/Bienne Indulab                           *
;                                                                     *
;    Changes:       program for dealing with no load at output        *
;		    added Interrupt routine (5.5.01)                  *	                                                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;    - Main program : mpptng.asm                                      *
;                                                                     *
;**********************************************************************

NCInterupt	call	PWMoff
		bsf	NOC

DeCharge	call	wait20ms		; wait for capacitor to be discharged
		call	UpdateCAN
		call 	GetFilteredUout

		jmpFltL UOFH,MAXUOH,ResNOC	; jmp, if minimal voltage not reached
		jmpFgtL UOFH,MAXUOH,DeCharge	; go on, if minimal reached
		jmpFleL	UOFL,MAXUOL,ResNOC	; consider L-Byte

		goto	DeCharge	

ResNOC		bcf	RES_NOC
		call	wait20ms
		bsf	RES_NOC
		
;----------------------------------------------------------------------
		call	PWMon			; PWM einschalten
		
		bcf	INTCON,RBIF		; reset interrupt
		bcf	NOC

		goto	IntReturn
		
