; a = command
mailbox_init:
	ld	hl, MailBoxMemStart
	ld	bc, MailBoxMemEnd-MailBoxMemStart
	call	mem_clear_sub
	ld	hl, MailBoxReadySig
	ld	(hl), 'N'
	inc	hl
	ld	(hl), 'E'
	inc	hl
	ld	(hl), 'Z'
	ret

mailbox_handle_cmd:
	ld	hl, MailBoxCommand+1  ; pass by command
	ld	b, a
	add	a, b
	add	a, b
	jptbl_dispatch
	jp	mbcmd_done             ; NEZ_CMD_READY
	jp	mbcmd_load_sfx         ; NEZ_CMD_LOAD_SFX
	jp	mbcmd_load_bgm         ; NEZ_CMD_LOAD_BGM
	jp	mbcmd_play_bgm         ; NEZ_CMD_PLAY_BGM
	jp	mbcmd_stop_bgm         ; NEZ_CMD_STOP_BGM
	jp	mbcmd_stop_sfx         ; NEZ_CMD_STOP_SFX
	jp	mbcmd_set_volume_sfx   ; NEZ_CMD_SET_VOLUME_SFX
	jp	mbcmd_set_volume_bgm   ; NEZ_CMD_SET_VOLUME_BGM

	; TODO
	jr	mbcmd_Done
mbcmd_load_bgm:
	push	hl
	call	nvm_bgm_reset
	pop	hl

	call	mbcmd_dataload_prep_sub

	; Command the loading of the BGM data
	push	hl
	ex	de, hl
	call	nez_load_bgm_data
	pop	hl

	; Play flag set?
	ld	a, (hl)
	and	a
	jp	z, mbcmd_done  ; nope - get out
	; TODO: command play
	jp	mbcmd_done

mbcmd_load_sfx:
mbcmd_play_bgm:         ; NEZ_CMD_PLAY_BGM
mbcmd_stop_bgm:         ; NEZ_CMD_STOP_BGM
mbcmd_stop_sfx:         ; NEZ_CMD_STOP_SFX
mbcmd_set_volume_sfx:   ; NEZ_CMD_SET_VOLUME_SFX
mbcmd_set_volume_bgm:   ; NEZ_CMD_SET_VOLUME_BGM
mbcmd_done:
	xor	a  ; NEZ_CMD_READY
	ld	(MailBoxCommand+NEZMB.cmd), a
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
