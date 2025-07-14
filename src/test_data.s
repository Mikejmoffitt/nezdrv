
;
; Test track. It's Freddie Hubbard's "Straight Life".
;

TEST_LENGTH = 6
TEST_TIMER = 0C0h

bgm_test:
	nTrackHeader bgm_test_end, 0, TEST_TIMER, .track_list, .instruments_list, .pcm_list

.track_list:
	nTrackRelPtr track_sl_bass
	nTrackRelPtr track_sl_lead
	nTrackRelPtr track_sl_unused
	nTrackRelPtr track_sl_bass_echo
	nTrackRelPtr track_sl_lead_echo
	nTrackRelPtr track_sl_unused

	nTrackRelPtr track_sl_unused
	nTrackRelPtr track_sl_unused
	nTrackRelPtr track_sl_unused
	nTrackRelPtr track_sl_unused
	nTrackListEnd

.instruments_list:
	nTrackRelPtr .inst0_lead
	nTrackRelPtr .inst1_bass
	nTrackListEnd

.pcm_list:
	nTrackListEnd

.inst0_lead:
	opnp_con_fb  2,  7
	opnp_mul_dt  1,  0  ; 0
	opnp_mul_dt  0,  0  ; 2
	opnp_mul_dt  0,  0  ; 1
	opnp_mul_dt  1,  0  ; 3
	opnp_tl     22      ; 0
	opnp_tl     63      ; 2
	opnp_tl      9      ; 1
	opnp_tl      0      ; 3
	opnp_ar_ks  31,  0  ; 0
	opnp_ar_ks  31,  0  ; 2
	opnp_ar_ks  31,  0  ; 1
	opnp_ar_ks  31,  0  ; 3
	opnp_dr_am   0,  0  ; 0
	opnp_dr_am   0,  0  ; 2
	opnp_dr_am   0,  0  ; 1
	opnp_dr_am  10,  0  ; 3
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
track_sl_unused:
	nStop


track_sl_bass_init_sub:
	nInst	1
	nLength	TEST_LENGTH
	nOct	3
	nRet

track_sl_bass_echo:
	nCall	track_sl_bass_init_sub
	nVol	74h
	nRest	3*TEST_LENGTH/2
	nJump	track_sl_bass.start

track_sl_bass:
	nCall	track_sl_bass_init_sub
	nVol	7Fh
.start:
	nRest	TEST_LENGTH*3
.loop:
	nCall	.pt1_sub
	nJump	.loop

.pt1_sub:
	nC TEST_LENGTH*2
	nE
	nG
	nOctUp
	nC
	nOctDn
	nG
	nC

	nOctDn
	nBb TEST_LENGTH*2
	nBb
	nOctUp
	nD
	nF
	nBb
	nF
	nOctDn
	nBb TEST_LENGTH*2
	nOctUp
	nRet

;
;
;
track_sl_lead_init_sub:
	nInst	0
	nLength	TEST_LENGTH
	nOct	4
	nRet

track_sl_lead_echo:
	nCall	track_sl_lead_init_sub
	nVol	72h
	nPanL
	nRest	3*TEST_LENGTH/2
	nJump	track_sl_lead.loop

track_sl_lead:
	nCall	track_sl_lead_init_sub
	nVol	7Fh
.loop:
	nCall	.pre_sub
	nCall	.pt1_sub
	nCall	.pt1_sub
	nCall	.pt2_sub
	nCall	.pt3_sub
	nCall	.pt3a_sub
	nJump	.loop

.pre_sub:
	nG
	nF
	nNoteOff
	nRest
	nRet

.pt1_sub:
	nE TEST_LENGTH*3
	nD
	nE
	nD
	nC TEST_LENGTH*2

	nD TEST_LENGTH*3
	nC
	nD
	nC
	nOctDn
	nBb TEST_LENGTH*2
	nBb TEST_LENGTH*2
	nOctUp
	nC TEST_LENGTH*11
	nE TEST_LENGTH*2
	nEb
	nRet

.pt2_sub:
	nLength TEST_LENGTH*2
	nE
	nF
	nG
	nLength TEST_LENGTH
	nA
	nAs
	nNoteOff
	nRest	TEST_LENGTH*8
	nLength TEST_LENGTH*2
	nAs
	nA
	nG
	nLength TEST_LENGTH
	nF
	nG
	nNoteOff
	nRest	TEST_LENGTH*8
	nLength	TEST_LENGTH*2
	nE
	nF
	nG
	nA
	nAs
	nA
	nG
	nF
	nG
	nE
	nE
	nLength	TEST_LENGTH
	nEb
	nE
	nNoteOff
	nRest	TEST_LENGTH*3
	nRet
	
.pt3_sub:
	nLpSet	2
	nCall	.pt3_inner
	nRest TEST_LENGTH*4
	nLpEnd
	nCall	.pt3_inner
	nRet

.pt3_inner:
	nE TEST_LENGTH*2
	nD
	nC
	nOctDn
	nBb
	nOctUp

	nC TEST_LENGTH*2
	nOctDn
	nBb
	nNoteOff
	nOctUp
	nRest TEST_LENGTH*4
	nRet

.pt3a_sub:
	nOctDn
	nG
	nBb
	nOctUp
	nLpSet	4
	nC
	nLpEnd
	nNoteOff
	nRest
	nD
	nC TEST_LENGTH*5
	nOctDn
	nBb
	nG
	nNoteOff
	nOctUp
	nRest TEST_LENGTH*7
	nRet

bgm_test_end:
