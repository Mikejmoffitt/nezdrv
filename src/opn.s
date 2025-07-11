;
; Hushes all channels and sets some basic control values.
;

OPN_TCTRL_DEFAULT = 3Fh

opn_init:
	ld	hl, .init_data
	ld	de, OPN_DATA0
	ld	bc, (.init_data_end-.init_data)<<7 | (.init_data_end-.init_data)
.loop:
	ld	a, (de)  ; get OPN status
	rlca
	jr	c, .loop
	dec	de  ; DE now points to addr
	ldi	    ; address byte
	ldi	    ; data byte
	dec	de  ; DE points back to data
	; add some delay for keyon regs
	call	opn_keyon_delay_sub
	djnz	.loop
	ret

.init_data:
	db	OPN_REG_TA_HI, 80h
	db	OPN_REG_TA_LO, 00h
	db	OPN_REG_TB,    20h
	db	OPN_REG_TCTRL, OPN_TCTRL_DEFAULT
	db	OPN_REG_KEYON, 00h  ; all notes key off
	db	OPN_REG_KEYON, 01h
	db	OPN_REG_KEYON, 02h
	db	OPN_REG_KEYON, 04h
	db	OPN_REG_KEYON, 05h
	db	OPN_REG_KEYON, 06h
.init_data_end:

opn_keyon_delay_sub:
	push	ix
	pop	ix
	ret

; Writes address register using c as the block offset
; ix = OPN_BASE
opn_set_datwalk	macro	regno
	ld	a, regno
	call	.write_sub
	endm

opn_set_datwalk_4op	macro	regno
	ld	a, regno
	call	.write_4op_sub
	endm

; hl = patch data
; a = channel num (0 - 6; '3' and '7' do not exist)
opn_set_patch:
	opn_set_base_ix  ; Set up ix with OPN_BASE or OPN_BASE2 by channel number.
	ld	c, a  ; Get channel offset into C.
	opn_set_datwalk OPN_REG_FB_CON
	opn_set_datwalk_4op OPN_REG_DT_MUL
	opn_set_datwalk_4op OPN_REG_TL
	opn_set_datwalk_4op OPN_REG_KS_AR
	opn_set_datwalk_4op OPN_REG_AM_DR
	opn_set_datwalk_4op OPN_REG_SR
	opn_set_datwalk_4op OPN_REG_SL_RR
	opn_set_datwalk_4op OPN_REG_SSG_EG
	ret

; a = base reg
; c = channel offs
; (hl) = data
.write_sub:
	add	a, c  ; channel bits
	ld	(ix+0), a  ; 19
	ld	a, (hl)    ; 7
	ld	(ix+1), a  ; 19
	inc	hl
	opn_set_delay
	ret

; a = base reg
; c = channel offs
; (hl) = data
.write_4op_sub:
	add	a, c  ; channel bits
	ld	b, 4  ; four operators
.write_4op_loop:
	ld	(ix+0), a  ; 19 addr
	ld	d, (hl)    ; 7
	ld	(ix+1), d  ; 19 data
	inc	hl
	add	a, 4  ; go to next op
	opn_set_delay
	djnz	.write_4op_loop
	ret
