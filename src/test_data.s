
;
; Test track. It's Freddie Hubbard's "Straight Life".
;

MELODY_LENGTH = 6
avm_data_testtrk:
	db	AVM_TIMER, 0C0h
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
	db	AVM_PAN, OPN_PAN_L
	db	AVM_LENGTH, MELODY_LENGTH
	db	AVM_OCT, 3*8
.loop:
	db	AVM_CALL
	dw	.melody_sub
	db	AVM_JUMP
	dw	.loop

.melody_sub:
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
	dw	AVM_RET

avm_data_testtrk2:
	db	AVM_PAN, OPN_PAN_R
	db	AVM_OCT, 5*8
	db	AVM_LENGTH, MELODY_LENGTH
.loop:
	db	AVM_CALL
	dw	.pt1_sub
	db	AVM_CALL
	dw	.pt2_sub
	db	AVM_JUMP
	dw	.loop

.pt1_sub:
	db	AVM_PMS, 7
	db	AVM_LOOPSET, 2
	db	AVM_NOTE_E | AVM_NOTE_REST_FLAG, MELODY_LENGTH*3
	db	AVM_NOTE_Eb
	db	AVM_NOTE_E
	db	AVM_NOTE_D
	db	AVM_NOTE_C | AVM_NOTE_REST_FLAG, MELODY_LENGTH*2

	db	AVM_NOTE_D | AVM_NOTE_REST_FLAG, MELODY_LENGTH*3
	db	AVM_NOTE_C
	db	AVM_NOTE_D
	db	AVM_NOTE_C, AVM_OCT_DOWN
	db	AVM_NOTE_Bb | AVM_NOTE_REST_FLAG, MELODY_LENGTH*2
	db	AVM_NOTE_Bb | AVM_NOTE_REST_FLAG, MELODY_LENGTH*2
	db	AVM_OCT_UP
	db	AVM_NOTE_C | AVM_NOTE_REST_FLAG, MELODY_LENGTH*11
	db	AVM_NOTE_E | AVM_NOTE_REST_FLAG, MELODY_LENGTH*2
	db	AVM_NOTE_Eb
	db	AVM_LOOPEND
	dw	AVM_RET

.pt2_sub:
	db	AVM_NOTE_E | AVM_NOTE_REST_FLAG, MELODY_LENGTH*2
	db	AVM_NOTE_F | AVM_NOTE_REST_FLAG, MELODY_LENGTH*2
	db	AVM_NOTE_G | AVM_NOTE_REST_FLAG, MELODY_LENGTH*2
	db	AVM_NOTE_A
	db	AVM_NOTE_As, AVM_NOTE_OFF
	db	AVM_REST, MELODY_LENGTH*8
	db	AVM_NOTE_As | AVM_NOTE_REST_FLAG, MELODY_LENGTH*2
	db	AVM_NOTE_A | AVM_NOTE_REST_FLAG, MELODY_LENGTH*2
	db	AVM_NOTE_G | AVM_NOTE_REST_FLAG, MELODY_LENGTH*2
	db	AVM_NOTE_F
	db	AVM_NOTE_G, AVM_NOTE_OFF
	db	AVM_REST, MELODY_LENGTH*8
	db	AVM_NOTE_E | AVM_NOTE_REST_FLAG, MELODY_LENGTH*2
	db	AVM_NOTE_F | AVM_NOTE_REST_FLAG, MELODY_LENGTH*2
	db	AVM_NOTE_G | AVM_NOTE_REST_FLAG, MELODY_LENGTH*2
	db	AVM_NOTE_A | AVM_NOTE_REST_FLAG, MELODY_LENGTH*2
	db	AVM_NOTE_As | AVM_NOTE_REST_FLAG, MELODY_LENGTH*2
	db	AVM_NOTE_A | AVM_NOTE_REST_FLAG, MELODY_LENGTH*2
	db	AVM_NOTE_G | AVM_NOTE_REST_FLAG, MELODY_LENGTH*2
	db	AVM_NOTE_F | AVM_NOTE_REST_FLAG, MELODY_LENGTH*2
	db	AVM_NOTE_G | AVM_NOTE_REST_FLAG, MELODY_LENGTH*2
	db	AVM_NOTE_E | AVM_NOTE_REST_FLAG, MELODY_LENGTH*2
	db	AVM_NOTE_E | AVM_NOTE_REST_FLAG, MELODY_LENGTH*2
	db	AVM_NOTE_Eb
	db	AVM_NOTE_E, AVM_NOTE_OFF
	db	AVM_REST, MELODY_LENGTH*3
	db	AVM_NOTE_E | AVM_NOTE_REST_FLAG, MELODY_LENGTH*2
	db	AVM_NOTE_D
	db	AVM_NOTE_C
	db	AVM_OCT_DOWN, AVM_NOTE_Bb, AVM_OCT_UP
	db	AVM_RET



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
