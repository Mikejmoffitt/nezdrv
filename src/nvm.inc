;
; Audio VM state 0 one channel
;

; Channels A-F
OPN_BGM_CHANNEL_COUNT = 6
; Channels G-J
PSG_BGM_CHANNEL_COUNT = 4
; Channels KOM
OPN_SFX_CHANNEL_COUNT = 3
; Channels N-P
PSG_SFX_CHANNEL_COUNT = 4

TOTAL_BGM_CHANNEL_COUNT = OPN_BGM_CHANNEL_COUNT+PSG_BGM_CHANNEL_COUNT
TOTAL_SFX_CHANNEL_COUNT = OPN_SFX_CHANNEL_COUNT+PSG_SFX_CHANNEL_COUNT
TOTAL_CHANNEL_COUNT = TOTAL_BGM_CHANNEL_COUNT+TOTAL_SFX_CHANNEL_COUNT

NVM_STACK_DEPTH = 5

NVM_STATUS_INACTIVE = 0
NVM_STATUS_ACTIVE = 1
NVM_STATUS_MUTED = 2

NVM_REST_DEFAULT = 12

NVM_BLOCK_PORTAMENTO_SKIP_FLAG = 80h

;
; NEZDRV channel VM memory state.
;
NVM struct
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
stack:       ds NVM_STACK_DEPTH*2

; Note settings
volume:      ds 1  ; really attenuation, summed with tl on key-on.
octave:      ds 1  ; stored as multiples of 8 to match block register.
portamento:  ds 1  ; rate of change for target_freq. If 0, it is instant.

; Portamento state
now_freq:    ds 2
now_block:   ds 1  ; if negative, immediately adopts the target.
tgt_freq:    ds 2
tgt_block:   ds 1
; Key down stuff
key_pending: ds 1  ; if true, awaiting a key on event.

; Vibrato
vib_tbl:     ds 2  ; set when vibrato command is set.
vib_mag:     ds 1  ; vibrato magnitude.
vib_speed:   ds 1
vib_cnt:     ds 1  ;
vib_out:     ds 1

; OPN-specific state
patch_ptr:   ds 2
tl_conoffs:  ds 1  ; pre-multiplied jr table offset for tl setting (patch con * 2)
tl:          ds 4  ; TL values from when instrument was set.
pan:         ds 1  ; pan/ams/pms register.

NVM endstruct


; Header defining a header for a blob of track data (BGM or SFX).
; Two bytes preceed it with a word that contains the byte count of the data.
NEZINFO struct
ta:                    ds 2  ; Timer A value (PCM rate) (ignored for SFX)
tb:                    ds 1  ; Timer B value (tempo control) (ignored for SFX)
; Null-terminated lists that are relative to the start of the data blob.
track_list_offs:       ds 2  ; For SFX, these are the effect indices.
instrument_list_offs:  ds 2
pcm_list_offs:         ds 2
NEZINFO endstruct
