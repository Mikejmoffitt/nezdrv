
nvm_op_note:
	ld	b, a  ; back up the note data in b

	ld	a, (iy+NVM.channel_id)
	and	a  ; test if PSG (id >= 80h)
	jp	p, nvmopn_op_note

nvmpsg_op_note:
	and	a, 1Fh  ; just index
	call	nvm_note_calc_transpose
	ld	a, b    ; restore note
	call	nvmpsg_note_set_env_sub
	ld	a, b    ; restore note
	exx  ; avoid pushing hl and bc
	ld	c, (iy+NVM.octave)
	call	psg_calc_period
	ld	(iy+NVMPSG.tgt_period+1), h
	ld	(iy+NVMPSG.tgt_period), l
	exx
	jp	nvm_op_note_setrest


; a = note
nvmpsg_note_set_env_sub:
.set_key_on:
	and	a, NVM_NOTE_NO_KEY_ON_FLAG
	ret	nz
	ld	a, (iy+NVM.instrument_ptr+0)
	ld	(iy+NVMPSG.env_ptr+0), a
	ld	a, (iy+NVM.instrument_ptr+1)
	ld	(iy+NVMPSG.env_ptr+1), a
	ld	a, 01h
	ld	(iy+NVMPSG.key_on), a
	ret


nvmopn_op_note:
	; Volume and pan control
	ld	a, (iy+NVM.mute)
	and	a
	jp	m, .muted
	jr	z, .unmuted

	; not muted, but nonzero - that's the restore case.
	ld	d, (iy+NVM.instrument_ptr+1)
	ld	e, (iy+NVM.instrument_ptr)
	push	bc
	push	hl
	call	nvm_load_inst.opn_apply
	pop	hl
	pop	bc
	ld	(iy+NVM.mute), NVM_MUTE_NONE
.unmuted:
	call	nvmopn_tlmod
	call	nvmopn_set_mod_sub.direct
.muted:

	; Mark pending key press (if applicable)
	ld	a, b    ; restore note
	and	a, NVM_NOTE_NO_KEY_ON_FLAG
	xor	NVM_NOTE_NO_KEY_ON_FLAG
	ld	(iy+NVMOPN.key_pending), a

	;
	; Set target octave and frequency.
	;

	; Note lookup
	ld	a, b    ; restore note
	and	a, 1Fh  ; just index

	call	nvm_note_calc_transpose
	; a now holds usable note index, and c the octave.

	; Turn C into block register value and adopt value.
	or	a  ; clear carry
	rl	c
	rl	c
	rl	c
	ld	(iy+NVMOPN.tgt_block), c

	exx  ; avoid pushing hl and bc

	; a now holds note modified by transposition
	ld	hl, opn_freq_tbl
	ld	e, a    ; offset freq tbl index with de
	ld	d, 00h
	add	hl, de
	ld	a, (hl)
	ld	(iy+NVMOPN.tgt_freq), a
	inc	hl
	ld	a, (hl)
	ld	(iy+NVMOPN.tgt_freq+1), a

	; If note was off before, skip portamento.
	ld	a, (iy+NVMOPN.now_block)
	and	a
	jp	p, +
	ld	a, (iy+NVMOPN.tgt_block)
	ld	(iy+NVMOPN.now_block), a
	ld	a, (iy+NVMOPN.tgt_freq)
	ld	(iy+NVMOPN.now_freq), a
	ld	a, (iy+NVMOPN.tgt_freq+1)
	ld	(iy+NVMOPN.now_freq+1), a
+:
	exx

nvm_op_note_setrest:
	; Optional rest duration byte
	ld	a, b
	and	a, nvm_NOTE_REST_FLAG
	jp	nz, nvm_op_rest

	; Else just adopt the default rest value.
	ld	a, (iy+NVM.rest_val)
	ld	(iy+NVM.rest_cnt), a
	jp	nvm_op_finished_yield

; in:  a: note value index (raw note b & 1Fh)
;     iy: nvm struct
; out: a: updated note value
;      c: effective octave
nvm_note_calc_transpose:
	; Apply transpose and set octave.
	ld	c, (iy+NVM.octave)
	add	a, (iy+NVM.transpose)
	; if transpose has taken us out of range modify octave and continue
.tpcheck:
	and	a
	jp	m, .tpbelow  ; gone below 0?
	cp	(NVM_NOTE_LIM)&1Eh
	jr	c, .tpok
.tpabove:
	sub	(NVM_NOTE_LIM)&1Eh
	inc	c
	jr	.tpcheck
.tpbelow:
	add	a, (NVM_NOTE_LIM)&1Eh
	dec	c
	jr	.tpcheck
.tpok:
	ret
