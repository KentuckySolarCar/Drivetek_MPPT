;**********************************************************************
;   P R O G R A M M	MPPTnG                                        *
;                                                                     *
;   Traking program for MPPT new generation                           *
;**********************************************************************
;                                                                     *
;    Filename:	    spi.asm                                           *
;    Date:          15.11.00                                          *
;    Last Update:   26.4.00                                           *
;    File Version:  V3.0                                              *
;                                                                     *
;    Author:        Vezzini A. / M. Lehmann / F. Kaufmann             *
;                                                                     *
;    Company:       HTA-Biel/Bienne Indulab                           *
;                                                                     *
;    Changes:       placed interrupt routine in the same file         *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;    - Main program : mpptng.asm                                      *
;                                                                     *
;**********************************************************************

;**********************************************************************
;		INIT SPI PORT
;
;		SPI Master, Idle high, Fosc/4, no collision
;**********************************************************************

InitSPIPort	bcf	SSPCON,SSPEN	; disable SPI Module

		movlw	INIT_SPI	; init SPI
		movwf	SSPCON

		bsf	SSPCON,SSPEN	; enable SPI Module

		bcf	PIR1,SSPIF	; clear interrupt flag

		bcf	SSPSTAT,SMP	; input data sampled at middle
		bcf	SSPSTAT,CKE	; transmit happens on transition idle to active clock

		BANK1
		bsf	PIE1_P,SSPIE	; SSP interrupt enable
;		bcf	PIE1_P,SSPIE	; SSP interrupt disable
		BANK0

		RETURN


;**********************************************************************
;		START SPI TRANSACTION
;
;		- Get number of bytes to exchange
;		- Load 1st byte to begin exchange
;**********************************************************************

ExchangeSPI	movf	FSR,W
		movwf	SPICounter	; load number of byte in SPICounter

		movlw	SPIBufBase	;
		subwf	SPICounter,F	; get number of byte
		btfsc	STATUS,Z
		  RETURN		; skip if Z not 0 (nothing to exchange)

		movlw	SPIBufBase
		movwf	SPIBufPointer

		bcf	CAN_CS		; select chip MCP2510
		movf	SPIBufBase,W	; load 1st byte from buffer
		movwf	SSPBUF		; sent in SPI bus

		RETURN


;**********************************************************************
;		WAIT SPI TRANSACTION TO BE COMPLETE
;**********************************************************************

WaitSPIExchange	clrwdt			; reset watchdog
		movf	SPICounter,F
		btfss	STATUS,Z
		  goto	WaitSPIExchange
		RETURN


;**********************************************************************
;		LOAD NUMBER OF ZERO BYTE IN W TO SPI BUFFER
;
;		IN: W	Number of zero byte to load
;			Assumes FSR is pointer
;**********************************************************************

LoadSPIZeros	andlw	0xFF
		btfsc	STATUS,Z	; test if number is 0
		   RETURN

		clrwdt			; reset watchdog		

		clrf	INDF
		incf	FSR,F
		addlw	0xFF
		btfss	STATUS,Z
		   goto	   LoadSPIZeros
		
		RETURN


;**********************************************************************
;		LOAD BYTE IN W TO SPI BUFFER
;
;		IN: W	Byte (i.e. instruction) to load
;			Assumes FSR is pointer
;**********************************************************************

LoadSPIByte	movwf	INDF		; Indirect addressing	
		incf	FSR,F
		RETURN


;**********************************************************************
;		INIT SPI BUFFER
;
;		Load FSR with start adress of SPI Buffer
;**********************************************************************

InitSPIBuf	clrf	SPICounter
		movlw	SPIBufBase
		movwf	SPIBufPointer	; set pointer at start of buffer
		movwf	FSR		; set FSR at start of buffer
		RETURN


;**********************************************************************
;		INTSPI (SPI interrupt)
;
;		Occured when a byte is transmit/received in the SSBUF
;
;		One single buffer (at SPIBufBase) is used for SPI
;		receive and transmit. When a byte is removed from the
;		buffer to transmit, it is replaced by the byte received.
;
;		The buffer pointer (SPIBufPointer) points to the last
;		byte loaded for transmission. This is the location that
;		the received byte will be stored.
;
;		The counter (SPICounter) contains the number of byte
;		remaining to be received. This is one less then the number
;		remaining to be transmited. When SPICounter reaches zero,
;		the transaction is complete.
;**********************************************************************

IntSPI		bcf	PIR1,SSPIF	; clear interrupt flag

		movf	SPIBufPointer,W
		movwf	FSR
		incf	SPIBufPointer,F

		movf	SSPBUF,W	; get data & clear buffer flag
		movwf	INDF		; put it into SPI buffer

		decfsz	SPICounter,F
		   goto	   MoreByte	; more byte to send

		bsf	CAN_CS		; deselect CAN Controller
		goto	IntReturn

MoreByte	incf	FSR,F
		movf	INDF,W		; get byte from buffer
		movwf	SSPBUF		; send it
		goto	IntReturn


