	cpu		Z80
	dottedstructs	on

	include	"src/macro.inc"
	include	"src/memmap.inc"
	include	"src/avm.inc"
	include	"src/opn.inc"
	include	"src/opnpatch.inc"

vbl_wait macro
	ld	a, 01h
	ld	(VblFlag), a
-:
	ld	a, (VblFlag)
	cp	00h
	jr	nz, -
	endm


; Vectors
	org	0000h
v_rst0:
	di             ; 1 byte
	im	1      ; 2 bytes
	jp	start  ; 2 bytes

	org	0008h
v_rst1:
	ret

	org	0010h
v_rst2:
	ret

	org	0018h
v_rst3:
	ret

	org	0020h
v_rst4:
	ret

	org	0028h
v_rst5:
	ret

	org	0030h
v_rst6:
	ret

	org	0038h
v_irq:
	ex	af, af'
	ld	a, (FrameCnt)
	inc	a
	ld	(FrameCnt), a
	ld	a, 00h
	ld	(VblFlag), a
	ex	af, af'
	ei
	ret

	org	0066h
v_nmi:
	retn

	include	"src/opn.s"
	include	"src/avm.s"


start:
	ld	sp, StackEnd ; 3 bytes
	call	opn_init
	; Clear work RAM
	ld	hl, TmpStart
	; DE := hl + 1
	ld	e, l
	ld	d, h
	inc	de
	ld	(hl), 00h  ; First byte is initialized with clear value 00h
	ld	bc, TmpEnd-TmpStart
	ldir

soft_start:
	call	avm_init

	;
	; TEST DATA
	;
	ld	iy, AvmOpn+AVM.len*0
	ld	de, avm_data_testtrk
	call	avm_set_head

	; Set up channel 0 with a patch
	ld	hl, opnp_test
	ld	a, 0
	call	opn_set_patch

	ei

main:
;	call	opn_wait_timer_b  ; TODO
	vbl_wait

	; For now just run the one
	ld	iy, AvmOpn
	call	avm_poll
;	call	keydown_test_func
	jr	main

;
; Test track
;
avm_data_testtrk:
	db	AVM_TIMER, 80
	db	AVM_OCT, 3*8
	db	AVM_JUMP
	dw	.melody
	; octave sweep
	db	AVM_OCT, 0
	db	AVM_LENGTH, 30
	db	AVM_NOTE_C
	rept	7
	db	AVM_NOTE_C, AVM_OCT_UP
	endm
	; note sweep
	db	AVM_OCT, 3*8
	db	AVM_LENGTH, 40
	db	AVM_NOTE_C
	db	AVM_NOTE_Cs
	db	AVM_NOTE_D
	db	AVM_NOTE_Ds
	db	AVM_NOTE_E
	db	AVM_NOTE_F
	db	AVM_NOTE_Fs
	db	AVM_NOTE_G
	db	AVM_NOTE_Gs
	db	AVM_NOTE_A
	db	AVM_NOTE_As
	db	AVM_NOTE_B
	db	AVM_OCT_UP, AVM_NOTE_C | AVM_NOTE_REST_FLAG, 48
.melody:
	db	AVM_LENGTH, 7
	db	AVM_OCT, 3*8
.loop:
	db	AVM_NOTE_C 
	db	AVM_REST, 0
	db	AVM_NOTE_E
	db	AVM_NOTE_G
	db	AVM_OCT_UP, AVM_NOTE_C, AVM_OCT_DOWN
	db	AVM_NOTE_G
	db	AVM_NOTE_C

	db	AVM_OCT_DOWN, AVM_NOTE_Bb
	db	AVM_REST, 0
	db	AVM_NOTE_Bb, AVM_OCT_UP
	db	AVM_NOTE_D
	db	AVM_NOTE_F
	db	AVM_NOTE_Bb
	db	AVM_NOTE_F
	db	AVM_OCT_DOWN, AVM_NOTE_Bb
	db	AVM_REST, 0
	db	AVM_OCT_UP
	db	AVM_JUMP
	dw	.loop


opnp_test:
	;          con, fb
	opnp_con_fb  0,  1
	opnp_mul_dt  7,  0  ; 0
	opnp_mul_dt  0,  3  ; 2
	opnp_mul_dt  0, -3  ; 1
	opnp_mul_dt  0,  0  ; 3
	opnp_tl     31      ; 0
	opnp_tl     17      ; 2
	opnp_tl     43      ; 1
	opnp_tl      7      ; 3
	opnp_ar_ks  31,  2  ; 0
	opnp_ar_ks  31,  2  ; 2
	opnp_ar_ks  31,  2  ; 1
	opnp_ar_ks  31,  2  ; 3
	opnp_dr_am  18,  0  ; 0
	opnp_dr_am  10,  0  ; 2
	opnp_dr_am  14,  0  ; 1
	opnp_dr_am  10,  0  ; 3
	opnp_sr      0      ; 0
	opnp_sr      0      ; 2
	opnp_sr      0      ; 1
	opnp_sr      0      ; 3
	opnp_rr_sl   8,  2  ; 0
	opnp_rr_sl   5,  2  ; 2
	opnp_rr_sl   5,  2  ; 1
	opnp_rr_sl   5,  2  ; 3
	opnp_ssg_eg  0      ; 0
	opnp_ssg_eg  0      ; 2
	opnp_ssg_eg  0      ; 1
	opnp_ssg_eg  0      ; 3

	include	"src/vars.s"
