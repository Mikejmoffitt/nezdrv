;
; Audio VM state 0 one channel
;

SFX_CHANNEL_COUNT = 3

; Channels A-F
OPN_BGM_CHANNEL_COUNT = 6
; Channels G-J
PSG_BGM_CHANNEL_COUNT = 4

TOTAL_BGM_CHANNEL_COUNT = OPN_BGM_CHANNEL_COUNT+PSG_BGM_CHANNEL_COUNT
TOTAL_CHANNEL_COUNT = TOTAL_BGM_CHANNEL_COUNT+SFX_CHANNEL_COUNT

NVM_STACK_DEPTH = 4
; Channel status
NVM_STATUS_INACTIVE = 0
NVM_STATUS_ACTIVE = 1
; Currently channel type (set globally when interpreter is called)
NVM_CHTYPE_OPN = 0
NVM_CHTYPE_PSG = 1

NVM_REST_DEFAULT = 12

NVM_BLOCK_PORTAMENTO_SKIP_FLAG = 80h

NVM_MUTE_NONE     = 00h
NVM_MUTE_RESTORED = 01h
NVM_MUTE_MUTED    = 80h

	align	10h
;
; NEZDRV channel VM memory state.
;
NVM struct
; Intrinsic channel properties
status:         ds 1
mute:           ds 1
channel_id:     ds 1

; Control flow
pc:             ds 2
stack_ptr:      ds 2
stack:          ds NVM_STACK_DEPTH*2
loop_stack_ptr: ds 2
loop_stack:     ds NVM_STACK_DEPTH
rest_val:       ds 1
rest_cnt:       ds 1

; Vibrato
;vib_phase:      ds 1  ; counting up or down
;vib_cnt:        ds 1  ; current value
;vib_mag:        ds 1  ; strength
;vib_speed:      ds 1  ; how much to increment by

; Note settings
transpose:      ds 1  ; in semitones
volume:         ds 1  ; really attenuation, summed with tl (opn) on key-on.
octave:         ds 1
portamento:     ds 1  ; rate of change for target_freq. If 0, it is instant.

; Instrument pointer (be it OPN patch or PSG macro)
instrument_ptr: ds 2
NVM endstruct

;
; OPN-specific channel state
;
NVMOPN struct
nvmbase:        ds NVM.len

; Key down stuff
key_pending:    ds 1  ; if true, awaiting a key on event.

; Instrument/Patch
tl_conoffs:     ds 1  ; pre-multiplied jr table offset for tl setting (patch con * 2)
tl:             ds 4  ; TL values from when instrument was set.
pan:            ds 1  ; pan/ams/pms register.

; Portamento state
now_freq:       ds 2
now_block:      ds 1  ; if negative, immediately adopts the target.
tgt_freq:       ds 2
tgt_block:      ds 1

pad:            ds 6

NVMOPN endstruct


;
; PSG-specific channel state.
;
NVMPSG struct
nvmbase:        ds NVM.len

key_on:         ds 1

; Amplitude Envelope
env_ptr:        ds 2  ; copied from instrument on key down.
env_loop_ptr:   ds 2

; Portamento state
now_period:     ds 2
tgt_period:     ds 2

pad:            ds 4+6

NVMPSG endstruct


;
; NVMBGM
;
; Basically an alias for storage purposes.
	IF	NVMPSG.len <> NVMOPN.len
	ERROR "PSG and OPN struct sizes differ!"
	ENDIF

NVMBGM struct
nvmbase:        ds NVMOPN.len
NVMBGM endstruct


NVMSFX struct
nvmbase:        ds NVMBGM.len
mute_channel:   ds 1
NVMSFX endstruct

NVMCONTEXT struct
global_volume:       ds 1
buffer_ptr:          ds 2
instrument_list_ptr: ds 2
pcm_rate:            ds 2
NVMCONTEXT endstruct


; Header defining a header for a blob of track data (BGM or SFX).
; Two bytes preceed it with a word that contains the byte count of the data.
NEZINFO struct
ta:                    ds 2  ; Timer A value (PCM rate) (ignored for SFX)
tb:                    ds 1  ; Timer B value (tempo control)
; Null-terminated lists that are relative to the start of the data blob.
track_list_offs:       ds 2  ; For SFX, these are the effect indices.
instrument_list_offs:  ds 2
NEZINFO endstruct
