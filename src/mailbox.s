mailbox_init:
	ld	hl, MailBox
	ld	bc, NEZMB.len-1
	call	mem_clear_sub
	ret

mailbox_update_sfx:
	ld	hl, MailBox+NEZMB.sfx
	ld	b, SFX_CHANNEL_COUNT
.loop:
	ld	a, (hl)
	and	a
	jr	z, .next
	push	bc
	push	hl
	dec	a
	call	nvm_sfx_play_by_cue
	pop	hl
	pop	bc
	xor	a
	ld	(hl), a
.next:
	inc	hl
	djnz	.loop
	ret


mailbox_handle_cmd:
	ld	hl, MailBox+1  ; pass by command
	ld	b, a
	add	a, b
	add	a, b
	jptbl_dispatch
	jp	mbcmd_done             ; NEZ_CMD_READY
	jp	mbcmd_load_sfx         ; NEZ_CMD_LOAD_SFX
	jp	mbcmd_load_pcm         ; NEZ_CMD_LOAD_PCM
	jp	mbcmd_play_bgm         ; NEZ_CMD_PLAY_BGM
	jp	mbcmd_pause_bgm        ; NEZ_CMD_PAUSE_BGM
	jp	mbcmd_resume_bgm       ; NEZ_CMD_RESUME_BGM
	jp	mbcmd_stop_bgm         ; NEZ_CMD_STOP_BGM
	jp	mbcmd_stop_sfx         ; NEZ_CMD_STOP_SFX
	jp	mbcmd_set_volume_sfx   ; NEZ_CMD_SET_VOLUME_SFX
	jp	mbcmd_set_volume_bgm   ; NEZ_CMD_SET_VOLUME_BGM

mbcmd_play_bgm:          ; NEZ_CMD_LOAD_BGM
	push	hl
	call	nvm_bgm_reset
	pop	hl

	; Command the loading of the BGM data
	call	mbcmd_dataload_prep_sub
	push	hl

	ex	de, hl
	call	nez_load_bgm_data
	pop	hl

	; Move playing state into BgmPlaying.
	ld	a, 01h
.play_commit:
	ld	(BgmPlaying), a
	jp	mbcmd_done

mbcmd_load_sfx:          ; NEZ_CMD_LOAD_SFX
	; Command the loading of the SFX data
	call	mbcmd_dataload_prep_sub

	push	hl
	ex	de, hl
	call	nez_load_sfx_data
	pop	hl

	jr	mbcmd_done

mbcmd_load_pcm:          ; NEZ_CMD_LOAD_PCM
	call	nez_load_pcm_sample
	jr	mbcmd_done

mbcmd_resume_bgm:        ; NEZ_CMD_RESUME_BGM
	ld	a, (BgmPlaying)
	and	a, 7Fh
	jr	mbcmd_play_bgm.play_commit

mbcmd_pause_bgm:        ; NEZ_CMD_PAUSE_BGM
	ld	a, (BgmPlaying)
	or	a, 80h
	jr	mbcmd_play_bgm.play_commit

mbcmd_stop_bgm:         ; NEZ_CMD_STOP_BGM
	xor	a
	jr	mbcmd_play_bgm.play_commit

mbcmd_stop_sfx:         ; NEZ_CMD_STOP_SFX
	; TODO
	jr	mbcmd_done

mbcmd_set_volume_sfx:   ; NEZ_CMD_SET_VOLUME_SFX
	ld	a, (hl)
	ld	(SfxContext+NVMCONTEXT.global_volume), a
	jr	mbcmd_done

mbcmd_set_volume_bgm:   ; NEZ_CMD_SET_VOLUME_BGM
	ld	a, (hl)
	ld	(BgmContext+NVMCONTEXT.global_volume), a
	jr	mbcmd_done

mbcmd_done:
	xor	a  ; NEZ_CMD_READY
	ld	(MailBox+NEZMB.cmd), a
	ret

; input:  hl = start of bank load cmd + 1 (hl is pointing at the bank bit)
; output: de = start of data to read; bank set appropriately.
mbcmd_dataload_prep_sub:
	ld	a, (hl)  ; bank
	inc	hl
	push	hl
	call	bank_set
	pop	hl
	; Load the pointer within the space at 8000h
	ld	e, (hl)  ; track pointer
	inc	hl
	ld	d, (hl)
	inc	hl
	ret
