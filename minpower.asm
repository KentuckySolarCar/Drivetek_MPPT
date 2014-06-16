;**********************************************************************
;   P R O G R A M M	MPPTnG                                        *
;                                                                     *
;   Undervoltage routine			                      *
;**********************************************************************
;                                                                     *
;    Filename:	    underv.asm                                        *
;    Date:          21.09.01                                          *
;    Last Update:   21.09.01                                          *
;    File Version:  V3.0                                              *
;                                                                     *
;    Author:        Michael Zuercher                                  *
;                                                                     *
;    Company:       HTA-Biel/Bienne Indulab                           *
;                                                                     *
;    Changes:       program part which waits for sufficient input     *
;		    voltage					      *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;    - Main program : mpptngv4.asm                                    *
;                                                                     *
;**********************************************************************

MinPower	call	CalcNewPower
		movf	PI0H,F				; Zero is affected
		btfss	_Z
		   goto    EnoughPower
		jmpFltL PI0M,MINPINM,NotEnoughPower	; jmp, if minimal Power not reached
		jmpFgtL PI0M,MINPINM,EnoughPower	; go on, if minimal reached
		jmpFleL	PI0L,MINPINL,NotEnoughPower	; consider L-Byte
		goto 	EnoughPower
		
NotEnoughPower	BANK1
		incf	PminCounter,F
		movlw	0x30
		subwf	PminCounter,W			;PminCounter-0x0A
		BANK0
		btfss	_C  				;!!!Achtung ueberprüfen
		   goto	   RetFromPMin
		goto	Main	; Stack has not to be decremented, due to circular stack architecture!

EnoughPower	BANK1
		movf	PminCounter,F
		btfss	_Z
		   decf	   PminCounter,F
		BANK0

RetFromPMin	nop
		RETURN
		



