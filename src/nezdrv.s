	cpu		Z80
	dottedstructs	on

	include	"src/macro.inc"
	include	"src/memmap.inc"

	include	"src/avm.inc"
	include	"src/opn.inc"
	include	"src/trackdata.inc"
	org	0000h
v_rst0:
	di                   ; 1 byte
	im	1            ; 2 bytes
	ld	sp, StackEnd ; 3 bytes
	jr	start        ; 2 bytes
	include	"src/pcm.s"
	include	"src/main.s"
	include	"src/opn.s"
	include	"src/avm.s"
	include	"src/vars.s"
	include	"src/test_data.s"



