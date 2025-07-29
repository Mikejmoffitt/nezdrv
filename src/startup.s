start:
	di                           ; 1 byte
	im	1
	ld	sp, NEZ_MAILBOX_ADDR ; 3 bytes
	call	opn_reset
	call	psg_reset
	call	nvm_init
	call	mailbox_init
	ld	hl, nez_signature
	ld	(hl), 'N'
	inc	hl
	ld	(hl), 'E'
	inc	hl
	ld	(hl), 'Z'

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
