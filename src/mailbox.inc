;
; NEZDRV communication mailbox spec.
;

NEZ_CMD_NONE = 0
NEZ_CMD_LOAD_BGM = 1
NEZ_CMD_LOAD_SFX = 2
NEZ_CMD_LOAD_PCM = 3
NEZ_CMD_PLAY_BGM = 4
NEZ_CMD_PLAY_SFX = 5
NEZ_CMD_STOP_BGM = 6
NEZ_CMD_STOP_SFX = 7

NEZMAILBOX struct
arg_bank:      ds 1
arg_ptr:       ds 2
arg_bytes:     ds 2
cmd:           ds 1
NEZMAILBOX endstruct
