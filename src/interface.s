; ------------------------------------------------------------------------------
;
; Track Load
;
; You should call nez_load_sfx_data first.
;
; ------------------------------------------------------------------------------

; hl = track head
; clobbers de, a
nez_load_sfx_data:
	ld	de, SfxBuffer
	call	nez_load_inner_buffer_sub
	ld	(BgmBufferPtr), de
	ret

; hl = buffer
nez_load_inner_buffer_sub:
	; The first two bytes contain (byte count - 2).
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	inc	hl
	ldir
	ret

; hl = track head
; clobbers de, a
nez_load_bgm_data:
	push	hl
	call	nvm_bgm_reset
	call	opn_reset
	pop	hl

	; Copy all of the data.
	ld	de, (BgmBufferPtr)
	call	nez_load_inner_buffer_sub

	call	nez_bgm_set_timers_sub
	call	nez_bgm_assign_tracks_sub
	call	nez_bgm_rebase_instruments_sub

	; The PCM list... not sure what to do with it yet.
	ret

; input: hl pointing to a list head offset
; output: hl pointing at the head of the list itself
nez_hf_deref_relative_offs_sub:
	ld	a, (hl)
	ld	e, a
	inc	hl
	ld	a, (hl)
	ld	d, a
	ld	hl, (BgmBufferPtr)
	add	hl, de
	ret



nez_bgm_assign_tracks_sub:
	; Track list = hl + TRACKINFO.track_list_offs
	ld	hl, (BgmBufferPtr)
	ld	de, TRACKINFO.track_list_offs
	ld	b, TOTAL_BGM_CHANNEL_COUNT
	add	hl, de  ; hl now points to the track list offset value.
	call	nez_hf_deref_relative_offs_sub

	; Set up tracks by walking the track list.
	ld	iy, NvmBgmStart
-:
	; Load DE with the offset from the list.
	ld	a, (hl)
	ld	e, a
	inc	hl
	ld	a, (hl)
	ld	d, a
	inc	hl
	; see if pointer is null, and if so, skip it
	ld	a, e
	or	d
	jr	z, .skip_track

	; de now contains the list entry; sum with the base pointer value

	; copy pointer and set track to active
	push	hl
	ld	hl, (BgmBufferPtr)
	add	hl, de

	ld	a, h
	ld	(iy+NVM.pc+1), a
	ld	a, l
	ld	(iy+NVM.pc), a
	pop	hl
	ld	(iy+NVM.status), nvm_STATUS_ACTIVE
.skip_track:
	ld	de, NVM.len
	add	iy, de
	djnz	-
	ret

nez_bgm_set_timers_sub:
	; Set the timers.
	ld	hl, (BgmBufferPtr)
	ld	de, TRACKINFO.ta
	add	hl, de
	ld	de, OPN_ADDR0
	ld	c, OPN_REG_TA_HI
	ld	b, 3
-:
	ld	a, c
	ld	(de), a  ; addr
	inc	de
	ld	a, (hl)
	ld	(de), a  ; data
	dec	de
	inc	hl
	inc	c
	djnz	-
	ret

nez_bgm_rebase_instruments_sub:
	; Now hook up the instrument list.
	ld	hl, (BgmBufferPtr)
	ld	de, TRACKINFO.instrument_list_offs
	add	hl, de  ; hl now points to the instrument list
	call	nez_hf_deref_relative_offs_sub
	ld	(BgmInstrumentListPtr), hl
	; Rebase the list.
	ld	de, (BgmBufferPtr)
	ld	bc, (BgmInstrumentListPtr)
.instrument_rebase_loop:
	; Get instrument offset into hl
	ld	a, (bc)
	inc	bc
	ld	l, a
	ld	a, (bc)
	dec	bc
	ld	h, a
	; test if it's nullptr and finish if so.
	or	l
	ret	z
	; add bgm buffer pointer
	add	hl, de
	; and write it back.
	ld	a, l
	ld	(bc), a
	inc	bc
	ld	a, h
	ld	(bc), a
	inc	bc
	jr	.instrument_rebase_loop
	ret
