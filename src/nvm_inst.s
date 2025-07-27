
; in:
;      de = instrument patch
;      iy = NVM head
nvm_load_inst:
	; only OPN needs to talk to hardware here.
	ld	a, (iy+NVM.channel_id)
	and	a   ; test for PSG (channel id >= 80h)
	jp	p, .opn_apply
	; PSG just needs to set the envelope ptr.
	ld	a, (iy+NVM.instrument_ptr+0)
	ld	(iy+NVMPSG.env_ptr+0), a
	ld	a, (iy+NVM.instrument_ptr+1)
	ld	(iy+NVMPSG.env_ptr+1), a
	ret

.opn_apply:
	; pull con data.
	IF	OPNPATCH.con_fb == 0  ; this is how I avoid self-owning later
	ld	a, (de)  ; OPNPATCh begins with con_fb
	ELSE
	ld	hl, OPNPATCH.con_fb
	add	hl, de  ; hl := source fb data
	ld	a, (hl)
	ENDIF  ; OPNPATCH.con_fb == 0
	and	a, 07h
	add	a, a
	ld	(iy+NVMOPN.tl_conoffs), a
	; pull TL data.
	ld	hl, OPNPATCH.tl
	add	hl, de  ; hl := source TL data
	ld	a, (hl)
	ld	(iy+NVMOPN.tl+0), a
	inc	hl
	ld	a, (hl)
	ld	(iy+NVMOPN.tl+1), a
	inc	hl
	ld	a, (hl)
	ld	(iy+NVMOPN.tl+2), a
	inc	hl
	ld	a, (hl)
	ld	(iy+NVMOPN.tl+3), a
	; write the patch to the OPN
	ld	de, 10000h-OPNPATCH.tl-3  ; why is there no 16-bit sub???
	add	hl, de  ; wind hl back to the patch start
	ld	a, (iy+NVM.channel_id)
	jp	opn_set_patch

; ------------------------------------------------------------------------------
;
; OPN volume application (through TL adjustment)
;
; Adjusts the TL register for an OPN channel by both the channel and global
; volume setting.
;
; in:
;     iy = NVMOPN channel struct
;
nvmopn_tlmod:
	ld	a, (CurrentContext+NVMCONTEXT.global_volume)
	add	a, (iy+NVM.volume)
	ld	(CurrentChannelVol), a

	;
	; Prepare OPN offset
	;
	ld	a, (iy+NVM.channel_id)
	call	opn_set_base_de_sub
	ld	c, a

tlmod macro opno
	ld	a, (iy+NVMOPN.tl+(opno))
	call	.limit_sub
	ld	i, a
	ld	a, OPN_REG_TL+(4*(opno))
	call	.write_sub
	endm

	; Modify tl. Must leave B alone for use afterwards.
	ld	a, (iy+NVMOPN.tl_conoffs)
	jptbl_dispatch
	jr	.note_volmod_op_4
	jr	.note_volmod_op_4
	jr	.note_volmod_op_4
	jr	.note_volmod_op_4
	jr	.note_volmod_op_3_and_4
	jr	.note_volmod_op_all_but_1
	jr	.note_volmod_op_all_but_1
	jr	.note_volmod_op_all
.note_volmod_op_all:  ; all operators
	tlmod	1-1
.note_volmod_op_all_but_1:  ; all but 1
	tlmod	2-1
.note_volmod_op_3_and_4:
	tlmod	3-1
.note_volmod_op_4:
	tlmod	4-1

	ret

; in:
;      a = TL register (differs by op number)
;      c = channel ID
;     de = OPN base for corresponding side
;      i = TL value to write
.write_sub:
	add	a, c  ; add channel ID
	ld	(de), a
	inc	de
	ld	a, i
	ld	(de), a  ; updated TL value
	dec	de
	ret

; in:
;      a = TL value
; out:
;      a = TL value summed with effective volume, limited to 7Fh
.limit_sub:
	add	a, 00h  ; replaced as CurrentChannelVol
CurrentChannelVol = .limit_sub+1
	cp	80h
	ret	c
	ld	a, 7Fh
	ret
