;
; Audio VM state 0 one channel
;

; PSG and OPN effects need to match in count as a tiny optimization.
SFX_CHANNEL_COUNT = 3

; Channels A-F
OPN_BGM_CHANNEL_COUNT = 6
; Channels G-J
PSG_BGM_CHANNEL_COUNT = 3
; Channels KOM
OPN_SFX_CHANNEL_COUNT = SFX_CHANNEL_COUNT
; Channels N-P
PSG_SFX_CHANNEL_COUNT = SFX_CHANNEL_COUNT

TOTAL_BGM_CHANNEL_COUNT = OPN_BGM_CHANNEL_COUNT+PSG_BGM_CHANNEL_COUNT
TOTAL_SFX_CHANNEL_COUNT = OPN_SFX_CHANNEL_COUNT+PSG_SFX_CHANNEL_COUNT
TOTAL_CHANNEL_COUNT = TOTAL_BGM_CHANNEL_COUNT+TOTAL_SFX_CHANNEL_COUNT

NVM_STACK_DEPTH = 5

NVM_STATUS_INACTIVE = 0
NVM_STATUS_ACTIVE = 1

NVM_REST_DEFAULT = 12

NVM_BLOCK_PORTAMENTO_SKIP_FLAG = 80h

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
; TODO: loop stack
loop_ptr:       ds 2
loop_cnt:       ds 1
rest_val:       ds 1
rest_cnt:       ds 1

; Note settings
volume:         ds 1  ; really attenuation, summed with tl on key-on.
octave:         ds 1  ; stored as multiples of 8 to match block register.
portamento:     ds 1  ; rate of change for target_freq. If 0, it is instant.

NVM endstruct

;
; OPN-specific channel state
;
NVMOPN struct
nvmbase:        ds NVM.len

; Patch
patch_ptr:      ds 2
tl_conoffs:     ds 1  ; pre-multiplied jr table offset for tl setting (patch con * 2)
tl:             ds 4  ; TL values from when instrument was set.
pan:            ds 1  ; pan/ams/pms register.

; Portamento state (OPN)
now_freq:       ds 2
now_block:      ds 1  ; if negative, immediately adopts the target.
tgt_freq:       ds 2
tgt_block:      ds 1

; Key down stuff
key_pending:    ds 1  ; if true, awaiting a key on event.

pad:            ds 1

NVMOPN endstruct

;
; PSG-specific channel state.
;
NVMPSG struct
nvmbase:        ds NVM.len

envelope_ptr:   ds 2

NVMPSG endstruct

	IF	NVMPSG.len <> NVMOPN.len
;ERROR "PSG and OPN struct sizes differ!"
	ENDIF

NVMCONTEXT struct
global_volume:       ds 1
buffer_ptr:          ds 2
instrument_list_ptr: ds 2
pcm_list_ptr:        ds 2
NVMCONTEXT endstruct


; Header defining a header for a blob of track data (BGM or SFX).
; Two bytes preceed it with a word that contains the byte count of the data.
NEZINFO struct
ta:                    ds 2  ; Timer A value (PCM rate) (ignored for SFX)
tb:                    ds 1  ; Timer B value (tempo control) (ignored for SFX)
; Null-terminated lists that are relative to the start of the data blob.
track_list_offs:       ds 2  ; For SFX, these are the effect indices.
instrument_list_offs:  ds 2
macro_list_offs:       ds 2
NEZINFO endstruct
