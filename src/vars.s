;
; Work RAM begin
;
TmpStart:

FrameCnt:       ds 1
VblFlag:        ds 1

	align	20h
AvmGlobal:      ds AVMG.len
	align	20h
AvmOpn:         ds AVM.len * OPN_CHANNEL_COUNT
AvmOpnFx:       ds AVM.len * OPN_FX_CHANNEL_COUNT
PsgCh:          ds AVM.len * PSG_CHANNEL_COUNT
PsgChFx:        ds AVM.len * PSG_FX_CHANNEL_COUNT

TmpEnd:


StackStart:
	ds 64*2
StackEnd:
