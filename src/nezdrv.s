;
; NEZDRV v0.1 (c) Mike Moffitt 2025
; Built with The Macro Assembler AS 1.42
;
	cpu		Z80
	dottedstructs	on

	include	"src/macro.inc"
	include	"src/memmap.inc"

	include	"src/mailbox.inc"
	include	"src/nvm.inc"
	include	"src/nvm_format.inc"
	include	"src/opn.inc"
	org	0000h
	include	"src/mem_misc.s"
	org	0000h
v_rst0:
	di                           ; 1 byte
	ld	sp, NEZ_MAILBOX_ADDR ; 3 bytes
	jp	start                ; 3 bytes
	include	"src/pcm.s"
	include	"src/irq.s"

; These files contain code that is only executed once, at startup. Some of it
; gets overlaid by work RAM variables.
PRG_STARTUP = $
	include	"src/mailbox_init.s"
	include	"src/nvm_init.s"
	include	"src/startup.s"

LAST_ORG	:=	$
	org	PRG_STARTUP
; RAM that overlays startup code.
	include	"src/mem_context.s"

	org	LAST_ORG
	db	"PRGMAIN"
	include	"src/bank.s"
	include	"src/main.s"
	include	"src/mailbox.s"
	include	"src/interface.s"
	include	"src/opn.s"
	include	"src/psg.s"
	include	"src/nvm.s"

NvmSfx:                ds NVMSFX.len * SFX_CHANNEL_COUNT
NvmBgm:
NvmOpnBgm:             ds NVMOPN.len * OPN_BGM_CHANNEL_COUNT
NvmPsgBgm:             ds NVMPSG.len * PSG_BGM_CHANNEL_COUNT
; This is where user data (tracks, instruments, etc) lives.
UserBuffer:

	include	"src/mem_mailbox.s"


