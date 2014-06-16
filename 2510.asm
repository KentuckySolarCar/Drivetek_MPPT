;**********************************************************************
;   P R O G R A M M	MPPTnG                                        *
;                                                                     *
;   Traking program for MPPT new generation                           *
;**********************************************************************
;                                                                     *
;    Filename:	    2510.asm                                          *
;    Date:          20.11.00                                          *
;    Last Update:   19.09.02                                          *
;    File Version:  V5.0                                              *
;                                                                     *
;    Author:        Michael Zürcher			              *
;                                                                     *
;    Company:       HTA-Biel/Bienne Indulab                           *
;                                                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;    - Main program : mpptngV5.asm                                    *
;                                                                     *
;**********************************************************************


#define	RESET2510	0xC0		; MCP2510 reset instruction
#define	READ2510	0x03		; MCP2510 read instruction
#define	WRITE2510	0x02		; MCP2510 write instruction
#define	RTS2510		0x80		; MCP2510 request to send instruction
#define	STATUS2510	0xA0		; MCP2510 read status instruction
#define	BITMODIFY2510	0x05		; MCP2510 bit modify instruction


;*******************************************************************
;                 LOCAL MACROS                                 
;*******************************************************************

;----------------------------------------------------------------------
;		WRITE literal byte to MCP2510 register
;
;		IN: Reg		register address
;		    LitData	data to write in the register
;----------------------------------------------------------------------
SPI_WriteL	MACRO	Reg,LitData
		movlw	LitData
		movwf	RegData2510
		movlw	Reg
		call	Write2510
		ENDM

;----------------------------------------------------------------------
;		WRITE data byte to MCP2510 register
;
;		IN: Reg		register address
;		    RegData	data to write in the register
;----------------------------------------------------------------------
SPI_WriteD	MACRO	Reg,RegData
		movf	RegData,W
		movwf	RegData2510
		movlw	Reg
		call	Write2510
		ENDM


;**********************************************************************
;		INIT MCP2510 CAN-Controller
;
;		Physical layer configuration:
;		- Fosc       = 20 MHz
;		- BRP        = 10
;		- Sync Seg   = 1 Tq
;		- Prop Seg   = 2 Tq
;		- Phase Seg1 = 3 Tq
;		- Phase Seg2 = 3 Tq
;		- SJW        = 1 Tq
;		- Bus line is sampled once at the sample point
;		- wake-up filter disable
;**********************************************************************

Init2510	call	Reset2510

		movlw	B'00000011'	; mask bit CLKOUT
		movwf	RegMask2510
		movlw	B'00000010'	; CLKOUT pin enable / clk:4
		movwf	RegData2510
		movlw	CANCTRL		; CAN control register of MCP2510
		call	BitMod2510

		SPI_WriteL CNF1,B'00000100'	; config register 1 of MCP2510 (Bitiming)

		SPI_WriteL CNF2,B'10001110'	; config register 2 of MCP2510

		SPI_WriteL CNF3,B'00000101'	; config register 3 of MCP2510

		SPI_WriteL CANINTE, B'00000000' ; int on RX0 full
						; no int on TX0/1/2 empty  
						; no int on Message error/Wakeup/EFLG error


;***********************************************************************
;   Configure TX
;***********************************************************************
		SPI_WriteL TXB0CTRL,B'00000011'	; TX0 has Highest Message Priority
		SPI_WriteL TXB1CTRL,B'00000010'	; TX1 has High Intermediate Message Priority
		SPI_WriteL TXB2CTRL,B'00000001'	; TX2 has Low Intermediate Message Priority

		SPI_WriteL TXRTSCTRL,B'00000000'	; all TXRTS pins are only digital inputs
		
		SPI_WriteD TXB0SIDH,IDTrackerTXH; Identifier High, Low is individual for each TX buffer		
		SPI_WriteD TXB0SIDL,IDTrackerTXL; Identifier Low for TX0

		SPI_WriteL TXB1SIDH,0x00	; Identifier High, Low is individual for each TX buffer			
		SPI_WriteL TXB1SIDL,0x00	; Identifier Low for TX1, never used	

		SPI_WriteL TXB2SIDH,0x00	; Identifier High, Low is individual for each TX buffer			
		SPI_WriteL TXB2SIDL,0x00	; Identifier Low for TX1, never used	
		
		SPI_WriteL TXB0DLC,0x08		; Data Frame of TX0 has a lenght of 8 Bytes		
		SPI_WriteL TXB1DLC,0x06		; Data Frame of TX1 has a lenght of 6 Bytes
		
;TX Buffers are not cleared here!	
;***********************************************************************
;   Configure RX
;***********************************************************************
		SPI_WriteL RXB0CTRL,B'00000000'	; B0 filter enabled, receive standart and extended frames
		SPI_WriteL RXB1CTRL,B'00000000'	; B1 filter enabled

		SPI_WriteL BFPCTRL,B'00000000'	; disable RX1BF/RX0BF pin
		
;***********************************************************************
;   RX Filter and Masks
;***********************************************************************

		SPI_WriteL RXM0SIDH,B'11111111'	; acceptance filter mask 0 high
		SPI_WriteL RXM0SIDL,B'11100000'	; acceptance filter mask 0 low
				
		SPI_WriteD RXF1SIDH,IDTrackerRXH; acceptance filter 1 high
		SPI_WriteD RXF1SIDL,IDTrackerRXL; acceptance filter 1 low
		
		SPI_WriteD RXF0SIDH,IDTrackerRXH; acceptance filter 0 high
		SPI_WriteD RXF0SIDL,IDTrackerRXL; acceptance filter 0 low
		
		SPI_WriteL RXM1SIDH,B'11111111'	; acceptance filter mask 1 high
		SPI_WriteL RXM1SIDL,B'11100000'	; acceptance filter mask 1 low

		SPI_WriteL RXF2SIDH,B'00000000'	; acceptance filter 2 high
		SPI_WriteL RXF2SIDL,B'00000000'	; acceptance filter 2 low

		SPI_WriteL RXF3SIDH,B'00000000'	; acceptance filter 3 high
		SPI_WriteL RXF3SIDL,B'00000000'	; acceptance filter 3 low

		SPI_WriteL RXF4SIDH,B'00000000'	; acceptance filter 4 high
		SPI_WriteL RXF4SIDL,B'00000000'	; acceptance filter 4 low

		SPI_WriteL RXF5SIDH,B'00000000'	; acceptance filter 5 high
		SPI_WriteL RXF5SIDL,B'00000000'	; acceptance filter 5 low

;***********************************************************************
;   Errors and Interupts
;***********************************************************************

		SPI_WriteL	CANINTE,B'00000001'	; enable RX0 Buffer Interupt
				
		call	NormalMode2510

		RETURN


;**********************************************************************
;		RESET Internal registers to default state
;
;		NOTE: - automatically put MCP2510 in configuration mode
;		      data format under SPI bus
;		      SI pin -> instruction
;		      SO pin ->    ---
;**********************************************************************

Reset2510	call	InitSPIBuf

		movlw	RESET2510
		call	LoadSPIByte	; reset MCP2510

		call	ExchangeSPI	; start SPI transaction
		call	WaitSPIExchange	; wait SPI transaction complete

		movlw	0x25		; wait 37us
		call	wait

		RETURN


;**********************************************************************
;		READ data from register beginning at selected address
;
;		IN: w			address of the register to be readed
;		    RegAdr2510		temp to hold address
;
;		NOTE: data format under SPI bus
;		      SI pin -> instruction / address / ---
;		      SO pin ->    ---      /   ---   / data
;**********************************************************************
Read2510	movwf	RegAdr2510	; hold address

		call	InitSPIBuf	; init SPI buffer

		movlw	READ2510	; MCP2510 instruction
		call	LoadSPIByte

		movf	RegAdr2510,W	; MCP2510 address
		call	LoadSPIByte

		movlw	1		; Expect 1 byte answer
		call	LoadSPIZeros

		call	ExchangeSPI	; send via SPI bus
		call	WaitSPIExchange	; wait transmission to be complete

		movf	SPIBufBase+2,W	; store answer in SPI buffer

		RETURN


;**********************************************************************
;		WRITE data to register beginning at selected address
;
;		IN: w			address of the register to be readed
;		    RegAdr2510		temp to hold address
;		    RegData2510		data sent/receive register
;
;		NOTE: data format under SPI bus
;		      SI pin -> instruction / address / data
;		      SO pin ->    ---      /   ---   / ---
;**********************************************************************
Write2510	movwf	RegAdr2510	; hold address

		call	InitSPIBuf	; init SPI buffer

		movlw	WRITE2510	; MCP2510 instruction
		call	LoadSPIByte

		movf	RegAdr2510,W	; MCP2510 address
		call	LoadSPIByte

		movf	RegData2510,W	; Expect 1 byte answer
		call	LoadSPIByte

		call	ExchangeSPI	; send via SPI bus
		call	WaitSPIExchange	; wait transmission to be complete

		RETURN


;**********************************************************************
;		RTS Send the request to send instruction to the CAN-Bus
;		Controller with value in w (ORed)
;
;		- Sets TXBnCTRL
;		- TXREQ bit for one or more transmit buffers
;
;		IN: w			address of the register to be readed
;		    RegAdr2510		temp to hold address
;		    RegData2510		data sent/receive register
;
;		NOTE: data format under SPI bus
;		      SI pin -> instruction (10000nnn)
;		      SO pin ->    ---
;**********************************************************************
Rts2510		movwf	RegData2510	; hold address

		call	InitSPIBuf	; init SPI buffer

		movlw	RTS2510		; MCP2510 instruction
		iorwf	RegData2510,W	; get data and OR it with RTS
		call	LoadSPIByte

		call	ExchangeSPI	; send via SPI bus
		call	WaitSPIExchange	; wait transmission to be complete

		RETURN


;**********************************************************************
;		GET STATUS bits for transmit/receive functions 
;
;		NOTE: data format under SPI bus
;		      SI pin -> instruction /  ---   /     ---
;		      SO pin ->    ---      /  data  / repeat data
;**********************************************************************
Status2510	call	InitSPIBuf	; init SPI buffer

		movlw	STATUS2510	; MCP2510 instruction
		call	LoadSPIByte

		movlw	1		; Expect 1 byte answer
		call	LoadSPIZeros

		call	ExchangeSPI	; send via SPI bus
		call	WaitSPIExchange	; wait transmission to be complete

		RETURN


;**********************************************************************
;		MODIFY BIT IN REGITERS OF MCP2510 CAN-Controller 
;
;		IN: reg W		address of the register to be modified
;		    RegAdr2510		temp to hold address
;		    RegMask2510		mask register
;		    RegData2510		data sent/receive register
;
;		NOTE: data format under SPI bus
;		      SI pin -> instruction / address / mask / data
;		      SO pin -> ---
;**********************************************************************
BitMod2510	movwf	RegAdr2510	; hold address

		call	InitSPIBuf	; init SPI buffer

		movlw	BITMODIFY2510	; MCP2510 instruction
		call	LoadSPIByte

		movf	RegAdr2510,W	; MCP2510 address
		call	LoadSPIByte

		movf	RegMask2510,W	; MCP2510 mask
		call	LoadSPIByte

		movf	RegData2510,W	; MCP2510 data
		call	LoadSPIByte

		call	ExchangeSPI	; send via SPI bus
		call	WaitSPIExchange	; wait transmission to be complete

		RETURN


;**********************************************************************
;		SET NORMAL MODE OF MCP2510 CAN-Controller 
;
;		NOTE: - Set normal operation mode
;		      - CLKOUT pin disable
;**********************************************************************
NormalMode2510	movlw	B'11100000'	; mask bits
		movwf	RegMask2510
		movlw	B'00000000'	; Set Normal Mode
		movwf	RegData2510
		movlw	CANCTRL		; CAN control register of MCP2510
		call	BitMod2510

		movlw	0x00	
		movwf	NormalModeCounter
		
WaitNormal	incf	NormalModeCounter,f
		movlw	CANSTAT
		call	Read2510
		andlw	0xE0
		btfsc	_Z
		  goto	Ret
		jmpFneL	NormalModeCounter,0xFF,WaitNormal		

Ret		nop
		RETURN


