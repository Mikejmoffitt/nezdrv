
;
; Test track. It's Freddie Hubbard's "Straight Life".
;

TEST_LENGTH = 6
TEST_TIMER = 0C0h

track_test:
	dw	0           ; PCM Rate timer
	db	TEST_TIMER  ; tempo timer
	dw	.track_list
	dw	.instruments_list
.track_list:
	dw	avm_data_test_bass
	dw	avm_data_test_lead
	dw	0
	dw	avm_data_test_bass_echo
	dw	avm_data_test_lead_echo
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
.instruments_list:
	dw	.inst0_lead
	dw	.inst1_bass

.inst0_lead:
	opnp_con_fb  2,  7
	opnp_mul_dt  2,  0  ; 0
	opnp_mul_dt  0,  0  ; 2
	opnp_mul_dt  0,  0  ; 1
	opnp_mul_dt  1,  0  ; 3
	opnp_tl     27      ; 0
	opnp_tl     63      ; 2
	opnp_tl      9      ; 1
	opnp_tl      1      ; 3
	opnp_ar_ks  31,  0  ; 0
	opnp_ar_ks  31,  0  ; 2
	opnp_ar_ks  31,  0  ; 1
	opnp_ar_ks  31,  0  ; 3
	opnp_dr_am   0,  0  ; 0
	opnp_dr_am   0,  0  ; 2
	opnp_dr_am   0,  0  ; 1
	opnp_dr_am  15,  0  ; 3
	opnp_sr      0      ; 0
	opnp_sr      0      ; 2
	opnp_sr      0      ; 1
	opnp_sr     12      ; 3
	opnp_rr_sl   0,  0  ; 0
	opnp_rr_sl   0,  0  ; 2
	opnp_rr_sl   0,  0  ; 1
	opnp_rr_sl  24,  3  ; 3
	opnp_ssg_eg  0      ; 0
	opnp_ssg_eg  0      ; 2
	opnp_ssg_eg  0      ; 1
	opnp_ssg_eg  0      ; 3

.inst1_bass:
	opnp_con_fb  0,  1
	opnp_mul_dt  7,  0  ; 0
	opnp_mul_dt  0,  3  ; 2
	opnp_mul_dt  0, -3  ; 1
	opnp_mul_dt  0,  0  ; 3
	opnp_tl     31      ; 0
	opnp_tl     17      ; 2
	opnp_tl     43      ; 1
	opnp_tl      2      ; 3
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


;
;
;
avm_data_test_bass_init_sub:
	db	AVM_INST, 2
	db	AVM_LENGTH, TEST_LENGTH
	db	AVM_OCT, 3*8
	db	AVM_RET

avm_data_test_bass_echo:
	db	AVM_CALL
	dw	avm_data_test_bass_init_sub
	db	AVM_VOL, 09h
	db	AVM_REST, 3*TEST_LENGTH/2
	db	AVM_JUMP
	dw	avm_data_test_bass.loop

avm_data_test_bass:
	db	AVM_CALL
	dw	avm_data_test_bass_init_sub
	db	AVM_VOL, 00h
.loop:
;	db	AVM_CALL
;	dw	.ptest_sub
;	db	AVM_JUMP
;	dw	.loop
	db	AVM_CALL
	dw	.pt1_sub
	db	AVM_JUMP
	dw	.loop

.pt1_sub:
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

.ptest_sub:
	db	AVM_LENGTH, 020h
	db	AVM_NOTE_C
	db	AVM_NOTE_E
	db	AVM_NOTE_G
	db	AVM_OCT_UP, AVM_NOTE_C, AVM_OCT_DOWN
	dw	AVM_RET

;
;
;
avm_data_test_lead_init_sub:
	db	AVM_INST, 0
	db	AVM_LENGTH, TEST_LENGTH
	db	AVM_OCT, 5*8
	db	AVM_SLIDE, 50
	db	AVM_RET

avm_data_test_lead_echo:
	db	AVM_CALL
	dw	avm_data_test_lead_init_sub
	db	AVM_VOL, 12h
	db	AVM_REST, TEST_LENGTH
	db	AVM_JUMP
	dw	avm_data_test_lead.loop

avm_data_test_lead:
	db	AVM_CALL
	dw	avm_data_test_lead_init_sub
	db	AVM_PAN, OPN_PAN_R
	db	AVM_VOL, 00h
.loop:
	db	AVM_LOOPSET, 2
	db	AVM_CALL
	dw	.pt1_sub
	db	AVM_CALL
	dw	.pt1_sub
	db	AVM_CALL
	dw	.pt2_sub
	db	AVM_JUMP
	dw	.loop

.pt1_sub:
	db	AVM_NOTE_E | AVM_NOTE_REST_FLAG, TEST_LENGTH*3
	db	AVM_NOTE_Eb
	db	AVM_NOTE_E
	db	AVM_NOTE_D
	db	AVM_NOTE_C | AVM_NOTE_REST_FLAG, TEST_LENGTH*2

	db	AVM_NOTE_D | AVM_NOTE_REST_FLAG, TEST_LENGTH*3
	db	AVM_NOTE_C
	db	AVM_NOTE_D
	db	AVM_NOTE_C, AVM_OCT_DOWN
	db	AVM_NOTE_Bb | AVM_NOTE_REST_FLAG, TEST_LENGTH*2
	db	AVM_NOTE_Bb | AVM_NOTE_REST_FLAG, TEST_LENGTH*2
	db	AVM_OCT_UP
	db	AVM_NOTE_C | AVM_NOTE_REST_FLAG, TEST_LENGTH*11
	db	AVM_NOTE_E | AVM_NOTE_REST_FLAG, TEST_LENGTH*2
	db	AVM_NOTE_Eb
	dw	AVM_RET

.pt2_sub:
	db	AVM_NOTE_E | AVM_NOTE_REST_FLAG, TEST_LENGTH*2
	db	AVM_NOTE_F | AVM_NOTE_REST_FLAG, TEST_LENGTH*2
	db	AVM_NOTE_G | AVM_NOTE_REST_FLAG, TEST_LENGTH*2
	db	AVM_NOTE_A
	db	AVM_NOTE_As, AVM_NOTE_OFF
	db	AVM_REST, TEST_LENGTH*8
	db	AVM_NOTE_As | AVM_NOTE_REST_FLAG, TEST_LENGTH*2
	db	AVM_NOTE_A | AVM_NOTE_REST_FLAG, TEST_LENGTH*2
	db	AVM_NOTE_G | AVM_NOTE_REST_FLAG, TEST_LENGTH*2
	db	AVM_NOTE_F
	db	AVM_NOTE_G, AVM_NOTE_OFF
	db	AVM_REST, TEST_LENGTH*8
	db	AVM_NOTE_E | AVM_NOTE_REST_FLAG, TEST_LENGTH*2
	db	AVM_NOTE_F | AVM_NOTE_REST_FLAG, TEST_LENGTH*2
	db	AVM_NOTE_G | AVM_NOTE_REST_FLAG, TEST_LENGTH*2
	db	AVM_NOTE_A | AVM_NOTE_REST_FLAG, TEST_LENGTH*2
	db	AVM_NOTE_As | AVM_NOTE_REST_FLAG, TEST_LENGTH*2
	db	AVM_NOTE_A | AVM_NOTE_REST_FLAG, TEST_LENGTH*2
	db	AVM_NOTE_G | AVM_NOTE_REST_FLAG, TEST_LENGTH*2
	db	AVM_NOTE_F | AVM_NOTE_REST_FLAG, TEST_LENGTH*2
	db	AVM_NOTE_G | AVM_NOTE_REST_FLAG, TEST_LENGTH*2
	db	AVM_NOTE_E | AVM_NOTE_REST_FLAG, TEST_LENGTH*2
	db	AVM_NOTE_E | AVM_NOTE_REST_FLAG, TEST_LENGTH*2
	db	AVM_NOTE_Eb
	db	AVM_NOTE_E, AVM_NOTE_OFF
	db	AVM_REST, TEST_LENGTH*3
	db	AVM_NOTE_E | AVM_NOTE_REST_FLAG, TEST_LENGTH*2
	db	AVM_NOTE_D
	db	AVM_NOTE_C
	db	AVM_OCT_DOWN, AVM_NOTE_Bb, AVM_OCT_UP
	db	AVM_RET

avm_data_test_sweeps:
	db	AVM_CALL
	dw	avm_data_test_bass_init_sub

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
	
