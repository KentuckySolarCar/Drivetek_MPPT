;**********************************************************************
;   P R O G R A M M	MPPTnGv4                                          *
;                                                                     *
;   Traking program for MPPT new generation Version 3                 *
;**********************************************************************
;                                                                     *
;    Filename:	    mpptngv6.asm                                      *
;    Date:          15.11.00                                          *
;    Last Update:   16.2.05                                           *
;    File Version:  V4.0                                              *
;                                                                     *
;    Author:        Michael Zürcher, Christoph Raible                 *
;                              					                      *
;    Company:       HTA-Biel/Bienne Indulab, drivetek ag                           *
;                                                                     *
;    Changes:       Adated for redesigned HW V3.0		              *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Files required:                                                  *
;                                                                     *
;    - P16f877.INC	Basic includes                                    *
;    - MCP2510.INC                                                    *
;    - MACROS16.INC                                                   *
;    - USER.INC                                                       *
;    - ADC.ASM                                                        *
;    - CAN.ASM                                                        *
;    - CHARGE.ASM                                                     *
;    - INTERPT.ASM                                                    *
;    - INIT.ASM                                                       *
;    - NOLOAD.ASM                                                     *
;    - PWM.ASM                                                        *
;    - SPI.ASM                                                        *
;    - TEMP.ASM                                                       *
;    - TRACK.ASM                                                      *
;    - CELSIUS.ASM                                                    *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;                                                                     *
;    - Program written for Flash PIC16F877                            *
;    - Programming via ICSP                                           *
;    - Clock Frequency 20MHz                                          *
;                                                                     *
;**********************************************************************


		list p=16f877		    ; list directive to define processor
#include	"P16F877.INC"		; processor specific variable definitions
#include	"MCP2510.INC"		; defs for CANbus Controller
#include	"MACROS16.INC"		; basic Macros for PIC16 Series
#include	"MPPTNGV6.INC"		; mpptng definitions
#include	"USER23.INC"	     	; user defined constants 

	__CONFIG _CP_OFF & _WRT_ENABLE_ON & _CPD_OFF & _LVP_OFF & _BODEN_OFF & _PWRTE_ON & _WDT_ON & _HS_OSC

;----------------------------------------------------------------------
;                                                                     -
;    Configuration word __CONFIG (adress 2007h) :                     -
;                                                                     -
;    - _CP_OFF		: Flash Programm Memory Code Protection             -
;    - _WRT_ENABLE_ON	: Flash Programm Memory Write Enable          -
;    - _CPD_OFF		: Data EE Memory Code Protection                 -
;    - _LVP_OFF		: Low Voltage ICSP Enable bit                    -
;    - _BODEN_OFF	: Brown-out Reset Enable bit                        -
;    - _PWRTE_ON	: Power-up Timer Enable bit                         -
;    - _WDT_OFF		: Watchdog Timer Enable bit                      -
;    - _HS_OSC		: HS oscillator                                     -
;                                                                     -
;----------------------------------------------------------------------

	errorlevel -302


;**********************************************************************
;		RESET VECTOR
;**********************************************************************
		ORG	0x00			; processor reset vector
		nop					; for ICD
		goto	Main		; go to beginning of program


;********************************************************************
;		Include Sub-program
;********************************************************************

#include	"interpt.asm"		; interrupt routine
#include	"adc.asm"			; adc routine

#include	"2510.asm"			; 2510 routine
#include	"init.asm"			; init routine

#include	"can.asm"			; can network routine
#include	"pwm.asm"			; PWM Modules routine
#include	"spi.asm"			; SPI routine
#include	"track.asm"			; tracking routine
;Temperature Procedure
#include	"celsius.asm"		; Converts temperatures to degs C

;Special States
#include	"charge.asm"		; charge output caps routine
#include	"noload.asm"		; no load at output
#include	"underv.asm"		; 
#include	"minpower.asm"		; 
#include	"constv.asm"		; 
#include	"overtemp.asm"		; 


;**********************************************************************
;		Initialization 
;**********************************************************************

Main	call 	Init			; Initialize PICmicro
		
		call	InitADC			; Initialize A/D Converters

		btfss	CAN_PRE			; skip next line if CAN_PRE = 0
		goto    monOVC1
		movf	PORTD,W			; read A0-A3
		andlw	B'00001111'		; mask A0-A3 Bits
		btfsc	_Z	
	    goto	monOVC1
        call	InitCAN			; Initialize SPI-Bus & CAN module

		movlw	CAN_TIME
		movwf	CAN_COUNTER		; load CAN counter
		bcf	INTCON,INTF	   ; clear all eventual interrupts
		bsf	INTCON,INTE	   ; enable INT/RB0 (CAN INT.)
		bsf	Initialized		; PIC initialized
		bsf	NOC				; before initialized set No battery connectet, undervoltage, ocer temp.
		bsf	UNDV
		bsf OVT
		bcf	BVLR
;----------------------------------------------------------------------
; No Charge
;----------------------------------------------------------------------

monOVC1		call	UpdateCAN
			call	wait20ms

			clrwdt					; reset watchdog

			call	GetUout
		
			movf	UO0H,W
			sublw	MAXUOH			;MAXUOH-UOFH

			btfsc	_Z
			goto  	LowByte1

			btfsc	_C
			goto	Reset_NOC1
	
			goto  	monOVC1

LowByte1	movlw	MAXUOL
			subwf	UO0L,W
			btfsc	_C
			goto	monOVC1

Reset_NOC1	bcf	RES_NOC				; Reset NoCharge-Flip-Flop
			call	wait20ms
			bsf	RES_NOC


;----------------------------------------------------------------------
; Overheat
;----------------------------------------------------------------------

OVH_LOOP1	bcf	RES_OVH			; Reset OVH-Flip-Flop
			call	wait20ms
			bsf	RES_OVH

;----------------------------------------------------------------------

PWM			call	InitPWM		; Initialize PWMs modules
				            	; PWM signal remain "off"
;----------------------------------------------------------------------
; Input low voltage
;----------------------------------------------------------------------
			call	UnderVoltage
;----------------------------------------------------------------------
; PreCharge
;----------------------------------------------------------------------		
		
			call	PreCharge	

;----------------------------------------------------------------------
; Reset the Pmin Counter
;----------------------------------------------------------------------
			BANK1
			clrf	PminCounter
			BANK0
;**********************************************************************
;		State Machine
;**********************************************************************
State	
			goto	TrackingLoop

			END			   		; directive 'end of program'


