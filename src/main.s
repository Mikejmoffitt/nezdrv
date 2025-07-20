;
; Driver main loop.
;

; hl = region
; bc = bytes

mainloop:
	ld	a, (MailBox+NEZMB.cmd)
	and	a
	call	nz, mailbox_handle_cmd

.vbl_flag_load:
	ld	a, 0FFh  ; to be overwritten as VblWaitFlag.
VblWaitFlag = .vbl_flag_load+1
	and	a
	call	z, nez_run_sfx_sub
	; Wait for timer events.
	pcm_service  ; status exists in a and carry
	rrca  ; test bit B
	jr	nc, mainloop

	; Ack timer B
	ld	hl, OPN_BASE
	ld	(hl), OPN_REG_TCTRL
	inc	hl
	ld	(hl), OPN_TB_ACK

	call	nez_run_bgm_sub

	jr	mainloop



nez_run_bgm_sub:
	; Is music stopped or paused?
.bgm_playing_load:
	ld	a, 00h ; to be overwritten.
BgmPlaying = .bgm_playing_load+1
	and	a
	ret	m  ; just paused; return without playing.
	jr	nz, +  ; playing
	jp	nvm_bgm_reset
+:
	call	nvm_context_bgm_set
	ld	b, TOTAL_BGM_CHANNEL_COUNT
	ld	iy, NvmBgm
	ld	de, NVMBGM.len
	call	nvm_poll

nez_run_sfx_sub:
	ld	a, 0FFh
	ld	(VblWaitFlag), a

	call	nvm_context_sfx_set

	ld	b, SFX_CHANNEL_COUNT
	ld	iy, NvmSfx
	ld	de, NVMSFX.len
	call	nvm_poll
	ret
