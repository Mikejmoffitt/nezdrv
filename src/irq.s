;
; V-IRQ - possibly used for sample buffering.
;
	IF WANT_IRQ == TRUE
	org	0038h
v_irq:
	ex	af, af'
	xor	a
	ld	(VblFlag), a
	ex	af, af'
	ei
	ret

; On another platform, we might want this, but on MD-Z80 we do not care.
;	org	0066h
;v_nmi:
;	retn
	ENDIF  ; WANT_IRQ
