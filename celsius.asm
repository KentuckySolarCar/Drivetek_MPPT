;**********************************************************************
;   P R O G R A M M	MPPTnG                                        *
;                                                                     *
;   Temperature values converter Version: Celsius                     *
;**********************************************************************
;                                                                     *
;    Filename:	    celsius.asm                                       *
;    Date:          15.11.00                                          *
;    Last Update:   01.10.01                                          *
;    File Version:  V3.0                                              *
;                                                                     *
;    Author:        Michael Zürcher             		      *
;                                                                     *
;    Company:       HTA-Biel/Bienne Indulab                           *
;                                                                     *
;    								      *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;    - Main program : mpptngV4.asm                                    *
;                                                                     *
;**********************************************************************
ConvTempCooler	jmpFeqL TCH,0x03,Cgt70	; Not a valid temperature
		
		jmpFgeL TCH,0x03,C75
		jmpFgeL TCH,0x02,C70
		jmpFgeL TCL,0xA4,C65
		jmpFgeL TCL,0x46,C60
		jmpFgeL TCL,0x3C,C55
		jmpFgeL TCL,0x26,C50
		jmpFgeL TCL,0x1B,C45
		jmpFgeL TCL,0x16,C40
		jmpFgeL TCL,0x13,C35
		jmpFgeL TCL,0x12,C30
		jmpFgeL TCL,0x11,C25
		goto	NoCels		; Tcooler lower than 20C

Cgt70		jmpFgeL TCL,0xF9,NoCels
		jmpFgeL	TCL,0xF8,C90	
		jmpFgeL TCL,0xF2,C85
		jmpFgeL TCL,0xDB,C80
		goto	C75

ConvTempAmb	jmpFgeL	TAMBL,0xA6,NoCels
		jmpFgeL	TAMBL,0xA3,C90
		jmpFgeL	TAMBL,0x9F,C85
		jmpFgeL	TAMBL,0x9B,C80
		jmpFgeL	TAMBL,0x97,C75
		jmpFgeL	TAMBL,0x93,C70
		jmpFgeL	TAMBL,0x90,C65
		jmpFgeL	TAMBL,0x8C,C60
		jmpFgeL	TAMBL,0x88,C55
		jmpFgeL	TAMBL,0x85,C50
		jmpFgeL	TAMBL,0x80,C45
		jmpFgeL	TAMBL,0x7C,C40
		jmpFgeL	TAMBL,0x79,C35
		jmpFgeL	TAMBL,0x75,C30
		jmpFgeL	TAMBL,0x70,C25
		jmpFgeL	TAMBL,0x6D,C20
		jmpFgeL	TAMBL,0x69,C15
		goto	NoCels


NoCels	movlw	0xFF
	RETURN
C95	movlw	0x5F
	RETURN
C90	movlw	0x5A
	RETURN
C85	movlw	0x55
	RETURN
C80	movlw	0x50
	RETURN
C75	movlw	0x4B
	RETURN
C70	movlw	0x46
	RETURN
C65	movlw	0x41
	RETURN
C60	movlw	0x3C
	RETURN
C55	movlw	0x37
	RETURN
C50	movlw	0x32
	RETURN
C45	movlw	0x2D
	RETURN
C40	movlw	0x28
	RETURN
C35	movlw	0x23
	RETURN
C30	movlw	0x1E
	RETURN
C25	movlw	0x19
	RETURN
C20	movlw	0x14
	RETURN
C15	movlw	0x0F
	RETURN		
