; ------------------------------------------------------------------------------
;
; Initialization
;
; This function is only called once at startup.
;
; ------------------------------------------------------------------------------
nvm_init:
	call	nvm_bgm_channels_init
	call	nvm_sfx_channels_init
	; All buffers start at UserBuffer. It is expected that SFX and PCM are
	; set once, while BGM can be exchanged. It's also okay to omit SFX and
	; PCM loads.
	ld	hl, UserBuffer
	ld	(UserBufferLoadPtr), hl
	ld	(BgmContext+NVMCONTEXT.buffer_ptr), hl
	ld	(SfxContext+NVMCONTEXT.buffer_ptr), hl
	ld	(PcmListPtr), hl
	xor	a
	ld	(BgmContext+NVMCONTEXT.global_volume), a
	ld	(SfxContext+NVMCONTEXT.global_volume), a
	ret

nvm_opn_channel_id_tbl:
	db	0, 1, 2, 4, 5, 6
nvm_psg_channel_id_tbl:
	db	80h, 0A0h, 0C0h, 0E0h

nvm_bgm_channels_init:
	ld	de, NVMOPN.len
	ld	hl, nvm_opn_channel_id_tbl
	ld	iy, NvmOpnBgm
	ld	b, OPN_BGM_CHANNEL_COUNT
	call	nvm_channel_grp_init_sub
	ld	de, NVMPSG.len
	ld	hl, nvm_psg_channel_id_tbl
	ld	b, PSG_BGM_CHANNEL_COUNT
	ld	iy, NvmPsgBgm
	jr	nvm_channel_grp_init_sub

nvm_sfx_channels_init:
	ld	de, NVMOPN.len
	ld	hl, nvm_opn_channel_id_tbl
	ld	iy, NvmOpnSfx
	ld	b, OPN_SFX_CHANNEL_COUNT
	call	nvm_channel_grp_init_sub
	ld	de, NVMPSG.len
	ld	hl, nvm_psg_channel_id_tbl+2
	ld	b, PSG_SFX_CHANNEL_COUNT
	ld	iy, NvmPsgSfx
	jr	nvm_channel_grp_init_sub

; hl = channel id assignment tbl
; iy = start of block
; de = struct offset per
; b = count
nvm_channel_grp_init_sub:
-:
	call	nvm_reset_sub

	ld	a, (hl)
	inc	hl
	ld	(iy+NVM.channel_id), a

	add	iy, de
	djnz	-
	ret
