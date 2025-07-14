; ------------------------------------------------------------------------------
;
; Track Load
;
; You should call nez_load_sfx_data first as it sets BgmBufferPtr.
;
; ------------------------------------------------------------------------------

; hl = track head
; clobbers de, a
nez_load_sfx_data:
	call	nvm_context_sfx_set
	call	nez_load_buffer_sub
	; Timers are not set.
	ld	(BgmBufferPtr), de  ; This sets up the BGM buffer address.
	call	nez_load_standard_rebase_sub

	ld	de, (InstrumentListPtr)
	ld	(SfxInstrumentListPtr), de
	ld	de, (PcmListPtr)
	ld	(SfxPcmListPtr), de

	; Sfx track pointer is needed to handle cue commands.
	ld	de, NEZINFO.track_list_offs
	call	nez_get_list_head_sub
	ld	(SfxTrackListPtr), hl

	ret

; hl = track head
; clobbers de, a
nez_load_bgm_data:
	call	nvm_context_bgm_set
	call	nez_load_buffer_sub
	call	nez_load_standard_rebase_sub
	call	nez_bgm_assign_tracks_sub
	call	nez_bgm_set_timers_sub
	ld	de, (InstrumentListPtr)
	ld	(BgmInstrumentListPtr), de
	ld	de, (PcmListPtr)
	ld	(BgmPcmListPtr), de
	ret

; hl = buffer
nez_load_buffer_sub:
	ld	de, (BufferPtr)
	; The first two bytes contain (byte count - 2).
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	inc	hl
	ldir
	ret

; input: hl pointing to a list head offset
; output: hl pointing at the head of the list itself
nez_hl_deref_relative_offs_sub:
	ld	a, (hl)
	ld	e, a
	inc	hl
	ld	a, (hl)
	ld	d, a
	ld	hl, (BufferPtr)
	add	hl, de
	ret

; The list is null-terminated.
nez_bgm_assign_tracks_sub:
	; Track list = hl + NEZINFO.track_list_offs
	ld	hl, (BufferPtr)
	ld	de, NEZINFO.track_list_offs
	add	hl, de  ; hl now points to the track list offset value.
	call	nez_hl_deref_relative_offs_sub

	; Set up tracks by walking the track list.
	ld	iy, NvmBgmStart
.loop:
	; Load DE with the entry from the list.
	ld	a, (hl)
	ld	e, a
	inc	hl
	ld	a, (hl)
	ld	d, a
	inc	hl
	; see if pointer is null, and if so, stop assigning tracks.
	ld	a, e
	or	d
	ret	z
	; copy pointer and proceed
	ld	(iy+NVM.pc+1), d
	ld	(iy+NVM.pc), e
	ld	(iy+NVM.status), nvm_STATUS_ACTIVE
.next_track:
	ld	de, NVM.len
	add	iy, de
	jr	.loop
	ret

nez_bgm_set_timers_sub:
	; Set the timers.
	ld	hl, (BgmBufferPtr)
	ld	de, NEZINFO.ta
	add	hl, de
	ld	de, OPN_ADDR0
	ld	c, OPN_REG_TA_HI
	ld	b, 3
.loop:
	ld	a, c
	ld	(de), a  ; addr
	inc	de
	ld	a, (hl)
	ld	(de), a  ; data
	dec	de
	inc	hl
	inc	c
	djnz	.loop
	ret

;
; Rebasing the lists copied from the data. Be sure to set context first.
;
nez_load_standard_rebase_sub:
	call	nez_rebase_tracks
	call	nez_rebase_instruments
	jr	nez_rebase_pcm

nez_rebase_tracks:
	ld	de, NEZINFO.track_list_offs
	call	nez_get_list_head_sub
	jr	nez_rebase_relative_list_sub

nez_rebase_instruments:
	ld	de, NEZINFO.instrument_list_offs
	call	nez_get_list_head_sub
	ld	(InstrumentListPtr), hl
	jr	nez_rebase_relative_list_sub

nez_rebase_pcm:
	ld	de, NEZINFO.pcm_list_offs
	call	nez_get_list_head_sub
	ld	(PcmListPtr), hl
	jr	nez_rebase_relative_list_sub

; de = NEZINFO offset
; returns head in hl
nez_get_list_head_sub:
	ld	hl, (BufferPtr)
	add	hl, de  ; hl now points to the instrument list
	jp	nez_hl_deref_relative_offs_sub


; rebases a relative offset list against BufferPtr (nullptr-terminated).
; hl = list head
nez_rebase_relative_list_sub:
	; Rebase the list.
	ld	de, (BufferPtr)
	; get hl into bc; we need it but will be doing math on hl.
	push	hl
	pop	bc
.rebase_loop:
	; Get instrument offset into hl
	ld	a, (bc)
	inc	bc
	ld	l, a
	ld	a, (bc)
	dec	bc
	ld	h, a
	; test if it's nullptr and finish if so.
	or	l
	jr	nz, +
	; nullptr gets written to the list as-is and we're done.
	ld	a, 00h
	ld	(bc), a
	inc	bc
	ld	(bc), a
	ret
+:
	; add bgm buffer pointer
	add	hl, de
	; and write it back
	ld	a, l
	ld	(bc), a
	inc	bc
	ld	a, h
	ld	(bc), a
	inc	bc
	jr	.rebase_loop
