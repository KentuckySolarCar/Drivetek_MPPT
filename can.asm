;**********************************************************************
;   P R O G R A M M	MPPTnG                                        *
;                                                                     *
;   Traking program for MPPT new generation                           *
;**********************************************************************
;                                                                     *
;    Filename:	    can.asm                                           *
;    Date:          15.11.00                                          *
;    Last Update:   18.10.00                                          *
;    File Version:  V3.0                                              *
;                                                                     *
;    Author:        Michael Zürcher			              *
;                                                                     *
;    Company:       HTA-Biel/Bienne Indulab                           *
;                                                                     *
;    Changes:       separate CAN handling programm with V3.0          *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;    - Main program : mpptngV4.asm                                    *
;                                                                     *
;**********************************************************************

InitCAN		bsf	CAN_CS		; deselect CAN Controller

;**********************************************************************
;		INIT CAN MODULE
;**********************************************************************



		;read the DIP-switches and attribut IDTracker

		clrf	IDTrackerTXL
		
		movlw	TXBASEADR
		movwf	IDTrackerTXH
		btfsc	PORTD,3
		   incf	   IDTrackerTXH,F	
		
		movlw	RXBASEADR
		movwf	IDTrackerRXH
		btfsc	PORTD,3
		   incf	   IDTrackerRXH,F	

		movf	PORTD,W		; read switches
		andlw	B'00000111'
		bcf	_C
		movwf	IDTrackerTXL
		rlf	IDTrackerTXL,F	; shift left four positions
		rlf	IDTrackerTXL,F
		rlf	IDTrackerTXL,F
		rlf	IDTrackerTXL,F
		rlf	IDTrackerTXL,F
		movf	IDTrackerTXL,W
		movwf	IDTrackerRXL	

				
		call	InitSPIPort	; Initialize SPI-Bus


		; Wait 40 ms for 2510 to initialize ( there is no significance to 40 ms,
		; we just selected a large time since time is not critical)

		call	wait20ms
		call	wait20ms

		call	Init2510		; Initialize CAN-Controller MCP2510
		

;*******************************************************************************
; configure and enable RB0/INT
;*******************************************************************************

		movf	OPTION_REG_P,W	; read Option Register
		andlw	B'10111111'	; Interupt on falling edge of RB0/INT pin
		movwf	OPTION_REG_P	; 

		RETURN

;**********************************************************************
;		Update TX0 Buffer
;
;		Frame type   -> Data Frame
;		ID type      -> Standart
;		Frame Format ->	SOF / ID / control / datas / CRC / EOF
;		Data Format  ->	Byte0 : UinH
;				Byte1 : UinL
;				Byte2 : IinH
;				Byte3 : IinL
;				Byte4 : UoutH
;				Byte5 : UoutL
;				Byte6 : TambH
;				Byte7 : TambL
;**********************************************************************

UpdateTX0	SPI_WriteL TXB0DLC,0x07		; 7 bytes to send
		
		movf	GenFlags,W		; add GenFlags to UinH Byte
		andlw	B'00001111'
		movwf	Temp0
		bcf	_C
		rlf	Temp0,F
		rlf	Temp0,F
		rlf	Temp0,F
		rlf Temp0,F
		movfw	UIF0H
		andlw	B'00000011'
		movwf	UIF0H
		movfw	Temp0
		addwf	UIF0H,W
		movwf	Temp0
		SPI_WriteD TXB0D0,Temp0
		SPI_WriteD TXB0D1,UIF0L
		SPI_WriteD TXB0D2,IIF0H
		SPI_WriteD TXB0D3,IIF0L	
		SPI_WriteD TXB0D4,UOFH 
		SPI_WriteD TXB0D5,UOFL	
	
		call 	GetTamb
		call	ConvTempAmb
		movwf	TAMBL
		SPI_WriteD TXB0D6,TAMBL	

;		call 	GetTCooler
;		call	ConvTempCooler
;		movwf	TCL
;		SPI_WriteD TXB0D7,TCL	
		
		RETURN

;**********************************************************************
;  Send content of TX0 Buffer on CAN Bus
;**********************************************************************

SendCANTX0	clrwdt				; reset watchdog
		movlw	B'00001000'		; mask bit TXREQ (msg transmit request)
		movwf	RegMask2510
		movlw	TXB0CTRL		; transmit buffer1 control register
		call	Read2510
		andwf	RegMask2510,W		; test TXREQ bit
		btfss	STATUS,Z		; wait until TXREQ = 0 (wait for pending msg to be sent)
		   goto	   SendCANTX0	
		movlw	RTS0			; transmit buffer Tx0
		call	Rts2510

		RETURN

;**********************************************************************
;		CAN Interrupt Handling routine
;**********************************************************************
IntCAN		bsf	CANTxRq
		bcf	INTCON,INTF
		bcf	INTCON,INTE		
		goto	IntReturn

;**********************************************************************
;		Send Data Over CAn if requested
;**********************************************************************
CANRqTest	btfss   Initialized
		   RETURN
		btfss	CAN_PRE		; skip next line if CAN_PRE = 0
		   RETURN
		movf	PORTD,W		; read A0-A3
		andlw	B'00001111'	; mask A0-A3 Bits
		btfsc	_Z	
		   RETURN	
;		btfss	CANTxRq	
;	           RETURN	
		movlw	CANINTF
		call	Read2510
		movwf	Temp4
		btfss	Temp4,0
			RETURN		

		call	GetFilteredIin				; get actual values
		call	GetFilteredUout
		call	GetFilteredUin
;		call	GetTCooler
		call	GetTamb

		call 	UpdateTX0
		call	SendCANTX0

		SPI_WriteL CANINTF,B'00000000'

		movlw	CANINTF
		call 	Read2510
		nop
		bcf	INTCON,INTF
		bsf	INTCON,INTE
		bcf	CANTxRq
		RETURN
	



