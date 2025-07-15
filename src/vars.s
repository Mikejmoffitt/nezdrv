;
; Work RAM begin
;

NEZ_STACK_DEPTH = 12

TmpStart:

BgmContext:            ds NVMCONTEXT.len
SfxContext:            ds NVMCONTEXT.len
CurrentContext:        ds NVMCONTEXT.len
; Sound effect specific
SfxTrackListPtr:       ds 2
; BGM Specific
BgmPlaying:            ds 1

	align	10h

; Playback channel state.
NvmStart:
NvmBgmStart:
NvmOpnBgm:             ds NVM.len * OPN_BGM_CHANNEL_COUNT
NvmPsgBgm:             ds NVM.len * PSG_BGM_CHANNEL_COUNT
NvmSfxStart:
NvmOpnSfx:             ds NVM.len * OPN_SFX_CHANNEL_COUNT
NvmPsgSfx:             ds NVM.len * PSG_SFX_CHANNEL_COUNT

TmpEnd:

StackStart:            ds 2*NEZ_STACK_DEPTH
StackEnd:

; This is where user data (tracks, instruments, etc) lives.
UserBuffer:




	org Z80_RAM_BYTES-0020h
MailBoxMemStart:
MailBoxSfxQueue:       ds TOTAL_SFX_CHANNEL_COUNT
	align	10h
MailBoxCommand:        ds 0Dh
MailBoxReadySig:       ds 03h
MailBoxMemEnd:
