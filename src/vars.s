;
; Work RAM begin
;

NEZ_STACK_DEPTH = 16

TmpStart:

InstrumentListPtr:     ds 2  ; copied from either the sfx or bgm var
SfxInstrumentListPtr:  ds 2
BgmInstrumentListPtr:  ds 2

BufferPtr:             ds 2  ; copied from either the sfx or bgm var
SfxBufferPtr:          ds 2  ; UserBuffer
BgmBufferPtr:          ds 2  ; UserBuffer + size of SfxData

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

StackStart:            ds 2*NEZ_STACK_DEPTH
StackEnd:

UserBuffer:




	org Z80_RAM_BYTES-NEZMAILBOX.len
MailBox:               ds NEZMAILBOX.len
