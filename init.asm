;**********************************************************************
;   P R O G R A M M	MPPTnG                                            *
;                                                                     *
;   Traking program for MPPT new generation                           *
;**********************************************************************
;                                                                     *
;    Filename:	    init.asm                                          *
;    Date:          15.11.00                                          *
;    Last Update:   21.09.00                                          *
;    File Version:  V3.0                                              *
;                                                                     *
;    Author:        Michael Zürcher                                   *
;                                                                     *
;    Company:       HTA-Biel/Bienne Indulab                           *
;                                                                     *
;    Changes:       Introduced separate init routine with V3.0        *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;    - Main program : mpptng.asm                                      *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Ports config:                                                    *
;                                                                     *
;    port ra0	an0	i	Analog Umes_in                                * 
;    port ra1	an1	i	Analog Umes_out                               *
;    port ra2	an2	i	Analog Imes_in                                *
;    port ra3	Vref+	i	+4.1V                                     *
;    port ra4	an3	i	--- not connected ---                         *
;    port ra5	an4	i	Analog Temp Ambiant                           *
;                                                                     *
;    port rb0	int	i	External INT                                  *
;    port rb1	-	o	LED red                                       *
;    port rb2	-	i	Can present                                   *
;    port rb3	-	i	OVH interrupt (OverHeat)                      *
;    port rb4	-	i	NOC interrupt (NoCharge)                      *
;    port rb5	-	i	UNDV interrupt (UnderVoltage)                 *
;    port rb6	pgc	o	In-Circuit Debugger                           *
;    port rb7	pgd	o	In-Circuit Debugger                           *
;                                                                     *
;    port rc0	-	o	ENA_FET                                       *
;    port rc1	ccp2	o	PWM2 (Duty cycle)                         *
;    port rc2	ccp1	o	PWM1 (Aux pulse)                          *
;    port rc3	sck	o	SPI bus - SCK (output for master mode)        *
;    port rc4	sdi	i	SPI bus - SDI (auto controlled by SPI Module) *
;    port rc5	sdo	o	SPI bus - SDO (output)                        *
;    port rc6	-	o	RS232TX                                       *
;    port rc7	-	i	RS232RX                                       *
;                                                                     *
;    port rd0	-	i	Adress0 IDTracker                             * 
;    port rd1	-	i	Adress1 IDTracker                             *
;    port rd2	-	i	Adress2 IDTracker                             *
;    port rd3	-	i	Adress3 IDTracker                             *
;    port rd4	-	i	Adress4 IDTracker                             *
;    port rd5	-	o	SEL_CAN                                       *
;    port rd6	-	o	RES_NOC (Reset NoCharge flip-flop)            *
;    port rd7	-	o	RES_OVH (Reset OverVoltage flip-flop)         *
;                                                                     *
;    port re0	an5	i	Analog  -not used-                            *
;    port re1	an6	i	Analog Temp Cooler                            *
;    port re2	-	i	--- not used ---                              *
;                                                                     *
;**********************************************************************


;**********************************************************************
;		GENERAL INITIALISATION
;**********************************************************************
Init		BANK1
			clrf	PIE1_P			; clear peripheral interrupts
       
	  		movlw	B'10001101' 	; pullup off / falling edge for RB0/INT pin
									; Watchdog Prescaler is 101 = 1:32 = 0.625s
									; Watchdog Timer must be enabled on download "2007h"
			movwf	OPTION_REG_P	
			 

			movlw	0x20			; clear general purpose register (RAM) bank 0
			movwf	FSR
initClr1	clrf	INDF
			incf	FSR,F
			btfss	FSR,7
		   	goto	initClr1

			movlw	0xA0			; clear general purpose register (RAM) bank 1
			movwf	FSR
initClr2	clrf	INDF
			incf	FSR,F
			btfsc	FSR,7
		   	goto	initClr2


			clrf	GenFlags		; clear general flags

			BANK0

			clrf	PORTA			; clear output data latches of PortA
			clrf	PORTB			; clear output data latches of PortB
			movlw	B'00000011'		; init portC:	RC0  ENA_FET=1
									; RC1  DUT_CYC=1
									; RC2  AUX_PUL=0
			movwf	PORTC	

			BANK1
		
			movlw	INIT_IO_A	; init portA direction
			movwf	TRISA
			movlw	INIT_IO_B	; init portB direction
			movwf	TRISB
			movlw	INIT_IO_C	; init portC direction
			movwf	TRISC
			movlw	INIT_IO_D	; init portD direction
			movwf	TRISD
			movlw	INIT_IO_E	; init portE direction
			movwf	TRISE

			BANK0

			movlw	B'11001000'	; enable peripheral interrupt, disables RB0/INT
								; enable port B change interrupt
			movwf	INTCON
					
			RETURN

