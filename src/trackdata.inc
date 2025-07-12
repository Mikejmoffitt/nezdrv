;
; Track header.
;

TRACKINFO struct
ta:                    ds 2  ; Timer A value (PCM rate)
tb:                    ds 1  ; Timer B value (tempo control)
track_list_ptr:        ds 2
instrument_list_ptr:   ds 2
TRACKINFO endstruct

NEZDRV_TRACK_LOAD_ADDR = 0A00h
