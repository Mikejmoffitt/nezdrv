; ------------------------------------------------------------------------------
;
; NEZDRV communication mailbox spec.
;
; ------------------------------------------------------------------------------
;
; Communications occur through two dedicated areas of memory for cross-CPU
; data exchange. The command mailbox is for handling data initialization and
; configuration, while the sound effect cue mailbox is for triggering effects.
;

NEZ_MAILBOX_ADDR = Z80_RAM_BYTES-20h

; ------------------------------------------------------------------------------
;
; Sound Effect Cue Mailbox
;
; ------------------------------------------------------------------------------
;
; As the engine can handle one sound effect per dedicated channel, there is one
; command input per channel. A value of $FF means no sample is to be played.

NEZMB_EFFECT_CUE struct
	opn_a: ds 1
	opn_b: ds 1
	opn_c: ds 1
	psg_a: ds 1
	psg_b: ds 1
NEZMB_EFFECT_CUE ends

; ------------------------------------------------------------------------------
;
; Command Mailbox
;
; ------------------------------------------------------------------------------
;
; The mailbox lives at $1FF0. The first byte is the command, followed by data
; which varies based on the command (see the structure overlays).
;
; To initialize:
;
; 1) Load the NEZDRV binary into Z80 memory at 0000h and release reset.
; 2) Wait for the mailbox last three bytes to read "NEZ"
; 3) Issue NEZ_CMD_LOAD_SFX with a pointer to the SFX data.
; 4) Issue NEZ_CMD_LOAD_PCM for each PCM sample.
;
; To play BGM:
;
; 5) Issue NEZ_CMD_LOAD_BGM with a pointer to the BGM data.
;
; BGM can be stopped using a command, or simply another can be loaded and played
; without having to do any other preparation. SFX and PCM should not be loaded
; more than once as that data is expected to be permanent.


NEZ_CMD_READY          = 0
NEZ_CMD_LOAD_SFX       = 1
NEZ_CMD_LOAD_PCM       = 2
NEZ_CMD_LOAD_BGM       = 3
NEZ_CMD_PLAY_BGM       = 4
NEZ_CMD_PAUSE_BGM      = 5
NEZ_CMD_STOP_BGM       = 6
NEZ_CMD_STOP_SFX       = 7
NEZ_CMD_SET_VOLUME_SFX = 8
NEZ_CMD_SET_VOLUME_BGM = 9

; The last three bytes are used for the sound driver to indicate it has fully
; initialized itself. After initializing the driver, check that the following
; bytes contain the expected values:

; 1FFDh = 'N'
; 1FFEh = 'E'
; 1FFFh = 'Z'


; ------------------------------------------------------------------------------
;
; 00h NEZ_CMD_READY
;
; ------------------------------------------------------------------------------
;
; No parameters are needed. When the 68K side sees this, it means the driver is
; ready for a new command.
;
; Mailbox overlay: NEZMB
;
; ------------------------------------------------------------------------------
;
; 01h NEZ_CMD_LOAD_SFX
;
; ------------------------------------------------------------------------------
;
; A binary blob of data for sound effects is copied into memory. This will
; invalidate any track data that is loaded, and commands will stop. BGM can be
; loaded after SFX have been installed.
;
; Mailbox overlay: NEZMB_CMD_LOAD
;
; ------------------------------------------------------------------------------
;
; 02h NEZ_CMD_LOAD_PCM
;
; ------------------------------------------------------------------------------
;
; A pointer to a single PCM sample address is issued. Each one is added to an
; internal list of PCM effects. Each PCM sample reference eats 3 bytes of memory
; that could go towards BGM and SFX data, but the true upper limit is 85.
;
; Mailbox overlay: NEZMB_CMD_LOAD
;
; ------------------------------------------------------------------------------
;
; 03h NEZ_CMD_LOAD_BGM
;
; ------------------------------------------------------------------------------
;
; A binary blob of data for one BGM track is copied into memory. This should be
; called after sound effects are loaded, if they are to be used. It is possible
; to call this command again without special preparation to prepare to play a
; different BGM.
;
; After loading, if the play flag is set, BGM will play after loading.
;
; Mailbox overlay: NEZMB_CMD_LOAD
;
; ------------------------------------------------------------------------------
;
; 04h NEZ_CMD_PLAY_BGM
;
; ------------------------------------------------------------------------------
;
; The current loaded BGM is played.
;
; Mailbox overlay: NEZMB
;
; ------------------------------------------------------------------------------
;
; 06h NEZ_CMD_STOP_BGM
;
; ------------------------------------------------------------------------------
;
; The current BGM is stopped.
;
; Mailbox overlay: NEZMB
;
; ------------------------------------------------------------------------------
;
; 07h NEZ_CMD_PAUSE_BGM
;
; ------------------------------------------------------------------------------
;
; The current BGM is paused.
;
; Mailbox overlay: NEZMB
;
; ------------------------------------------------------------------------------
;
; 07h NEZ_CMD_STOP_SFX
;
; ------------------------------------------------------------------------------
;
; Sound effects are stopped.
;
; Mailbox overlay: NEZMB
;
; ------------------------------------------------------------------------------
;
; 08h NEZ_CMD_SET_VOLUME_SFX
;
; ------------------------------------------------------------------------------
;
; The global volume for sound effects is set.
;
; Mailbox overlay: NEZMB_CMD_VOLUME
;
; ------------------------------------------------------------------------------
;
; 09h NEZ_CMD_SET_VOLUME_BGM
;
; ------------------------------------------------------------------------------
;
; The global volume for BGM is set.
;
; Mailbox overlay: NEZMB_CMD_VOLUME
;


; Structure overlays for mailbox memory

NEZMB struct
	cmd:	ds 1
NEZMB ends

NEZMB_CMD_LOAD struct
	cmd:	ds 1
	bank:	ds 1
	ptr:	ds 2
	play:	ds 1  ; flag for BGM. If true, plays after being loaded.
NEZMB_CMD_LOAD ends

NEZMB_CMD_PLAY struct
	cmd:	ds 1
	num:	ds 2  ; little-endian
	chan:	ds 1  ; ignored for BGM.
NEZMB_CMD_PLAY ends

NEZMB_CMD_VOLUME struct
	cmd:	ds 1
NEZMB_CMD_VOLUME ends
