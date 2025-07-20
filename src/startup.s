start:
	call	opn_reset
	call	psg_reset
	call	mailbox_init
	call	nvm_init
	im	1
	ei
	jp	mainloop
