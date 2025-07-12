;
; Work RAM begin
;
TmpStart:


AvmGlobal:      ds AVMG.len
	align	10h
AvmStart:
AvmOpnStart:
AvmOpnFx:       ds AVM.len * OPN_FX_CHANNEL_COUNT
AvmOpn:         ds AVM.len * OPN_CHANNEL_COUNT
AvmOpnEnd:
AvmPsgStart:
PsgChFx:        ds AVM.len * PSG_FX_CHANNEL_COUNT
PsgCh:          ds AVM.len * PSG_CHANNEL_COUNT
AvmPsgEnd:
AvmEnd:

TmpEnd:


StackStart:
	ds 64*2
StackEnd:
