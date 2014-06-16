;**********************************************************************
;   P R O G R A M M	MPPTnG                                            *
;                                                                     *
;   Traking program for MPPT new generation                           *
;**********************************************************************
;                                                                     *
;    Filename:	    track.asm                                         *
;    Date:          13.03.01                                          *
;    Last Update:   28.09.01                                          *
;    File Version:  V3.0                                              *
;                                                                     *
;    Author:        Michael Zürcher			                          *
;                                                                     *
;    Company:       HTA-Biel/Bienne Indulab                           *
;                                                                     *
;    Changes:       Content Improved perturbation and observation     *
;                   tracking method                                   *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;    - Main program : mpptngv4sm                                      *
;                                                                     *
;**********************************************************************

;**********************************************************************
;		P&O Algorithm 
; (runs as an infinite loop, unless interrupt occurs)
;
;  dVk-1 dPk-1 dVk  dPk   dVk+1         Description
;______________________________________________________________________
; 
;   -     -     -     -      + 	  A) invalid
;   -     -     -     +      +    B) invalid, control condition applies
;   -     -     +     -      -    C) incidence decreased meanwhile
;   -     -     +     +      +    D) V<Vmpp, keep increasing delta
;   -     +     -     -      +    E) MPP is reached, inverse delta
;   -     +     -     +      -    F) unclear, control condition applies
;   -     +     +     -      -    G) V>Vmpp, decrease delta again
;   -     +     +     +      -    H) incidence increased meanwhile, cc applies
;   +     -     -     -      +    I) incidense decreased meanwhile
;   +     -     -     +      -    J) V>Vmpp, keep decreasing delta
;   +     -     +     -      -    K) invalid
;   +     -     +     +      -    L) invalid, cc applies
;   +     +     -     -      +    M) V<Vmpp, increase delta again
;   +     +     -     +      +    N) incidence increased meanwhile, cc applies
;   +     +     +     -      -    O) MPP is reached, inverse delta
;   +     +     +     +      -    P) unclear, control condition applies
;**********************************************************************
;  dIk-1 dPk-1 dIk  dPk   dIk+1         Description
;______________________________________________________________________
; 
;   -     -     -     -      - 	  A) invalid
;   -     -     -     +      -    B) invalid, control condition applies
;   -     -     +     -      +    C) incidence decreased meanwhile
;   -     -     +     +      -    D) V<Vmpp, keep increasing delta
;   -     +     -     -      -    E) MPP is reached, inverse delta
;   -     +     -     +      +    F) unclear, control condition applies
;   -     +     +     -      +    G) V>Vmpp, decrease delta again
;   -     +     +     +      +    H) incidence increased meanwhile, cc applies
;   +     -     -     -      -    I) incidense decreased meanwhile
;   +     -     -     +      +    J) V>Vmpp, keep decreasing delta
;   +     -     +     -      +    K) invalid
;   +     -     +     +      +    L) invalid, cc applies
;   +     +     -     -      -    M) V<Vmpp, increase delta again
;   +     +     -     +      -    N) incidence increased meanwhile, cc applies
;   +     +     +     -      +    O) MPP is reached, inverse delta
;   +     +     +     +      +    P) unclear, control condition applies
;**********************************************************************

TrackingLoop	call	wait1s		; wait 200ms to eliminate an eventual "flippering"
		call	PWMon		; turns conversion on
;**********************************************************************
; Tracking Loop
;**********************************************************************
	
MPPTtracking	
		bcf	BVLR
		movlw	B'00010000'			; inverts REDLED
		xorwf	PORTD,F				; Has to be different for MPPT V1.X!
		
		clrwdt						; reset watchdog

		call	wait20ms       			; to obtain an approximate tracking frequency of 50Hz
						
		call	GetFilteredUin

		jmpFltL UIF0H,MINUINH,UVState		; jmp, if minimal voltage not reached
		jmpFgtL UIF0H,MINUINH,MeasIin		; go on, if minimal reached
		jmpFleL	UIF0L,MINUINL,UVState		; consider L-Byte
		goto	MeasIin

UVState		call 	UnderVoltage
		
MeasIin		call	GetFilteredIin			; Measure the current input current

		call	MinPower					; call Minpower Test Subroutine

		call	SetVSFup					; Prepare Voltage Signum Flags for the Decision Tree
		call	SetPSFup					; Prepare Current Signum Flags for the Decision Tree

MeasUout	call	GetFilteredUout			; test if battery reached full level
		jmpFltL UOFH,MAXUOH,MeasTemp		; jmp, if output voltage within limits
		jmpFgtL UOFH,MAXUOH,ConstVMode		; go on, if ouput voltage exceeded
		jmpFleL	UOFL,MAXUOL,MeasTemp		; consider L-Byte
		
		goto	ConstVMode

MeasTemp	
		call	OverTemp					;Check Temp.

		
TXupdate	call 	CANRqTest
		goto	DecisionTree

;----------------------------------------------------------------------
; Tracking algorithm
;----------------------------------------------------------------------	

		;basic algorithm

DecisionTree	BANK1
		btfss	PSF,0		;basic algorithm
		   goto NegP		
PosP		btfss	VSF,0		
		   goto NegDV
		goto  PosDV
NegP		btfss	VSF,0
		   goto PosDV
		goto  NegDV
;----------------------------------------------------------------------

		;P&O algorithm


		BANK1
		btfss	VSF,0		;P&O algorithm
		   goto   PXXX

MXXX		btfss	VSF,1
		   goto	  MPXX

MMXX		goto	PosDV		; in case of A) B) E) F)

MPXX		btfss	PSF,1
		   goto   PosDV		; in case of M) N)

MPXM		btfss	PSF,0
		   goto   NegDV		; in case of J)
		goto   PosDV		; in case of I)

PXXX		btfss	VSF,1
		   goto   NegDV		; in case of K) L) O) P)

PMXX		btfss	PSF,1
		   goto   NegDV		; in case of G) H)

PMXM		btfss	PSF,0
		   goto   PosDV		; in case of D)
		goto   NegDV		; in case of C)

;----------------------------------------------------------------------

PosDV		BANK0
		call	DecDuty		; decrement duty cycle
		goto	MPPTtracking

NegDV		BANK0
		call	IncDuty		; increment duty cycle
		goto	MPPTtracking

;**********************************************************************



;**********************************************************************
;		Actualize voltage signum Flags
;
;		- Result register (-------- or ++++++++) 1 = -, 0 = +
;		OUT: VSF
;**********************************************************************
SetVSFup	movf	UIF0H,W		;compare current with former UIF_H
		subwf	UIF1H,W
		
		btfss 	_Z
		   goto  VSFsetup

		movf	UIF0L,W		;compare current with former PIF_L
		subwf	UIF1L,W
VSFsetup	BANK1
		rlf 	VSF,F		;use borrow as new voltage signum
		BANK0
	
		RETURN


;**********************************************************************
;		Actualize power signum Flags
;
;		- Result register (-------- or ++++++++) 1 = -, 0 = +
;		OUT: PSF
;**********************************************************************
SetPSFup	movf	PI0H,W		;compare current with former PIF_H
		subwf	PI1H,W

		btfss	_Z
		   goto  PSFsetup
		
		movf	PI0M,W		;compare current with former PIF_M
		subwf	PI1M,W

		btfss 	_Z
		   goto  PSFsetup

		movf	PI0L,W		;compare current with former PIF_L
		subwf	PI1L,W
PSFsetup	BANK1
		rlf 	PSF,F		;use borrow as new voltage signum			
		movlw	0x01
		andwf	PSF,F
		BANK0			

		RETURN


