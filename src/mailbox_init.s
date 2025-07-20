mailbox_init:
	ld	hl, MailBoxMemStart
	ld	bc, MailBoxMemEnd-MailBoxMemStart-1
	call	mem_clear_sub
	ld	hl, MailBoxReadySig
	ld	(hl), 'N'
	inc	hl
	ld	(hl), 'E'
	inc	hl
	ld	(hl), 'Z'
	ret

mem_clear_sub:
	; DE := hl + 1
	ld	e, l
	ld	d, h
	inc	de
	ld	(hl), 00h  ; First byte is initialized with clear value 00h
	ldir
	ret
