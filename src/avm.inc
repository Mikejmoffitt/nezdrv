;
; Audio VM state 0 one channel
;


OPN_CHANNEL_COUNT = 6
PSG_CHANNEL_COUNT = 4
OPN_FX_CHANNEL_COUNT = 3
PSG_FX_CHANNEL_COUNT = 2
TOTAL_OPN_CHANNEL_COUNT = OPN_CHANNEL_COUNT+OPN_FX_CHANNEL_COUNT
TOTAL_PSG_CHANNEL_COUNT = PSG_CHANNEL_COUNT+PSG_FX_CHANNEL_COUNT
TOTAL_CHANNEL_COUNT = TOTAL_OPN_CHANNEL_COUNT+TOTAL_PSG_CHANNEL_COUNT

AVM_STACK_DEPTH = 5

AVM_STATUS_INACTIVE = 0
AVM_STATUS_ACTIVE = 1
AVM_STATUS_MUTED = 2

AVM_REST_DEFAULT = 12

; General generic channel VM state
AVM struct
; Intrinsic channel properties
status:      ds 1
channel_id:  ds 1

; Control flow
pc:          ds 2
loop_ptr:    ds 2
loop_cnt:    ds 1
rest_val:    ds 1
rest_cnt:    ds 1
stack_ptr:   ds 2
stack:       ds AVM_STACK_DEPTH*2

; Note settings
volume:      ds 1  ; really attenuation, summed with tl on key-on.
octave:      ds 1  ; stored as multiples of 8 to match block register.
portamento:  ds 1  ; rate of change for target_freq. If 0, it is instant.

; Current note play variables
now_freq:    ds 2
now_block:   ds 1
tgt_freq:    ds 2
tgt_block:   ds 1
key_pending: ds 1  ; if true, awaiting a key on event.

; OPN-specific state
patch_ptr:   ds 2
tl_conoffs:  ds 1  ; pre-multiplied jump table offset for tl setting (patch con * 3)
tl:          ds 4  ; TL values from when instrument was set.
pan:         ds 1  ; pan/ams/pms register.

pad:         ds 10h-7h

AVM endstruct


; Overall global state
AVMG struct
instrument_list_ptr: ds 2
AVMG endstruct

; Sound engine instruction bytes.

; Control instructions can be used as offsets into a jump as-is.

; Jump
AVM_JUMP     = 3*0
; Call routine (+ 2 bytes)
AVM_CALL     = 3*1
; Return
AVM_RET      = 3*2
; Set loop point (+ 1 byte for count)
AVM_LOOPSET  = 3*3
; End loop point (decrement and jump to loop ptr if nonzero)
AVM_LOOPEND  = 3*4
; Set timer  value +1 byte
AVM_TIMER    = 3*5
; Set note length (in note ticks) +1 byte
AVM_LENGTH   = 3*6
; Rest
AVM_REST     = 3*7
; Set octave +1 byte
AVM_OCT      = 3*8
; Increment octave
AVM_OCT_UP   = 3*9
; Decrement octave
AVM_OCT_DOWN = 3*10
; Set instrument  +1 byte = instrument (multiple of 2)
AVM_INST     = 3*11
; Set volume (inverse TL) +1 byte
AVM_VOL      = 3*12
; Set panning
AVM_PAN      = 3*13
; Set PMS
AVM_PMS      = 3*14
; Set AMS
AVM_AMS      = 3*15
; Set arbitrary FM register  +2 bytes
AVM_OPN_REG  = 3*16
; Stop the channel.
AVM_STOP     = 3*17
; Note off
AVM_NOTE_OFF = 3*18
; Set portamento
AVM_SLIDE    = 3*19



; The note instructions allow the low nybble to be used as an offset into the
; frequency table after masking with 1Fh.
AVM_NOTE_C   = 80h
AVM_NOTE_Cs  = 82h
AVM_NOTE_D   = 84h
AVM_NOTE_Ds  = 86h
AVM_NOTE_E   = 88h
AVM_NOTE_F   = 8Ah
AVM_NOTE_Fs  = 8Ch
AVM_NOTE_G   = 8Eh
AVM_NOTE_Gs  = 90h
AVM_NOTE_A   = 92h
AVM_NOTE_As  = 94h
AVM_NOTE_B   = 96h
AVM_NOTE_Bs  = 98h
; If a note command has bit 5 set (20h) then the next byte contains the rest
; counter value to use instead of the one set for teh channel.
AVM_NOTE_REST_FLAG = 20h
; With bit 6 set, the new frequency is adopted, but the key state is unchanged.
AVM_NOTE_NO_KEY_ON_FLAG = 40h

AVM_NOTE_Db  = AVM_NOTE_Cs
AVM_NOTE_Eb  = AVM_NOTE_Ds
AVM_NOTE_Gb  = AVM_NOTE_Fs
AVM_NOTE_Ab  = AVM_NOTE_Gs
AVM_NOTE_Bb  = AVM_NOTE_As


