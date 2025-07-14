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

;
; a = bank number (covering bits 15-21) total of 101 cycles.
;
; A way to slightly speed this up would be to pre-calculate something like this,
; accomplishing the bank switch in "only" 73 cycles at the expense of 12 bytes.
; Of course, that's only possible for constant data. However, a table of bank
; switching routines could be set up and modified based on the correpsonding
; samples being switched.
;
; ld	hl, BANK_SEL  ; 6001h      | 10 cycles, three bytes
; ld	(hl), h                    | 7 cycles, one byte
; From here on, eight bits are assembled to load either h or l based on
; the established bank index. Register h forms a functioning 0 while l is a 1.
; ld	(hl), h/l     ; Bit 23 (0) |  7 cycles, one byte
;
; This occurs in a total of 101 cycles.
bank_set_inline	macro
	ld	hl, BANK_SEL  ; 10 cycles

	ld	(hl), a       ; 7 cycles; A15 bit
	rept	7
	rrca                  ; 4 cycles
	ld	(hl), a       ; 7 cycles; A16-A22 bits
	endm
	ld	(hl), l       ; 7 cycles; A23 bit, a constant 0

	endm
