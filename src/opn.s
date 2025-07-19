;
; Hushes all channels and sets some basic control values.
;

; shuts up the channels
opn_reset:
	; First side
	ld	hl, OPN_ADDR0
	call	.sub_3ch
	; Second side
	ld	hl, OPN_ADDR1
	call	.sub_3ch
	jr	.keyoff
.sub_3ch:
	; reset pan
	ld	a, OPN_REG_MOD
	ld	d, OPN_PAN_L|OPN_PAN_R
	ld	b, 03h
	call	.reg_inc_loop
	; mute all operators
	ld	a, OPN_REG_TL
	ld	d, 7Fh
	ld	b, 10h
	call	.reg_inc_loop
	; call for instant release
	ld	a, OPN_REG_SL_RR
	ld	d, 0Fh
	ld	b, 10h
	; fall-through to .reg_inc_loop

.reg_inc_loop:
	ld	(hl), a
	inc	hl
	ld	(hl), d
	dec	hl

	push	ix
	pop	ix
	inc	a  ; next tl
	djnz	.reg_inc_loop
	ret

.keyoff:
	ld	hl, .init_data
.start:
	ld	de, OPN_DATA0
	ld	bc, (.init_data_end-.init_data)<<7 | (.init_data_end-.init_data)
.reg_copy_loop:
	ld	a, (de)  ; get OPN status
	rlca
	jr	c, .reg_copy_loop
	dec	de  ; DE now points to addr
	ldi	    ; address byte
	ldi	    ; data byte
	dec	de  ; DE points back to data
	djnz	.reg_copy_loop
	ret

.init_data:
	db	OPN_REG_LFO,    00h  ; LFO turned off
	db	OPN_REG_DACSEL, 00h  ; DAC turned off
	db	OPN_REG_TCTRL,  3Fh  ; both timers enabled and acked
	db	OPN_REG_KEYON,  00h  ; all notes key off
	db	OPN_REG_KEYON,  01h
	db	OPN_REG_KEYON,  02h
	db	OPN_REG_KEYON,  04h
	db	OPN_REG_KEYON,  05h
	db	OPN_REG_KEYON,  06h
.init_data_end:

opn_keyon_delay_sub:
	push	ix
	pop	ix
	ret

opn_set_base_de_sub:
	opn_set_base_de
	ret

; hl = patch data
; a = channel reg offset (0 - 6; '3' and '7' do not exist)
opn_set_patch:
	call	opn_set_base_de_sub

	; Patch data is just the register data in a row, so scoop it all.
	ld	c, a
	ld	a, OPN_REG_FB_CON
	add	a, c
	call	.write_sub
	; Now scoop all the reg data
	ld	b, 7*4  ; 4op patch data.
	ld	a, OPN_REG_DT_MUL
	add	a, c
.patchdata_loop:
	ld	i, a  ; i = scratch since we are not using IM2
	call	.write_sub
	ld	a, i
	add	a, 4  ; go to next op
	djnz	.patchdata_loop
	ret

; a = reg
; (de) = opn base
; (hl) = data
.write_sub:
	ld	(de), a
	inc	de
	ld	a, (hl)
	ld	(de), a
	dec	de
	inc	hl
	ret
