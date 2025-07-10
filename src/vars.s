;
; Work RAM begin
;
TmpStart:

	align	20h
AvmGlobal:      ds AVMG.len
	align	20h
AvmOpnFx:       ds AVM.len * OPN_FX_CHANNEL_COUNT
AvmOpn:         ds AVM.len * OPN_CHANNEL_COUNT
PsgChFx:        ds AVM.len * PSG_FX_CHANNEL_COUNT
PsgCh:          ds AVM.len * PSG_CHANNEL_COUNT

TmpEnd:


StackStart:
	ds 64*2
StackEnd:
