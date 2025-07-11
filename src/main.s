;
; Driver main loop.
;

start:
	call	opn_init
	; Clear work RAM
	ld	hl, TmpStart
	; DE := hl + 1
	ld	e, l
	ld	d, h
	inc	de
	ld	(hl), 00h  ; First byte is initialized with clear value 00h
	ld	bc, TmpEnd-TmpStart
	ldir
	call	avm_init

	;
	; TEST DATA
	;

set_opn_track macro chid, avmptr
	ld	iy, AvmOpn+AVM.len*chid
	ld	de, avmptr
	call	avm_set_head
	endm

	set_opn_track 0, avm_data_test_bass
	set_opn_track 1, avm_data_test_bass_echo
	set_opn_track 4, avm_data_test_lead
	set_opn_track 5, avm_data_test_lead_echo

main:
	; Wait for timer events.
	ld	a, (OPN_BASE)
	bit	1, a
	jr	nz, .run_avm
	bit	0, a
	jr	z, main
	rst	pcm_poll
	jr	main

.run_avm:
	; Ack timer B
	ld	a, OPN_REG_TCTRL
	ld	(OPN_ADDR0), a
	ld	a, OPN_TB_ACK
	ld	(OPN_DATA0), a

	call	avm_poll
;	call	keydown_test_func
	jr	main
