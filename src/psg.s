psg_reset:
	ld	hl, PSG
	ld	(hl), 09Fh  ; mute channel 0
	ld	(hl), 0BFh  ; mute channel 1
	ld	(hl), 0DFh  ; mute channel 2
	ld	(hl), 0FFh  ; mute channel 3
	ret


; in:   a: note value
;       c: octave
; out: hl: period value
psg_calc_period:
	ld	hl, nvmpsg_period_tbl
	and	a, 1Fh  ; index into freq table
	ld	e, a    ; offset freq tbl index with de
	ld	d, 00h
	add	hl, de  ; hl now points at freq.
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ex	de, hl  ; hl now has the freq.
	ld	a, c
	add	a, c
	jptbl_dispatch
	jr	.set_period  ; octave 0
	jr	.oct1
	jr	.oct2
	jr	.oct3
	jr	.oct4
	jr	.oct5
	jr	.oct6
	jr	.oct7
; what is an octave adjustment? a miserable pile of right shifts
.oct7:
	xor	a
	jr	.oct7_a
.oct6:
	xor	a
	jr	.oct6_a
.oct5:
	xor	a
	add	hl, hl
	rla
.oct6_a:
	add	hl, hl
	rla
.oct7_a:
	add	hl, hl
	rla
	ld	l, h
	ld	h, a
	jr	.set_period
.oct4:
	srl	h
	rr	l
.oct3:
	srl	h
	rr	l
.oct2:
	srl	h
	rr	l
.oct1:
	srl	h
	rr	l
.set_period:
	ret

	IF NEZ_HICLK == FALSE
nvmpsg_period_tbl:
	dw	851*2  ; C
	dw	803*2
	dw	758*2
	dw	715*2
	dw	675*2
	dw	637*2
	dw	601*2
	dw	568*2
	dw	536*2
	dw	506*2
	dw	477*2
	dw	450*2  ; B
	
	ELSE
; With the Z80 at 7.670434MHz (up from 3.579545) some adjustment is needed.
nvmpsg_period_tbl:
	dw	1824*2  ; C
	dw	1721*2
	dw	1625*2
	dw	1532*2
	dw	1446*2
	dw	1365*2
	dw	1288*2
	dw	1217*2
	dw	1149*2
	dw	1084*2
	dw	1022*2
	dw	964*2  ; B

	ENDIF  ; NEZ_HICLK
