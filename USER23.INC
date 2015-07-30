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
;John Broadbent University Of Kentucky Solar Car Team (UKSC)
;We downloaded this code from UC Berkly (CalSol), with the goal of useing this to change the operating point for our trackers.
;The p16f877 has serveral 10 bit adc's, and the MPPT send can messages with a 10 bit voltage.

;===================================
;gallium versioin 07/30/2015
;===================================
;The target operating points are below
;Minimum Input Voltage [V]  33.5
;Maximum Input Voltage [V]  107
;Nominal Battery Voltage [V]  132
;Minimum Output Voltage [V]  117.39
;Maximum Output Voltage [V]  134 
;Maximum Input MPP Current [A] 5.79
;Maximum Input Short Circuit Current [A] 6.22
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

;UKSC new values (JM)
; (target voltage) / ( mV per Count) = number of counts needed 
;( 134 volts / 208.79mV per Count) = 641.79 ~= 642 Counts = 0x0282
#define MAXUOH      0x02
#define MAXUOL      0x82


;**********************************************************************
;   P&O Constants
;**********************************************************************
;CalSol's values are below. Kinda neat, I guess.
;#define MINUINH	0x00	; Min  input voltage HByte 26V in 150.49 mV Units
;#define MINUINL	0xAD	; Min  input voltage LByte 26V; in 150.49 mV Units

;UKSC new values (JM)
;(target Voltage) / (mV per Count) = number of counts needed
;(33.5 votls) / ( 150.49 mV / per count) = 222.606 ~= 222 counts = 0x00DE

#define MINUINH 0x00
#define MINUINL	0xDE
;**********************************************************************
;Min Output Voltage, used for Precharge
;**********************************************************************
;#define MINUBATH	0x01	; Min output voltage HByte 84 V in 196.97 mV  Units
;#define MINUBATL	0xAA	; Min output voltage LByte 84 V in 196.97 mV  Units

;UKSC new values (JB)
;(target Voltage) / (mV per Count) = number of counts needed
;(117.39 volts) / (208.79 mV perCount) = 560  = 0x0230
#define MINUBATH   0x02
#define MINUBATL   0x30
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
;( 107 volts) / (150.49 mV perCount) = 690 = 0x02b2

#define UmppH 0x02      
#define UmppL 0xb2                                                                                                                                                                                                     

