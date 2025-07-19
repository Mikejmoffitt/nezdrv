;
; NEZDRV v0.1 (c) Mike Moffitt 2025
; Built with The Macro Assembler AS 1.42
;
	cpu		Z80
	dottedstructs	on

NEZ_VERSION_STR = "NEZDRV01"

	include	"src/macro.inc"
	include	"src/memmap.inc"

	include	"src/mailbox.inc"
	include	"src/nvm.inc"
	include	"src/nvm_format.inc"
	include	"src/opn.inc"
	org	0000h
v_rst0:
	di                   ; 1 byte
	im	1            ; 2 bytes
	ld	sp, StackEnd ; 3 bytes
	jr	start        ; 2 bytes
	db	NEZ_VERSION_STR
	include	"src/pcm.s"
	include	"src/bank.s"
	include	"src/main.s"
	include	"src/mailbox.s"
	include	"src/interface.s"
	include	"src/opn.s"
	include	"src/psg.s"
	include	"src/nvm.s"
	include	"src/vars.s"
