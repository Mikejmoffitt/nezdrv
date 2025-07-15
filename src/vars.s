;
; Work RAM begin
;

NEZ_STACK_DEPTH = 16

TmpStart:

InstrumentListPtr:     ds 2  ; copied from either the sfx or bgm var
SfxInstrumentListPtr:  ds 2
BgmInstrumentListPtr:  ds 2

PcmListPtr:            ds 2
SfxPcmListPtr:         ds 2
BgmPcmListPtr:         ds 2

GlobalVolume:          ds 1
BgmGlobalVolume:       ds 1
SfxGlobalVolume:       ds 1

BufferPtr:             ds 2  ; copied from either the sfx or bgm var
SfxBufferPtr:          ds 2  ; UserBuffer
BgmBufferPtr:          ds 2  ; UserBuffer + size of SfxData

SfxTrackListPtr:       ds 2

CurrentBank:           ds 1

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

UserBuffer:




	org Z80_RAM_BYTES-0020h
MailBoxMemStart:
MailBoxSfxQueue:       ds TOTAL_SFX_CHANNEL_COUNT
	align	10h
MailBoxCommand:        ds 0Dh
MailBoxReadySig:       ds 03h
MailBoxMemEnd:
