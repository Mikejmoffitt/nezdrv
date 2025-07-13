NEZ_ORG = 0A00h

; Sound engine instruction bytes.

; Jump
NVM_JUMP     = 3*0
; Call routine (+ 2 bytes)
NVM_CALL     = 3*1
; Return
NVM_RET      = 3*2
; Set loop point (+ 1 byte for count)
NVM_LOOPSET  = 3*3
; End loop point (decrement and jump to loop ptr if nonzero)
NVM_LOOPEND  = 3*4
; Set timer B value +1 byte
NVM_TEMPO    = 3*5
; Set note length (in note ticks) +1 byte
NVM_LENGTH   = 3*6
; Rest
NVM_REST     = 3*7
; Set octave +1 byte
NVM_OCT      = 3*8
; Increment octave
NVM_OCT_UP   = 3*9
; Decrement octave
NVM_OCT_DOWN = 3*10
; Set instrument  +1 byte = instrument (multiple of 2)
NVM_INST     = 3*11
; Set volume (inverse TL) +1 byte
NVM_VOL      = 3*12
; Set panning
NVM_PAN      = 3*13
; Set PMS
NVM_PMS      = 3*14
; Set AMS
NVM_AMS      = 3*15
; Set arbitrary FM register  +2 bytes
NVM_OPN_REG  = 3*16
; Stop the channel.
NVM_STOP     = 3*17
; Note off
NVM_NOTE_OFF = 3*18
; Set portamento
NVM_SLIDE    = 3*19
; Set timer A value +2 bytes
NVM_PCMRATE  = 3*20

; The note instructions allow the low nybble to be used as an offset into the
; frequency table after masking with 1Fh.
NVM_NOTE_C   = 80h
NVM_NOTE_Cs  = 82h
NVM_NOTE_D   = 84h
NVM_NOTE_Ds  = 86h
NVM_NOTE_E   = 88h
NVM_NOTE_F   = 8Ah
NVM_NOTE_Fs  = 8Ch
NVM_NOTE_G   = 8Eh
NVM_NOTE_Gs  = 90h
NVM_NOTE_A   = 92h
NVM_NOTE_As  = 94h
NVM_NOTE_B   = 96h
NVM_NOTE_Bs  = 98h

NVM_NOTE_Db  = NVM_NOTE_Cs
NVM_NOTE_Eb  = NVM_NOTE_Ds
NVM_NOTE_Gb  = NVM_NOTE_Fs
NVM_NOTE_Ab  = NVM_NOTE_Gs
NVM_NOTE_Bb  = NVM_NOTE_As

; If a note command has bit 5 set (20h) then the next byte contains the rest
; counter value to use instead of the one set for teh channel.
NVM_NOTE_REST_FLAG = 20h
; With bit 6 set, the new frequency is adopted, but the key state is unchanged.
NVM_NOTE_NO_KEY_ON_FLAG = 40h

;
; Internal macros
;
NRelOffsCalc macro lbl
	dw	lbl-$-1
	endm

;
; Macros for commands
;

nJump macro lbl
	db	NVM_JUMP
	NRelOffsCalc lbl
	endm

nCall macro lbl
	db	NVM_CALL
	NRelOffsCalc lbl
	endm

nRet macro
	db	NVM_RET
	endm

NLpSet macro lpcount
	db	NVM_LOOPSET, lpcount
	endm

NLpEnd macro
	db	NVM_LOOPEND
	endm

NTempo macro tval
	db	NVM_TEMPO, tval
	endm

nLength macro lenval
	db	NVM_LENGTH, lenval
	endm

nRest macro restval=0
	db	NVM_REST, restval
	endm

nOct macro octno
	db	NVM_OCT, (octno)*8
	endm

nOctUp macro
	db	NVM_OCT_UP
	endm

nOctDn macro
	db	NVM_OCT_DOWN
	endm

NInst	macro instno
	db	NVM_INST, (instno)*2
	endm

nVol	macro volval
	db	NVM_VOL, 7Fh-(volval)
	endm

nPan macro panval
	db	NVM_PAN, panval
	endm

nPanBoth macro
	nPan OPN_PAN_L | OPN_PAN_R
	endm

nPanL macro
	nPan OPN_PAN_L
	endm

nPanR macro
	nPan OPN_PAN_R
	endm

NPms macro pmsval
	db	NVM_PMS, ((pmsval)&07h)<<OPN_PMS_SHIFT
	endm

NAms macro amsval
	db	NVM_AMS, ((amsval)&03h)<<OPN_AMS_SHIFT
	endm

NOpnReg macro regno, regval
	db	NVM_OPN_REG, regno, regval
	endm

NStop macro
	db	NVM_STOP
	endm

nNoteOff macro
	db	NVM_NOTE_OFF
	endm

nSlide macro slideval
	db	NVM_SLIDE, slideval
	endm

NPcmRate macro rateval
	db	NVM_PCMRATE
	; data is massaged for Timer-A register consumption.
	db	((rateval)>>2)
	db	((rateval)&03h)
	endm

nNote macro noteval, restval
	IF restval > 0
	db	noteval | NVM_NOTE_REST_FLAG
	db	restval
	ELSE
	db	noteval
	ENDIF  ; restval
	endm

nC macro restarg=0
	nNote	NVM_NOTE_C, restarg
	endm

nCs macro restarg=0
	nNote	NVM_NOTE_Cs, restarg
	endm

nD macro restarg=0
	nNote	NVM_NOTE_D, restarg
	endm

nDs macro restarg=0
	nNote	NVM_NOTE_Ds, restarg
	endm

nE macro restarg=0
	nNote	NVM_NOTE_E, restarg
	endm

nF macro restarg=0
	nNote	NVM_NOTE_F, restarg
	endm

nFs macro restarg=0
	nNote	NVM_NOTE_Fs, restarg
	endm

nG macro restarg=0
	nNote	NVM_NOTE_G, restarg
	endm

nGs macro restarg=0
	nNote	NVM_NOTE_Gs, restarg
	endm

nA macro restarg=0
	nNote	NVM_NOTE_A, restarg
	endm

nAs macro restarg=0
	nNote	NVM_NOTE_As, restarg
	endm

nB macro restarg=0
	nNote	NVM_NOTE_B, restarg
	endm

nBs macro restarg=0
	nNote	NVM_NOTE_Bs, restarg
	endm

nDb macro restarg=0
	nCs restarg
	endm

nEb macro restarg=0
	nDs restarg
	endm

nGb macro restarg=0
	nFs restarg
	endm

nAb macro restarg=0
	nGs restarg
	endm

nBb macro restarg=0
	nAs restarg
	endm
