

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
