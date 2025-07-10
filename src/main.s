;
; Driver main loop.
;

start:
	ld	sp, StackEnd ; 3 bytes
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
	ld	iy, AvmOpn+AVM.len*3
	ld	de, avm_data_testtrk
	call	avm_set_head
	ld	iy, AvmOpn+AVM.len*2
	ld	de, avm_data_testtrk2
	call	avm_set_head

	; Set up channel 0 with a patch
	ld	hl, opnp_test
	ld	a, 0
	call	opn_set_patch
	ld	hl, opnp_test
	ld	a, 1
	call	opn_set_patch
	ld	hl, opnp_test
	ld	a, 2
	call	opn_set_patch

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
