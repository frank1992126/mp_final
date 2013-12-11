.EQU CR,  0x0D
.EQU LF,  0x0A
.EQU BEL, 0x07

.ORG 0x0000
	ajmp MAIN
.ORG 0x0023
	ajmp SINT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;SCON(Serial Control Flag) Definition
; Bit addressable.
; Bit:	7	6	5	4	3	2	1	0
;		SM0	SM1	SM2	REN	TB0	RB0	TI	RI
;
; SM0 And SM1 is used to select Mode 0~3
; In Mode 1, if SM2 is set, 8051 will drop data without stop-bit
; REN stands for Receive Enable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.ORG 0x0100
MAIN:
	; Configure Interrupt
	mov IE,   #0x90
	
	; Configure Serial Mode
	mov SCON, #0x52			;0b01010010 mode1, sm2=1, ren=1
	mov PCON, #0x00
	
	; Configure Serial Baudrate
	; In timer 1 auto reload mode
	; Baud = (2^SMOD)/32 * (OSCFreq/12/(256-TH1)	
	mov  TMOD, #0x20			;Timer1 in mode 2
	mov  TH1,  #250			;Baud=9600
	setb TR1				;Start timer1
	
	;;; send welcome msg
	acall PRINTIL
	.db "==== Microprocessor Final Project - Tiny Basic ====",CR,LF
	.db	"==  Author:            Frank Chang               ==",CR,LF
	.db	"==  Last Modified:     2013/12/11                ==",CR,LF
	.db	"===================================================",CR,(LF|80h)
	
	ljmp END_PROG			; End Program

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Serial Interrupt Handler
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SINT:
	jb RI, SINT_RI
	reti		; if RI is not set, return (omit TI)
SINT_RI:		; if RI is set, echo
	clr RI
	mov    A, SBUF
	cjne   A, #CR, NOT_CR	; if CR is received, send CRLF instead of CR
	mov dptr, #newline
	acall PRINT
	reti
NOT_CR:
	acall TX_DATA
	reti

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Serial Data Send
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TX_DATA:
	JNB	 TI, TX_DATA		; wait for send finish
	clr	 TI
	mov	 SBUF, A
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Print String to serial
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRINTIL:					; Print In-line String
	pop dph
	pop dpl
	acall PRINT
	mov A,  #1
	jmp @dptr+A
PRINTLN:					; Print with newline
	acall PRINT
	mov dptr, #newline
	acall PRINT
	ret
PRINT:						;  Uses dptr as string pointer
	push ACC
PRINT_LOOP:
	clr  A
	movc A, @dptr+A			; Load character
	jbc	ACC.7, PRINT_END	; if end of string, quit
	acall TX_DATA
	inc dptr				; Next char
	sjmp PRINT_LOOP			; send next character
PRINT_END:
	acall TX_DATA
	pop ACC
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Code Scanner
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Code Parser
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	End of Program
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
END_PROG:			; End Program
	sjmp END_PROG

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Strings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
newline: .db CR, (LF | 80h)
