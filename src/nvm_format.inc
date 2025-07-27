; ------------------------------------------------------------------------------
;
; Data format definitions and macros for writing music for NEZDRV.
;
; ------------------------------------------------------------------------------

;
; Track header definition.
;

NEZ_PCMRATE_DEFAULT = 03FBh
NEZ_TEMPO_DEFAULT = 0E0h
NEZ_REST_LENGTH_DEFAULT = 12

; Macro for making relative pointers within a track.
nTrackRelPtr macro lbl
	dw	lbl-NEZ_TRACK_BASE-2
	endm

; Start marker for track / effect file.
; pcmrate:         PCM playback rate (0 - 1023)
; temporate:       Music base timer rate (0 - 255). Ignored for sound effects.
; instrumentlists: Instrument list symbol name.
;
; This macro must be placed at the top of the file before any data.
;
nTrackHeader macro pcmrate, temporate, tracklist, instrumentlist
NEZ_TRACK_BASE := $
	nTrackRelPtr NEZ_TRACK_END
	nPcmRateEncode pcmrate
	db	temporate
	nTrackRelPtr tracklist
	nTrackRelPtr instrumentlist
	endm

; End marker for track / effect data. This must be placed at the end, after all
; data. This marker is necessary for the header's size field.
nTrackFooter macro
NEZ_TRACK_END := $
	endm

; List end marker (null terminator for the time being)
nTrackListEnd macro
	dw	0
	endm

; Macro to massage 10-bit timer value for use with Timer A register.
nPcmRateEncode macro pcmrate
	db	((pcmrate)>>2)
	db	((pcmrate)&03h)
	endm

; Macro to include a PCM file and assign it a length marker.
nPcmDef macro filename
	dw	.pcmend-.pcmstart
.pcmstart:
	binclude	filename
.pcmend:
	endm

; Channel IDs.
NVM_CHID_OPN0  = 00h
NVM_CHID_OPN1  = 01h
NVM_CHID_OPN2  = 02h
NVM_CHID_OPN3  = 03h
NVM_CHID_OPN4  = 04h
NVM_CHID_OPN5  = 05h
NVM_CHID_PSG0  = 06h
NVM_CHID_PSG1  = 07h
NVM_CHID_PSG2  = 08h
NVM_CHID_PSGN  = 09h
NVM_CHID_PSGNS = 80h  ; special noise case.

; Macro for setting channel ID. Will set the noise channel mode automatically.
nSfxCh	channel
	IF channel == NVM_CHID_PSGNS
	dw	channel
	nNoise	03h
	ELSE
	dw	channel
	ENDIF  ; channel
	endm

;
; Instruction Macros
;

;
; Internal macros
;
NRelOffsCalc macro lbl
	dw	(lbl)-$-1
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

nLpSet macro lpcount
	db	NVM_LOOPSET, lpcount
	endm

nLpEnd macro lbl
	db	NVM_LOOPEND
	NRelOffsCalc lbl
	endm

nTempo macro tval
	db	NVM_TEMPO, tval
	endm

nLength macro lenval
	db	NVM_LENGTH, lenval
	endm

nRest macro restval=0
	db	NVM_REST, (restval)
	endm

nOct macro octno
	db	NVM_OCT, (octno)
	endm

nOctUp macro
	db	NVM_OCT_UP
	endm

nOctDn macro
	db	NVM_OCT_DOWN
	endm

nInst	macro instno
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

nPms macro pmsval=0
	db	NVM_PMS, ((pmsval)&07h)<<OPN_PMS_SHIFT
	endm

nAms macro amsval=0
	db	NVM_AMS, ((amsval)&03h)<<OPN_AMS_SHIFT
	endm

nLfo macro lfoval
	db	NVM_LFO, 08h | lfoval
	endm

nLfoOff	macro
	nLfo	0
	endm

nOpnReg macro regno, regval
	db	NVM_OPN_REG, regno, regval
	endm

nStop macro
	db	NVM_STOP
	endm

nOff macro spcarg=-1
	db	NVM_NOTE_OFF
	IF spcarg == -1
	nRest
	ENDIF  ; spcarg
	IF spcarg > 0
	nRest	spcarg
	ENDIF  ; spcarg
	endm

nSlide macro slideval
	db	NVM_SLIDE, slideval
	endm

nPcmRate macro rateval
	db	NVM_PCMRATE
	; data is massaged for Timer-A register consumption.
	nPcmRateEncode rateval
	endm

nPcmMode macro enabled
	db	NVM_PCMMODE
	IF enabled > 0
	db	80h
	ELSE
	db	00h
	ENDIF  ; enabled
	endm

nPcmPlay macro id, spcarg=-1
	db	NVM_PCMPLAY
	db	(id)*3
	IF	spcarg == -1
	nRest
	ELSE
	IF restart > 0
	nRest spcarg
	ENDIF
	ENDIF
	endm

nPcmStop macro
	db	NVM_PCMSTOP
	endm

nTrn	macro trnval
	db	NVM_TRN, trnval*2
	endm

nTrnAdd	macro trnval
	db	NVM_TRN_ADD, trnval*2
	endm

nTrnSub	macro trnval
	db	NVM_TRN_SUB, trnval*2
	endm

nSwpUp	macro speed
	nSlide	speed
	nOct	7
	db	NVM_NOTE_B | NVM_NOTE_NO_KEY_ON_FLAG | NVM_NOTE_REST_FLAG
	db	0
	endm

nSwpDn	macro speed
	nSlide	speed
	nOct	0
	db	NVM_NOTE_C | NVM_NOTE_NO_KEY_ON_FLAG | NVM_NOTE_REST_FLAG
	db	0
	endm

nNoise	macro	noisecmd
	db	NVM_NOISE
	db	noisecmd
	endm

nNote macro noteval, spcarg
	IF (spcarg) > 0
	db	noteval | NVM_NOTE_REST_FLAG | ((spcarg)>>8)
	db	((spcarg) & 0FFh)
	ELSE
	db	noteval | ((spcarg)>>8)
	ENDIF  ; spcarg
	endm

nC macro spcarg=0
	nNote	NVM_NOTE_C, spcarg
	endm

nCs macro spcarg=0
	nNote	NVM_NOTE_Cs, spcarg
	endm

nD macro spcarg=0
	nNote	NVM_NOTE_D, spcarg
	endm

nDs macro spcarg=0
	nNote	NVM_NOTE_Ds, spcarg
	endm

nE macro spcarg=0
	nNote	NVM_NOTE_E, spcarg
	endm

nF macro spcarg=0
	nNote	NVM_NOTE_F, spcarg
	endm

nFs macro spcarg=0
	nNote	NVM_NOTE_Fs, spcarg
	endm

nG macro spcarg=0
	nNote	NVM_NOTE_G, spcarg
	endm

nGs macro spcarg=0
	nNote	NVM_NOTE_Gs, spcarg
	endm

nA macro spcarg=0
	nNote	NVM_NOTE_A, spcarg
	endm

nAs macro spcarg=0
	nNote	NVM_NOTE_As, spcarg
	endm

nB macro spcarg=0
	nNote	NVM_NOTE_B, spcarg
	endm

nDb macro spcarg=0
	nCs spcarg
	endm

nEb macro spcarg=0
	nDs spcarg
	endm

nGb macro spcarg=0
	nFs spcarg
	endm

nAb macro spcarg=0
	nGs spcarg
	endm

nBb macro spcarg=0
	nAs spcarg
	endm


;
; Sound engine instruction raw opcode bytes.
;

; Jump
NVM_JUMP     = 3*0
; Call routine (+ 2 bytes)
NVM_CALL     = 3*1
; Return
NVM_RET      = 3*2
; Advance loop stack and set loop point (+ 1 byte for count)
NVM_LOOPSET  = 3*3
; End loop point (decrement and branch if loop counter is nonzero)
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
; Set LFO
NVM_LFO      = 3*16
; Stop the channel.
NVM_STOP     = 3*17
; Note off
NVM_NOTE_OFF = 3*18
; Set portamento
NVM_SLIDE    = 3*19
; Set timer A value +2 bytes
NVM_PCMRATE  = 3*20
; Enable or disable PCM mode +1 byte (80h = enable)
NVM_PCMMODE  = 3*21
; Play a PCM sample by ID + 1 byte
NVM_PCMPLAY  = 3*22
; Stop PCM playback.
NVM_PCMSTOP  = 3*23
; Set arbitrary FM register  +2 bytes
NVM_OPN_REG  = 3*24
; Set transposition for the channel.
NVM_TRN      = 3*25
; Add to transposition.
NVM_TRN_ADD  = 3*26
; Subtract from transposition
NVM_TRN_SUB  = 3*27
; Noise control
NVM_NOISE    = 3*28

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
NVM_NOTE_LIM = 98h

NVM_NOTE_Db  = NVM_NOTE_Cs
NVM_NOTE_Eb  = NVM_NOTE_Ds
NVM_NOTE_Gb  = NVM_NOTE_Fs
NVM_NOTE_Ab  = NVM_NOTE_Gs
NVM_NOTE_Bb  = NVM_NOTE_As

; PSG macro commands.
NVM_MACRO_END   = 0FFh
NVM_MACRO_LPSET = 0FEh
NVM_MACRO_LPEND = 0FDh  ; falls through on note off.

; If a note command has bit 5 set (20h) then the next byte contains the rest
; counter value to use instead of the one set for teh channel.
NVM_NOTE_REST_FLAG = 20h
; With bit 6 set, the new frequency is adopted, but the key state is unchanged.
NVM_NOTE_NO_KEY_ON_FLAG = 40h
