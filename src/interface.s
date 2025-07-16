; ------------------------------------------------------------------------------
;
; Track Load
;
; You should call nez_load_sfx_data first as it sets the BGM buffer pointer.
;
; ------------------------------------------------------------------------------

; Memory use:
;
; engine:
; [code]
; [work RAM]
; user buffer:
; [sfx data]
; [pcm list]
; [bgm data]*
;
; First SFX data is loaded. The sound effect buffer in principle always starts
; at the user buffer address, but that could change at some point.
; After loading SFX data, the PCM list pointer is set to the address tater.
;
; PCM data is loaded one sample at a time. The user buffer pointer is bumped
; with every addition.
;
; When BGM is loaded, it uses the user buffer pointer (which hangs out after
; the PCM list) and the buffer pointer does not change from thereon. This allows
; the BGM to be re-loaded without disturbing sound effects.
;


; hl = track head
; clobbers de, a
nez_load_sfx_data:
	call	nvm_context_sfx_set
	call	nez_load_buffer_sub
	ld	(PcmListPtr), de  ; PCM data
	call	nez_load_standard_rebase_sub

	ld	de, (CurrentContext+NVMCONTEXT.instrument_list_ptr)
	ld	(SfxContext+NVMCONTEXT.instrument_list_ptr), de

	; Sfx track pointer is needed to handle cue commands.
	ld	de, NEZINFO.track_list_offs
	call	nez_get_list_head_sub
	ld	(SfxTrackListPtr), hl

	ret

; hl = pointer to argument PCM data in mailbox
; the data is just copied as-is, as it is already formatted correctly.
; the user buffer is advanced.
nez_load_pcm_sample:
	ld	de, (UserBufferLoadPtr)
	rept	3
	ldi
	endm
	ld	(UserBufferLoadPtr), de
	ret

; hl = track head
; clobbers de, a
nez_load_bgm_data:
	call	nvm_context_bgm_set
	; BGM is designed to replace old BGM data, so the user buffer load ptr
	; is NOT advanced after loading.
	call	nez_load_buffer_sub
	ld	de, (CurrentContext+NVMCONTEXT.buffer_ptr)
	ld	(UserBufferLoadPtr), de
	call	nez_load_standard_rebase_sub
	call	nez_bgm_assign_tracks_sub
	call	nez_bgm_set_timers_sub
	ld	de, (CurrentContext+NVMCONTEXT.instrument_list_ptr)
	ld	(BgmContext+NVMCONTEXT.instrument_list_ptr), de
	ret

; hl = buffer
nez_load_buffer_sub:
	ld	de, (UserBufferLoadPtr)
	ld	(CurrentContext+NVMCONTEXT.buffer_ptr), de
	; The first two bytes contain (byte count - 2).
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	inc	hl
	ldir
	ld	(UserBufferLoadPtr), de
	ret

; input: hl pointing to a list head offset
; output: hl pointing at the head of the list itself
nez_hl_deref_relative_offs_sub:
	ld	a, (hl)
	ld	e, a
	inc	hl
	ld	a, (hl)
	ld	d, a
	ld	hl, (CurrentContext+NVMCONTEXT.buffer_ptr)
	add	hl, de
	ret

nez_bgm_assign_tracks_sub:
	; Track list = hl + NEZINFO.track_list_offs
	ld	hl, (CurrentContext+NVMCONTEXT.buffer_ptr)
	ld	de, NEZINFO.track_list_offs
	add	hl, de  ; hl now points to the track list offset value.
	call	nez_hl_deref_relative_offs_sub

	; Set up tracks by walking the track list.
	ld	iy, NvmOpnBgm
	ld	de, NVMOPN.len
	ld	b, OPN_BGM_CHANNEL_COUNT
	call	.loop
	ld	iy, NvmPsgBgm
	ld	de, NVMPSG.len
	ld	b, PSG_BGM_CHANNEL_COUNT
	; fall-through to .loop

.loop:
	ld	a, (hl)
	ld	(iy+NVM.pc), a
	inc	hl
	ld	a, (hl)
	ld	(iy+NVM.pc+1), a
	inc	hl
	ld	(iy+NVM.status), NVM_STATUS_ACTIVE
	add	iy, de
	djnz	.loop
	ret

nez_bgm_set_timers_sub:
	; Set the timers.
	ld	hl, (CurrentContext+NVMCONTEXT.buffer_ptr)
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
	push	hl
	pop	hl  ; just a delay
	djnz	.loop
	ret

;
; Rebasing the lists copied from the data. Be sure to set context first.
;
nez_load_standard_rebase_sub:
	call	nez_rebase_tracks
	jr	nez_rebase_instruments

nez_rebase_tracks:
	ld	de, NEZINFO.track_list_offs
	call	nez_get_list_head_sub
	jr	nez_rebase_relative_list_sub

nez_rebase_instruments:
	ld	de, NEZINFO.instrument_list_offs
	call	nez_get_list_head_sub
	ld	(CurrentContext+NVMCONTEXT.instrument_list_ptr), hl
	jr	nez_rebase_relative_list_sub

; de = NEZINFO offset
; returns head in hl
nez_get_list_head_sub:
	ld	hl, (CurrentContext+NVMCONTEXT.buffer_ptr)
	add	hl, de  ; hl now points to the instrument list
	jp	nez_hl_deref_relative_offs_sub


; rebases a relative offset list against the current buffer (nullptr-terminated).
; hl = list head
nez_rebase_relative_list_sub:
	; Rebase the list.
	ld	de, (CurrentContext+NVMCONTEXT.buffer_ptr)
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
