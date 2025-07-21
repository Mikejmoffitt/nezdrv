start:
	call	opn_reset
	call	psg_reset
	call	nvm_init
	call	mailbox_init
	im	1
	ei
	ld	bc, 6
	ld	hl, sig_str
	ld	de, nez_signature
	ldir
	jp	mainloop

mem_clear_sub:
	; DE := hl + 1
	ld	e, l
	ld	d, h
	inc	de
	ld	(hl), 00h  ; First byte is initialized with clear value 00h
	ldir
	ret
