; a = bank number
bank_set:
	cp	0FFh  ; Current bank number gets stored here.
	ret	z
	ld	(CurrentBank), a
	bank_set_inline
	ret

CurrentBank = bank_set+1
