;
; Work RAM begin
;

STACK_DEPTH = 10h

TmpStart:


TrackInfo:      ds TRACKINFO.len
	align	10h

AvmStart:
AvmBgmStart:
AvmOpnBgm:             ds AVM.len * OPN_BGM_CHANNEL_COUNT
AvmPsgBgm:             ds AVM.len * PSG_BGM_CHANNEL_COUNT
AvmSfxStart:
AvmOpnSfx:             ds AVM.len * OPN_SFX_CHANNEL_COUNT
AvmPsgSfx:             ds AVM.len * PSG_SFX_CHANNEL_COUNT

TmpEnd:

StackStart:
	ds STACK_DEPTH*2
StackEnd:
