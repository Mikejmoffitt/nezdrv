;
; Driver main loop.
;

; hl = region
; bc = bytes

mainloop:
	ld	a, (MailBoxCommand+NEZMB.cmd)
	and	a
	jr	z, +
	call	mailbox_handle_cmd
+:

.vbl_flag_load:
	ld	a, 0FFh  ; to be overwritten as VblWaitFlag.
VblWaitFlag = .vbl_flag_load+1
	and	a
	jr	nz, +
	call	nez_run_sfx_sub
+:
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
	ld	b, OPN_BGM_CHANNEL_COUNT
	ld	iy, NvmOpnBgm
	ld	de, NVMOPN.len
	call	nvm_poll
	ld	b, PSG_BGM_CHANNEL_COUNT
	ld	iy, NvmPsgBgm
	ld	de, NVMPsg.len
	jp	nvm_poll

nez_run_sfx_sub:
	ld	a, 0FFh
	ld	(VblWaitFlag), a

	call	nvm_context_sfx_set
	ld	b, OPN_SFX_CHANNEL_COUNT
	ld	iy, NvmOpnSfx
	ld	de, NVMOPN.len
	call	nvm_poll
	ld	b, PSG_SFX_CHANNEL_COUNT
	ld	iy, NvmPsgSfx
	ld	de, NVMPSG.len
	call	nvm_poll

	; Update mute status of BGM channels
	ld	a, (NvmOpnSfx+NVM.status+NVMOPN.len*0)
	ld	(NvmOpnBgm+NVM.mute+NVMOPN.len*0), a
	ld	a, (NvmOpnSfx+NVM.status+NVMOPN.len*1)
	ld	(NvmOpnBgm+NVM.mute+NVMOPN.len*1), a
	ld	a, (NvmOpnSfx+NVM.status+NVMOPN.len*2)
	ld	(NvmOpnBgm+NVM.mute+NVMOPN.len*2), a
	ld	a, (NvmPsgSfx+NVM.status+NVMPSG.len*0)
	ld	(NvmPsgBgm+NVM.mute+NVMPSG.len*0), a
	ld	a, (NvmPsgSfx+NVM.status+NVMPSG.len*1)
	ld	(NvmPsgBgm+NVM.mute+NVMPSG.len*1), a
	ld	a, (NvmPsgSfx+NVM.status+NVMPSG.len*2)
	ld	(NvmPsgBgm+NVM.mute+NVMPSG.len*2), a
	ret
