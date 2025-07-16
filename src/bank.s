; a = bank number
bank_set:
.bankchk_inst:
	cp	0FFh  ; Current bank number gets stored here.
	ret	z
	ld	(.bankchk_inst+1), a
	bank_set_inline
	ret
