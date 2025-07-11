add_a_to_hl	macro
	add	a, l
	ld	l, a
	adc	a, h
	sub	l
	ld	h, a
	endm

sub_a_from_hl	macro
	neg	a
	jr	z, +
	dec	h
	add_a_to_hl
+:
	endm

add_a_to_bc	macro
	add	a, b
	ld	b, a
	adc	a, c
	sub	b
	ld	c, a
	endm

add_a_to_de	macro
	add	a, d
	ld	d, a
	adc	a, e
	sub	d
	ld	e, a
	endm

add_a_to_iy	macro
	add	a, iyl
	ld	iyl, a
	adc	a, iyh
	sub	iyl
	ld	iyh, a
	endm

add_a_to_ixy	macro
	add	a, ixl
	ld	ixl, a
	adc	a, ixh
	sub	ixl
	ld	ixh, a
	endm

compare_hl_r16 macro regname
	or a
	sbc hl, regname
	add hl, regname
	endm

; a = offset
jptbl_dispatch	macro
	ld	($+4), a
	jr	$+0  ; overwritten by modifying code
	endm
