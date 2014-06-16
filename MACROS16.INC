;Basic macros for PIC16C series
;6/20/98

#ifdef __16C77
#define _COMMONBANK  ; use common upper 16 bytes in 4 banks
#endif
#ifdef __16C76
#define _COMMONBANK  ; use common upper 16 bytes in 4 banks
#endif

TRUE            equ     1
FALSE           equ     0  

; Page 1 register definitions to avoid page warning

OPTION_REG_P                 EQU     H'0081'-0x80
TRISA_P                      EQU     H'0085'-0x80
TRISB_P                      EQU     H'0086'-0x80
TRISC_P                      EQU     H'0087'-0x80
TRISD_P                      EQU     H'0088'-0x80
TRISE_P                      EQU     H'0089'-0x80
PIE1_P                       EQU     H'008C'-0x80
PIE2_P                       EQU     H'008D'-0x80
PCON_P                       EQU     H'008E'-0x80
PR2_P                        EQU     H'0092'-0x80
SSPADD_P                     EQU     H'0093'-0x80
SSPSTAT_P                    EQU     H'0094'-0x80
TXSTA_P                      EQU     H'0098'-0x80
SPBRG_P                      EQU     H'0099'-0x80
ADCON1_P                     EQU     H'009F'-0x80



; Special register bit definition pairs

;     STATUS bit definitions

#define _C              STATUS,0
#define _DC             STATUS,1
#define _Z              STATUS,2
#define _PD             STATUS,3
#define _TO             STATUS,4
#define _RP0            STATUS,5
#define _RP1            STATUS,6
#define _IRP            STATUS,7


#define _INTE       INTCON,INTE   ; External interrupt enable 
#define _INTF       INTCON,INTF   ; External interrupt flag
#define _RBIE       INTCON,RBIE   ; Port B pins 4-7 edge interrupt enable 
#define _RBIF       INTCON,RBIF   ; Port B pins 4-7 edge interrupt flag
#define _T0IE       INTCON,T0IE   ; Timer 0 interrupt enable 
#define _T0IF       INTCON,T0IF   ; Timer 0 interrupt flag

#define _CCP1IE_P   PIE1_P,CCP1IE ; Timer 1 compare int enable (page 1)
#define _CCP1IF     PIR1,CCP1IF   ; Timer 1 compare int flag

#define _RCIE_P     PIE1_P,RCIE   ; async rec interrupt enable (page 1)
#define _RCIF       PIR1,RCIF     ; async rec interrupt flag

#define _TXIE_P     PIE1_P,TXIE   ; async xmit interrupt enable (page 1)
#define _TXIF       PIR1,TXIF     ; async xmit interrupt flag

#define _SSPIE_P    PIE1_P,SSPIE  ; SSP int enable (page 1)
#define _SSPIF      PIR1,SSPIE    ; SSP interrupt flag

#define _TMR1IE_P   PIE1_P,TMR1IE ; Timer 1 enable (page 1)
#define _TMR1IF     PIR1,TMR1IF   ; Timer1 interrupt flag

#define _TMR2IE_P   PIE1_P,TMR2IE ; Timer 2 enable (page 1)
#define _TMR2IF     PIR1,TMR2IF   ; Timer2 interrupt flag

#ifdef _COMMONBANK ; use common upper 16 bytes in 4 banks

PAGE3	macro	
	bsf	PCLATH,4
	bsf	PCLATH,3
	endm

PAGE2	macro
	bsf	PCLATH,4
 	bcf	PCLATH,3
	endm

PAGE1	macro	
	bcf	PCLATH,4
	bsf	PCLATH,3
	endm

PAGE0	macro
	bcf	PCLATH,4
 	bcf	PCLATH,3
	endm


BANK3   macro
	bsf     STATUS,6
	bsf     STATUS,5
	endm

BANK2   macro
	bsf     STATUS,6
	bcf     STATUS,5
	endm

BANK1   macro
	bcf     STATUS,6
	bsf     STATUS,5
	endm

BANK0   macro
	bcf     STATUS,6
	bcf     STATUS,5
	endm


FSRBank23 macro
	bsf     STATUS,7
	endm

FSRBank01 macro
	bcf     STATUS,7
	endm
#else


PAGE1	macro	
	bsf	PCLATH,3
	endm

PAGE0	macro
 	bcf	PCLATH,3
	endm

BANK0   macro
	bcf     STATUS,5    ; Select page 0
	endm

BANK1   macro
	bsf     STATUS,5    ; Select page 1
	endm
#endif

enableInt macro
	bsf     INTCON,GIE
	endm

disableInt macro
          local    Loop
Loop    bcf     INTCON,GIE
        btfsc   INTCON,GIE
        goto    Loop
	endm



; Byte logical & arithmetic macros

bV2bV   macro   bSource,bDest
        movf    bSource,W
        movwf   bDest
        endm

bL2bV   macro   bVal,bDest
        movlw   bVal
        movwf   bDest
        endm

jmpFeqZ macro   Reg,Label
        movf    Reg,F
        btfsc   _Z
        goto    Label
        endm

jmpFneZ macro   Reg,Label
        movf    Reg,F
        btfss   _Z
        goto    Label
        endm

jmpFgtL macro   Reg1,bVal,Label
          movfw     Reg1
          jmpWgtL   bVal,Label
	endm

jmpFgeL macro   Reg1,bVal,Label
          movfw     Reg1
          jmpWgeL   bVal,Label
	endm

jmpFeqL macro   Reg,bVal,Label
	movf    Reg,W
          sublw   bVal
	btfsc   _Z
	goto    Label
	endm

jmpFneL macro   Reg,bVal,Label
	movf    Reg,W
          sublw   bVal
          btfss   _Z
          goto    Label
          endm

jmpFleL macro   Reg1,bVal,Label
          movfw     Reg1
          jmpWleL   bVal,Label
	endm

jmpFltL macro   Reg1,bVal,Label
          movfw     Reg1
          jmpWltL   bVal,Label
	endm

jmpFeqF macro   Reg1,Reg2,Label
	movf    Reg1,W
        subwf   Reg2,W
	btfsc   _Z
	goto    Label
	endm

jmpFneF macro   Reg1,Reg2,Label
	movf    Reg1,W
        subwf   Reg2,W
	btfss   _Z
	goto    Label
	endm

jmpFleF macro   Reg1,Reg2,Label
          movfw     Reg1
          jmpWleF   Reg2,Label
	endm

jmpFltF macro   Reg1,Reg2,Label
          movfw     Reg1
          jmpWltF   Reg2,Label
	endm

jmpWeqZ macro   Label        ; jmp if W == 0
        andlw   0xFF
        jmpZ    Label
        endm

jmpWneZ macro   Label        ; jmp if W != 0
        andlw   0xFF
        jmpNZ   Label
        endm

skipFeqZ macro   Reg
	movf    Reg,F
	btfss   _Z
	endm

skipFneZ macro   Reg
	movf    Reg,F
	btfsc   _Z
	endm

skipFeqL macro   Reg,bVal
	movf    Reg,W
        sublw   bVal
	btfss   _Z
	endm

skipFneL macro   Reg,bVal
	movf    Reg,W
        sublw   bVal
	btfsc   _Z
	endm

skipFeqF macro   Reg1,Reg2
	movf    Reg1,W
        subwf   Reg2,W
	btfss   _Z
	endm

skipFneF macro   Reg1,Reg2
	movf    Reg1,W
        subwf   Reg2,W
	btfsc   _Z
	endm

skipWeqZ macro
        andlw   0xFF
        btfss   _Z
        endm

skipWneZ macro
        andlw   0xFF
        btfsc   _Z
        endm

jmpWgtL macro   bVal,Label
	sublw   bVal
	btfss   _C
	goto    Label
	endm

jmpWgeL macro   bVal,Label
	sublw   bVal
	btfss   _C
	goto    Label
	btfsc   _Z
	goto    Label
	endm

jmpWeqL macro   bVal,Label
	sublw   bVal
	btfsc   _Z
	goto    Label
	endm

jmpWneL macro   bVal,Label
	sublw   bVal
	btfss   _Z
	goto    Label
	endm

jmpWleL macro   bVal,Label
	sublw   bVal
	btfsc   _C
	goto    Label
	endm

jmpWltL macro   bVal,Label
	sublw   bVal
        skipC
        bsf     _Z
	jmpNZ	Label
	endm

jmpWgtF macro   Reg,Label
	subwf   Reg,W
	btfss   _C
	goto    Label
	endm

jmpWgeF macro   Reg,Label
	subwf   Reg,W
	btfss   _C
	goto    Label
	btfsc   _Z
	goto    Label
	endm

jmpWeqF macro   Reg,Label
	subwf   Reg,W
	btfsc   _Z
	goto    Label
	endm

jmpWneF macro   Reg,Label
	subwf   Reg,W
	btfss   _Z
	goto    Label
	endm

jmpWleF macro   Reg,Label
	subwf   Reg,W
	btfsc   _C
	goto    Label
	endm

jmpWltF macro   Reg,Label
	subwf   Reg,W
        skipC
        bsf     _Z
	jmpNZ	Label
	endm


jmpClr  macro Reg,Bit,Label

	btfss   Reg,Bit
	goto    Label
	endm

jmpSet  macro Reg,Bit,Label
	btfsc   Reg,Bit
	goto    Label
	endm

jmpZ    macro Label
	btfsc   _Z
	goto    Label
	endm

jmpNZ   macro Label
	btfss   _Z
	goto    Label
	endm

jmpC    macro Label
	btfsc   _C
	goto    Label
	endm

jmpNC   macro Label
	btfss   _C
	goto    Label
	endm

skipClr macro Reg,Bit
	btfsc   Reg,Bit
	endm

skipSet macro Reg,Bit
	btfss   Reg,Bit
	endm

skipNZ  macro
	btfsc   _Z
	endm

skipZ   macro
	btfss   _Z
	endm

skipNC  macro
	btfsc   _C
	endm

skipC   macro
	btfss   _C
	endm

toggle  macro Reg,Bit
        local    SLabel,Label
	btfss   Reg,Bit
        goto    SLabel
        bcf     Reg,Bit
        goto    Label
SLabel  bsf     Reg,Bit
Label   
        endm        


tb2tb macro RegS,BitS,RegD,BitD
          local     jLab1,jLab2
          jmpSet    RegS,BitS,jLab1
          bcf       RegD,BitD
          goto      jLab2
jLab1     bsf       RegD,BitD
jLab2
          endm

tb2Nottb macro RegS,BitS,RegD,BitD
          local     jLab1,jLab2
          jmpClr    RegS,BitS,jLab1
          bcf       RegD,BitD
          goto      jLab2
jLab1     bsf       RegD,BitD
jLab2
          endm
