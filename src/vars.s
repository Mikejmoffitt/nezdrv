;
; Work RAM begin
;
TmpStart:

AvmGlobal:      ds AVMG.len
AvmOpnFx:       ds AVM.len * OPN_FX_CHANNEL_COUNT
AvmOpn:         ds AVM.len * OPN_CHANNEL_COUNT
PsgChFx:        ds AVM.len * PSG_FX_CHANNEL_COUNT
PsgCh:          ds AVM.len * PSG_CHANNEL_COUNT

TmpEnd:


StackStart:
	ds 64*2
StackEnd:
