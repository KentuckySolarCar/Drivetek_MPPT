;**********************************************************************
;   				                                      *
;                                                                     *
;   Macros for MPPTnG Version 2.0		                      *
;**********************************************************************
;                                                                     *
;    Filename:	    mpptng.inc                                        *
;    Date:          30.04.01                                          *
;    Last Update:   18.09.01                                          *
;    File Version:  V1.0                                              *
;                                                                     *
;    Author:        Michael Zürcher                                   *
;                                                                     *
;    Company:       HTA-Biel/Bienne Indulab                           *
;                                                                     *
;    Changes:       separate const include file with V3.0             *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;    - Main program : mpptng.asm                                      *
;                                                                     *
;**********************************************************************

;**********************************************************************
;		General Flags Definition
;**********************************************************************
#define	CAN_TxMsg	GenFlags,7	; xmit next CAN message bit
#define	CANTxRq		GenFlags,6	; xmit next CAN message bit
#define	Initialized	GenFlags,5
#define	BVLR		GenFlags,3	; Battery Voltage Level Reached Flag
#define	OVT		GenFlags,2	; Over Temp Flag
#define	NOC		GenFlags,1	; No Charge Flag
#define	UNDV		GenFlags,0	; Under Voltage Flag


;**********************************************************************
;		PIN DEFINITIONS
;**********************************************************************
; CAN control
#define CAN_CS		PORTD,5		; Chip-Select for MCP2510
#define CAN_PRE		PORTB,2		; Voltage present on MCP2510
#define CAN_TIME	0x04		; send CAN msg every 4 tacking cycles

; Security
#define INT_OVH		PORTB,3		; OverHeat interrupt
#define INT_NOC		PORTB,4		; NoCharge interrupt
#define INT_UNDV	PORTB,5		; UnderVoltage interrupt

#define RES_OVH		PORTD,7		; Reset OverHeat
#define RES_NOC		PORTD,6		; Reset NoCharge

#define REDLED		PORTD,4		; Red LED, "1"= led on

; Converter
#define INV_MOS_ENA	PORTB,1		; Enable High-Side FET switching
#define ENA_FET		PORTC,0		; Enable FET switching


;**********************************************************************
;		Adress DEFINITIONS
;**********************************************************************
; these variables are mirrored at all of the four memory banks.
; therefore, there's no need to switch to the accurate bank			

Temp0		EQU 0x71
Temp1		EQU 0x72
Temp2		EQU 0x73
Temp3		EQU 0x74
Temp4		EQU	0x76
Temp5		EQU	0x77
Waitboost	EQU 0x75

COUNTERA	EQU 0x7A	; counter A
COUNTERB	EQU 0x7B	; counter B
COUNTERC	EQU 0x7C	; counter C
CAN_COUNTER	EQU 0x7D	; CAN counter

; Storage for interrupt service routine
IntSaveW	EQU 0x7F	; save W (bank 0-3)

;**********************************************************************
;		ADC DEFINITIONS (Constants)
;**********************************************************************
#define INIT_IO_AD	B'10000001'	; consider "ports config"
;
; Tacq = 2us + (-1)*120pF * (1k + 7k)*ln(1/2047)+(60°C-25°C)(0.05us/°) = 11.6us
;
#define Tacq		0x0C		; ADConverter aquisition time (64_us)
#define CHANNEL0	B'10000000'	; Selector for (RA0/AN0)
#define CHANNEL1	B'10001000'	; Selector for (RA1/AN1)
#define CHANNEL2	B'10010000'	; Selector for (RA2/AN2)
#define CHANNEL4	B'10100000'	; Selector for (RA5/AN4)
#define CHANNEL5	B'10101000'	; Selector for (RE0/AN5)
#define CHANNEL6	B'10110000'	; Selector for (RE1/AN6)

;**********************************************************************
;		Port config DEFINITIONS (Constants)
;**********************************************************************
#define	INIT_IO_A	B'00101111'	; consider "ports config" RA4= Output
#define INIT_IO_B	B'00111101'	; '0' = output, 
#define INIT_IO_C	B'10010000'	; '1' = input
#define INIT_IO_D	B'00001111'	;
#define INIT_IO_E	B'00000111'	;


;**********************************************************************
;		SPI DEFINITIONS (Constants)
;**********************************************************************
#define INIT_SPI	B'00010010'	; SPI Master, Clock idle high, Fosc/64, no collision
;**********************************************************************
;		CAN DEFINITIONS (Constants)
;**********************************************************************
#define TXBASEADR	0xEE	
#define RXBASEADR	0xE2	


;**********************************************************************
;		PWM DEFINITIONS (Constants)
;**********************************************************************
#define DUTY2_MIN_H	0x0E		; Min corresponding to 3us
#define DUTY2_MIN_L	0xE7

#define PERIODE		0xCF		; PWMs periode 24kHz
#define AUX_PW		0x06		; Width of aux Pulse

#define BIGSTEP_H	0x04		; duty step high byte (xxxx xxxx)
#define BIGSTEP_L	0x00		; duty step  low byte (xx00 0000)

#define SMALLSTEP_H	0x02		; duty step high byte (xxxx xxxx)
#define SMALLSTEP_L	0x00		; duty step  low byte (xx00 0000)

#define MAXTCH		0x02		; max permitted cooler (0000 00xx)
#define MAXTCL		0xBB		; temperature          (xxxx xxxx)

;********************************************************************
;		LOCAL REGISTER STORAGE (VARIABLES)
;********************************************************************
	CBLOCK   	0x20		; bank 0 variables

	UI0H				; ADChannel 0 (current Umes_in) value high byte
	UI0L				; ADChannel 0 (current Umes_in) value low byte
	UI1H				; ADChannel 0 (former Umes_in) value high byte
	UI1L				; ADChannel 0 (former Umes_in) value low byte
	UI2H				; ADChannel 0 (Umes_in) value high byte
	UI2L				; ADChannel 0 (Umes_in) value low byte
	UI3H				; ADChannel 0 (Umes_in) value high byte
	UI3L				; ADChannel 0 (Umes_in) value low byte
	UIF0H				; Current averaged (UIN) high byte
	UIF0L				; Current averaged (UIN) low byte
	UIF1H				; Former averaged (UIN) high byte
	UIF1L				; Former averaged (UIN) low byte


	UO0H				; ADChannel 1 (current Umes_out) value high byte
	UO0L				; ADChannel 1 (current Umes_out) value low byte
	UO1H				; ADChannel 1 (former Umes_out) value high byte
	UO1L				; ADChannel 1 (former Umes_out) value low byte
	UO2H				; ADChannel 1 (Umes_out) value high byte
	UO2L				; ADChannel 1 (Umes_out) value low byte
	UO3H				; ADChannel 1 (Umes_out) value high byte
	UO3L				; ADChannel 1 (Umes_out) value low byte
	UOFH				; Averaged (UOUT) high byte
	UOFL				; Averaged (UOUT) low byte
	
	II0H				; ADChannel 2 (current Imes_in) value high byte
	II0L				; ADChannel 2 (current Imes_in) value low byte
	II1H				; ADChannel 2 (former Imes_in) value high byte
	II1L				; ADChannel 2 (former Imes_in) value low byte
	II2H				; ADChannel 2 (Imes_in) value high byte
	II2L				; ADChannel 2 (Imes_in) value low byte
	II3H				; ADChannel 2 (Imes_in) value high byte
	II3L				; ADChannel 2 (Imes_in) value low byte
	IIF0H				; Current averaged (IIN) high byte
	IIF0L				; Current averaged (IIN) low byte
	IIF1H				; Former averaged (IIN) high byte
	IIF1L				; Former averaged (IIN) low byte

	TAMBH				; ADChannel 4 (Temp_amb) value high byte
	TAMBL				; ADChannel 4 (Temp_amb) value low byte

	USENSEH				; ADChannel 5 (Uout_sense) value high byte
	USENSEL				; ADChannel 5 (Tout_sense) value low byte

	TCH				; ADChannel 6 (Temp_cooler) value high byte
	TCL				; ADChannel 6 (Temp_cooler) value low byte

	PI0H				; Current filtered input power value (MSB)
	PI0M				; Current filtered input power value (middle)
	PI0L				; Current filtered input power value (LSB)
	PI1H				; Former filtered input power value (MSB)
	PI1M				; Former filtered input power value (middle)
	PI1L				; Former filtered input power value (LSB)

	DUTY2_H				; PWM2 Duty cycle value high byte
	DUTY2_L				; PWM2 Duty cycle value low byte

	IDTrackerTXH			; response ID for Tracker high byte
	IDTrackerTXL			; response ID for Tracker low byte
	IDTrackerRXH			; ID for Tracker high byte
	IDTrackerRXL			; ID for Tracker low byte


	SPICounter			; number of byte remaining te receive
	SPIBufPointer			; pointer into buffer
	SPIBufBase:12			; start of SPI buffer (12 bytes)

	RegData2510			; data sent/receive register for MCP2510
	RegAdr2510			; address register for MCP2510
	RegMask2510			; bit Mask register for MCP2510

	IntSaveSt			; save STATUS
	IntSaveFSR			; save FSR
	IntSavePCLATH			; save PCLATCH

	GenFlags			; General Control Flags
	NormalModeCounter
	ENDC

	CBLOCK			0xA0

	VSF				; Voltage Signum Flags
	PSF				; Power Signum Flags

	PminCounter			;

	STEP_H				; H-Byte of Delta f()=Uin
	STEP_L				; L-Byte of Delta f()=Uin

	ENDC




