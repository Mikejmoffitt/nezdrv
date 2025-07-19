psg_reset:
	ld	hl, PSG
	ld	(hl), 09Fh  ; mute channel 0
	ld	(hl), 09Fh  ; mute channel 0
	ld	(hl), 09Fh  ; mute channel 0
	ld	(hl), 09Fh  ; mute channel 0
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
