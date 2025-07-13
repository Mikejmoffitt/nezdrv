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
	call	nvm_init
	call	nvm_load_track

main:
	; Wait for timer events.
	ld	a, (OPN_BASE)
	bit	1, a
	jr	nz, .run_nvm
	bit	0, a
	jr	z, main
	rst	pcm_poll
	jr	main

.run_nvm:
	; Ack timer B
	ld	a, OPN_REG_TCTRL
	ld	(OPN_ADDR0), a
	ld	a, OPN_TB_ACK
	ld	(OPN_DATA0), a

	call	nvm_poll
;	call	keydown_test_func
	jr	main
