; ------------------------------------------------------------------------------
;
; Pitch modulation
;
; The channel at iy has a target period or frequency (based on chip type) and
; a current "real" period/frequency (the "now_" prefix). Based on portamento /
; slide, vibrato, etc. this function will update the "now" data.
;
; This function is not responsible for actually writing to the hardware regs.
;
; in:
;      iy = NVM channel head
;
; ------------------------------------------------------------------------------

nvm_pitch:
	ld	a, (iy+NVM.channel_id)
	and	a
	jp	p, nvmopn_pitch

nvmpsg_pitch:
	ld	a, (iy+NVMPSG.tgt_period+1)
	ld	(iy+NVMPSG.now_period+1), a
	ld	a, (iy+NVMPSG.tgt_period)
	ld	(iy+NVMPSG.now_period), a
	ret

nvmopn_pitch:
	ld	a, (iy+NVM.portamento)
	or	a
	jr	nz, .port_change
	; Portamento of 0 = instant
	ld	a, (iy+NVMOPN.tgt_freq)
	ld	(iy+NVMOPN.now_freq), a
	ld	a, (iy+NVMOPN.tgt_freq+1)
	ld	(iy+NVMOPN.now_freq+1), a
	ld	a, (iy+NVMOPN.tgt_block)
	ld	(iy+NVMOPN.now_block), a
	ret

.port_change:
	ld	d, (iy+NVMOPN.now_freq+1)
	ld	e, (iy+NVMOPN.now_freq)
	ex	hl, de
	; Compare target block to now
	ld	a, (iy+NVMOPN.now_block)
	ld	b, (iy+NVMOPN.tgt_block)
	cp	b
	jr	c, .target_block_higher
	jp	z, .target_block_same
; Target block is an octave below. Freq sweeps down, then if the frequency dips
; below the OPN_NOTE_C threshhold, we decrement the octave and wrap freq.
.target_block_lower:
	; sub portamento from now freq
	ld	a, (iy+NVM.portamento)
	call	nvm_sub_a_from_hl_sub
	sub_a_from_hl
	; Is hl below OPN_NOTE_C?
	ld	de, OPN_NOTE_C
	compare_hl_r16 de
	jr	nc, .now_freq_hl_commit
	; if so, decrement now_block and add OPN_NOTE_C.
	ld	de, OPN_NOTE_C  ; for addition
	ld	a, (iy+NVMOPN.now_block)
	sub	08h
	jr	.new_block_mask_and_set

; Target block is an octave above. Freq sweeps up, then if it dips above
; OPN_NOTE_C*2, increment the octave and wrap req.
.target_block_higher:
	; add portamento to now freq
	ld	a, (iy+NVM.portamento)
	call	nvm_add_a_to_hl_sub
	; Is hl above OPN_NOTE_C*2?
	ld	de, OPN_NOTE_C*2
	compare_hl_r16 de
	jr	c, .now_freq_hl_commit
	; if so, increment now_block and subtract OPN_NOTE_C.
	ld	de, 10000h-OPN_NOTE_C  ; subtraction of OPN_NOTE_C
	ld	a, (iy+NVMOPN.now_block)
	add	a, 08h
.new_block_mask_and_set:
;	and	3Fh  ; TODO: Put back if we find upper bits harmful
	ld	(iy+NVMOPN.now_block), a
	add	hl, de
+:
	; Write back the freq (hl) and exit.
.now_freq_hl_commit:
	ex	de, hl
	jr	.now_freq_de_commit

.target_block_same:
	ld	d, (iy+NVMOPN.tgt_freq+1)
	ld	e, (iy+NVMOPN.tgt_freq)
	; Is the target frequency higher?
	compare_hl_r16 de
	ret	z  ; same block, same freq. get outta here
	jr	c, .target_freq_higher
.target_freq_lower:
	ld	a, (iy+NVM.portamento)
	call	nvm_sub_a_from_hl_sub
	; Did we surpass the target?
	compare_hl_r16 de
	jr	nc, .now_freq_hl_commit  ; nope
	; Adopt target and get out.
.now_freq_de_commit:
	ld	(iy+NVMOPN.now_freq+1), d
	ld	(iy+NVMOPN.now_freq), e
	ret
.target_freq_higher:
	ld	a, (iy+NVM.portamento)
	call	nvm_add_a_to_hl_sub
	; Did we surpass the target?
	compare_hl_r16 de
	jr	c, .now_freq_hl_commit  ; nope
	jr	.now_freq_de_commit  ; adopt target and get out.

nvm_add_a_to_hl_sub:
	add_a_to_hl
	ret

nvm_sub_a_from_hl_sub:
	sub_a_from_hl
	ret
