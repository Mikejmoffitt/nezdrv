start:
	call	opn_reset
	call	psg_reset
	call	nvm_init
	call	mailbox_init
	im	1
	ei
	jp	mainloop

mem_clear_sub:
	; DE := hl + 1
	ld	e, l
	ld	d, h
	inc	de
	ld	(hl), 00h  ; First byte is initialized with clear value 00h
	ldir
	ret
