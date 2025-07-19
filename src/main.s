;
; Driver main loop.
;

; hl = region
; bc = bytes
mem_clear_sub:
	; DE := hl + 1
	ld	e, l
	ld	d, h
	inc	de
	ld	(hl), 00h  ; First byte is initialized with clear value 00h
	ldir
	ret

start:
	call	opn_reset
	call	psg_reset
	; Clear work RAM
	ld	hl, TmpStart
	ld	bc, TmpEnd-TmpStart-1
	call	mem_clear_sub
	call	nvm_init
	call	mailbox_init

main:
	; TODO: check mailbox
	ld	a, (MailBoxCommand+NEZMB.cmd)
	and	a
	jr	z, +
	call	mailbox_handle_cmd
+:
	; Wait for timer events.
	pcm_service  ; status exists in a and carry
	rrca  ; test bit B
	jr	nc, main

.run_nvm:
	; Ack timer B
	ld	hl, OPN_BASE
	ld	(hl), OPN_REG_TCTRL
	inc	hl
	ld	(hl), OPN_TB_ACK

	ld	a, (BgmPlaying)
	and	a
	jr	z, .stopped

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

	call	nvm_context_bgm_set
	ld	b, OPN_BGM_CHANNEL_COUNT
	ld	iy, NvmOpnBgm
	ld	de, NVMOPN.len
	call	nvm_poll

	ld	b, PSG_BGM_CHANNEL_COUNT
	ld	iy, NvmPsgBgm
	ld	de, NVMPsg.len
	call	nvm_poll
	jr	main

.stopped:
	jp	m, main ; don't reset state if just paused.
	call	nvm_bgm_reset
	jp	main
