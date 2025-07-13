;
; Work RAM begin
;

TmpStart:

TrackListBank:         ds 1
TrackListPtr:          ds 2

SfxListBank:           ds 1
SfxListPtr:            ds 2

PcmListBank:           ds 1
PcmListPtr:            ds 1

CurrentBank:           ds 1

TrackInfo:      ds TRACKINFO.len
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

	org Z80_RAM_BYTES-NEZMAILBOX.len
StackEnd:
MailBox:               ds NEZMAILBOX.len
