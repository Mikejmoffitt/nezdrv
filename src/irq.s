
	IF	$ >= 0038h
	ERROR "PC has overrun V-IRQ address!"
	ENDIF

	org	0038h
vbl_irq_handler:
	ex	af, af'
	xor	a
	ld	(VblWaitFlag), a
	ex	af, af'
	ei
	ret

