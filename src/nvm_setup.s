; ------------------------------------------------------------------------------
;
; Resets generic NVM state for a single channel.
;
; in:
;      iy = NVM channel struct
;
; These functions are called when new BGM is played, a sound effect starts, etc.
;
; ------------------------------------------------------------------------------

; iy = NVM head
nvm_reset_sub:
	exx
	; Zero some defaults to inactive
	xor	a
	ld	(iy+NVM.status), a      ; inactive
	ld	(iy+NVM.mute), a        ; unmuted
	ld	(iy+NVM.portamento), a  ; no portamento

;	ld	(iy+NVM.vib_phase), a
;	ld	(iy+NVM.vib_cnt), a
;	ld	(iy+NVM.vib_mag), a
;	ld	(iy+NVM.vib_speed), a

	ld	(iy+NVM.rest_cnt), a
	ld	(iy+NVM.transpose), a   ; no transpose
	ld	(iy+NVM.volume), a      ; no attenuation
	; Set stack pointer
	push	iy
	pop	hl
	ld	de, NVM.stack
	add	hl, de
	ld	(iy+NVM.stack_ptr+1), h
	ld	(iy+NVM.stack_ptr), l
	; As well as loop stack ptr
	push	iy
	pop	hl
	ld	de, NVM.loop_stack-1  ; points right before it
	add	hl, de
	ld	(iy+NVM.loop_stack_ptr+1), h
	ld	(iy+NVM.loop_stack_ptr), l
	; channel default
	ld	(iy+NVM.rest_val), NVM_REST_DEFAULT
	exx
	ret

nvm_reset_by_type_sub:
	call	nvm_reset_sub
	ld	a, (iy+NVM.channel_id)
	and	a
	jp	p, .opn_specific
.psg_specific:
	xor	a
	ld	(iy+NVMPSG.key_on), a
	ret
.opn_specific:
	; default to both outputs, no modulation
	ld	(iy+NVMOPN.pan), OPN_PAN_L|OPN_PAN_R
	; No portamento for first note.
	ld	(iy+NVMOPN.now_block), 80h
	ret

; ------------------------------------------------------------------------------
;
; Resets all channels to an inactive state and silences sound generators.
;
; in:  (none)
; out: (one)
;
; ------------------------------------------------------------------------------
nvm_bgm_reset:
	pcm_poll_disable
	ld	b, TOTAL_BGM_CHANNEL_COUNT
	ld	iy, NvmBgm
	ld	de, NVMBGM.len
.loop:
	call	nvm_reset_by_type_sub
	add	iy, de
	djnz	.loop

	call	psg_reset
	jp	opn_reset

; ------------------------------------------------------------------------------
;
; in:
;       a = channel ID / enum value
; out:
;      ix = NVM pointer
;
; clobbers de, hl
;
; ------------------------------------------------------------------------------
nvm_channel_by_id:
	ld	d, 00h
	ld	e, a
	ld	hl, nvm_channel_ptr_tbl
	add	hl, de
	ld	a, (hl)
	ld	(.ix_load+2), a
	inc	hl
	ld	a, (hl)
	ld	(.ix_load+2+1), a
.ix_load:
	ld	ix, 6502h  ; immediate replaced with data from de
	ret


; Slight misnomer - "channel ID" here refers to the base register offset used
; when talking to the hardware. It is fortunate that they are distinct!
nvm_channel_id_tbl:
	db	0, 1, 2, 4, 5, 6        ; OPN 0, 1, 2, 3, 4, 5
	db	80h, 0A0h, 0C0h, 0E0h   ; PSG 0, 1, 2, N

; List of all BGM channels.
nvm_channel_ptr_tbl:
	dw	NvmOpnBgm+(NVMOPN.len*0)
	dw	NvmOpnBgm+(NVMOPN.len*1)
	dw	NvmOpnBgm+(NVMOPN.len*2)
	dw	NvmOpnBgm+(NVMOPN.len*3)
	dw	NvmOpnBgm+(NVMOPN.len*4)
	dw	NvmOpnBgm+(NVMOPN.len*5)
	dw	NvmPsgBgm+(NVMPSG.len*0)
	dw	NvmPsgBgm+(NVMPSG.len*1)
	dw	NvmPsgBgm+(NVMPSG.len*2)
	dw	NvmPsgBgm+(NVMPSG.len*3)
