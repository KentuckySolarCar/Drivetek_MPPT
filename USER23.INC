;**********************************************************************
;   P R O G R A M M	MPPTnG                                            *
;                                                                     *
;   Traking program for MPPT new generation                           *
;**********************************************************************
;                                                                     *
;    Filename:	    user.inc                                          *
;    Date:          20.04.01                                          *
;    Last Update:   14.03.05                                          *
;    File Version:  V3.0                                              *
;                                                                     *
;    Author:        Michael Zürcher, Christoph Raible                 *
;                                                                     *
;    Company:       HTA-Biel/Bienne Indulab, drivetek ag              *
;                                                                     *
;    Changes:       							                      *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;    - Main program : mpptng.asm                                      *
;    - Client : 23			                                          *
;								                                      *
;   Order Number: 23				                                  *
;                       					                          *
;**********************************************************************


;--------------------------
;Chris Heintz University Of Kentucky Solar Car Team (UKSC)
;We downloaded this code from UC Berkly (CalSol), with the goal of useing this to change the operating point for our trackers.
;The p16f877 has serveral 10 bit adc's, and the MPPT send can messages with a 10 bit voltage.
;The target operating points for NJIT are below
;Minimum Input Voltage [V]  36
;Maximum Input Voltage [V]  86.4
;Estimated MPP Voltage [V] 71.2
;Nominal Battery Voltage [V]  74
;Minimum Output Voltage [V]  54
;Maximum Output Voltage [V]  80 
;
; 
; and the volts to count (for the version 4 from the PDF)are 
;Input voltage multiplication factor: 150.49 [mV/LSB]
;Output voltage multiplication factor: 208.79 [mV/LSB]
;Input MPP current multiplication factor: 8.72 [mA/LSB]

;-----------------
;**********************************************************************
;   maximum battery voltage
;**********************************************************************
#define INITDUTY	0x74		; Duty resulting of Ubat and Uoc

;CalSol's values are below. Kinda neat, I guess.
;#define MAXUOH		0x02		; 117.6 V: Max Batt. volt HByte 
					; in 196.97 mV Units
;#define MAXUOL		0x55		; 117.6 V: Max Batt. volt LByte in
					; 196.97 mV Unit

;UKSC new values (JB)
; (target voltage) / ( mV per Count) = number of counts needed 
;( 80 volts / 208.79mV per Count) = 384 Counts = 0x0180
#define MAXUOH      0x01
#define MAXUOL      0x80


;**********************************************************************
;   P&O Constants
;**********************************************************************
;CalSol's values are below. Kinda neat, I guess.
;#define MINUINH	0x00	; Min  input voltage HByte 26V in 150.49 mV Units
;#define MINUINL	0xAD	; Min  input voltage LByte 26V; in 150.49 mV Units

;UKSC new values (JB)
;(target Voltage) / (mV per Count) = number of counts needed
;(36 volts) / ( 150.49 mV / per count) = 239 = 0x00EF

#define MINUINH 0x00
#define MINUINL	0xEF
;**********************************************************************
;Min Output Voltage, used for Precharge
;**********************************************************************
;#define MINUBATH	0x01	; Min output voltage HByte 84 V in 196.97 mV  Units
;#define MINUBATL	0xAA	; Min output voltage LByte 84 V in 196.97 mV  Units

;UKSC new values (JB)
;(target Voltage) / (mV per Count) = number of counts needed
;(54 volts) / (208.79 mV perCount) = 259  = 0x0103
#define MINUBATH   0x01
#define MINUBATL   0x03
;**********************************************************************
;   border ot discontinuous mode 
;   ON-Values have to be greater than OFF-Values
;   notice the hysteresis NOT USED IN HARDWARE V3.0!!!
;**********************************************************************
;#define IHFETONH	0x01	; H-FET Turn on HByte 32% of max current
;#define IHFETONL	0x47	; H-FET Turn on LByte 32% of max current
;#define IHFETOFFH	0x01	; H-FET Turn on HByte 25% of max current
;#define IHFETOFFL	0x00	; H-FET Turn on LByte 25% of max current


;**********************************************************************
;   Minimum Input Power of 
;**********************************************************************

#define MINPINM 0x16    ; M-Byte Min input power 5W (5.86 mA/Bit x 150.49 mV/Bit)
#define MINPINL 0x26	; L-Byte Min input power

;**********************************************************************
;   Maximum Power Point Input Voltage (influences tracking step width)
;**********************************************************************

;#define UmppH 0x02      ; Mpp input voltage HByte 86 V in 150.49 mV Units
;#define UmppL 0x3B	    ; Mpp input voltage LByte 86 V in 150.49 mV Units     

;UKSC new values (JB)

;(target Voltage) / (mV per Count) = number of counts needed
;( 71.2 volts) / (150.49 mV perCount) = 474 = 0x01DA

#define UmppH 0x01      
#define UmppL 0xDA	                                                                                                                                                                                                                                                                                                            

