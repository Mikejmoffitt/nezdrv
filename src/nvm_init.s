; ------------------------------------------------------------------------------
;
; Initialization
;
; This function is only called once at startup.
;
; ------------------------------------------------------------------------------
nvm_init:
	call	nvm_bgm_channels_init
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

nvm_bgm_channels_init:
	ld	de, NVMBGM.len
	ld	hl, nvm_channel_id_tbl
	ld	iy, NvmBgm
	ld	b, TOTAL_BGM_CHANNEL_COUNT
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

; The SFX channels just need to be made quiet. They will be initialized using
; nvm_init_sub and receive manual channel ID assignment.
nvm_sfx_channels_init:
	ld	de, NVMSFX.len
	ld	hl, NvmSfx+NVM.status
	ld	b, SFX_CHANNEL_COUNT
	xor	a
-:
	ld	(hl), a
	add	hl, de
	djnz	-
	ret
