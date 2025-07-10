; OPN/OPN2/OPN2C/etc registers

OPN_REG_TEST1  = 021h
OPN_REG_LFO    = 022h
OPN_REG_TA_HI  = 024h
OPN_REG_TA_LO  = 025h
OPN_REG_TB     = 026h
OPN_REG_TCTRL  = 027h
OPN_REG_KEYON  = 028h
OPN_REG_DACDAT = 02Ah
OPN_REG_DACSEL = 02Bh
OPN_REG_TEST2  = 02Ch
OPN_REG_DT_MUL = 030h
OPN_REG_TL     = 040h
OPN_REG_KS_AR  = 050h
OPN_REG_AM_DR  = 060h
OPN_REG_SR     = 070h
OPN_REG_SL_RR  = 080h
OPN_REG_SSG_EG = 090h
OPN_REG_FN_LO  = 0A0h
OPN_REG_FN_HI  = 0A4h
OPN_REG_FN3_LO = 0A8h
OPN_REG_FN3_HI = 0ACh
OPN_REG_FB_CON = 0B0h
OPN_REG_MOD    = 0B4h

; Tuning
OPN_NOTE_C     = 644
OPN_NOTE_Cs    = 681
OPN_NOTE_D     = 722
OPN_NOTE_Ds    = 765
OPN_NOTE_E     = 810
OPN_NOTE_F     = 858
OPN_NOTE_Fs    = 910
OPN_NOTE_G     = 964
OPN_NOTE_Gs    = 1021
OPN_NOTE_A     = 1081
OPN_NOTE_As    = 1146
OPN_NOTE_B     = 1214

OPN_NOTE_Db = OPN_NOTE_Cs
OPN_NOTE_Eb = OPN_NOTE_Ds
OPN_NOTE_Gb = OPN_NOTE_Fs
OPN_NOTE_Ab = OPN_NOTE_Gs
OPN_NOTE_Bs = OPN_NOTE_As

; For the longer delay associated with writing patch data.
opn_set_delay macro
	push	af
	pop	af
	endm

; Sets either OPN_BASE or OPN_BASE2 in ix based on channel ID in a
; Leaves a set up as a channel offset.
; in:  a = channel offset
; out: a = channel offset within OPN bank
;      ix = OPN_BASE*
opn_set_base_ix macro
	push	af
	ld	ix, OPN_BASE
	and	04h     ; filter out lower bits
	rrca            ; and downshift
	ld	ixl, a  ; bump address based on high channel bit
	pop	af
	and	03h
	endm

	; FM Patch data
OPNPATCH struct
	con_fb:   ds 1  ; B0h
	mul_dt:   ds 4  ; 30h
	tl:       ds 4  ; 40h
	ar_ks:    ds 4  ; 50h
	dr_am:    ds 4  ; 60h
	sr:       ds 4  ; 70h
	rr_sl:    ds 4  ; 80h
	ssg_eg:   ds 4  ; 90h
OPNPATCH endstruct

; Macros for making test instruments
opnp_con_fb macro con, fb
	db	((fb)<<3) | (con)
		endm

opnp_mul_dt macro mul, dt
	db	((dt&7)<<4) | (mul)
		endm

opnp_tl macro tl
	db	(tl)
		endm

opnp_ar_ks macro ar, ks
	db	((ks) << 6) | (ar)
		endm

opnp_dr_am macro dr, am
	db	((am) << 7) | (dr)
	endm

opnp_sr macro sr
	db	(sr)
	endm

opnp_rr_sl macro rr, sl
	db	((sl)<<4) | (rr)
	endm

opnp_ssg_eg macro ssgeg
	db	(ssgeg)
	endm
