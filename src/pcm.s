;
; pcm_poll is at 8 so it may be called by `rst 8` via macro.
;

pcm_service macro
	ld	a, (OPN_BASE)
	rrca  ; Timer A status bit goes into carry
	jr	c, +
	rst	pcm_poll
+:
	endm

	org	08h
pcm_poll:
	; Ack timer A
	ld	a, OPN_REG_TCTRL
	ld	(OPN_ADDR0), a
	ld	a, OPN_TA_ACK
	ld	(OPN_DATA0), a
	ret
