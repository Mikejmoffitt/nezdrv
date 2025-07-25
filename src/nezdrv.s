;
; NEZDRV v0.1 (c) Mike Moffitt 2025
; Built with The Macro Assembler AS 1.42
;
	cpu		Z80
	dottedstructs	on

	include	"src/macro.inc"
	include	"src/memmap.inc"

	include	"src/nvm.inc"
	include	"src/nvm_format.inc"
	include	"src/mailbox.inc"
	include	"src/opn.inc"

	org	0000h
nez_signature:  ; after startup is complete, three bytes become 'NEZ'
v_rst0:
	jr	start                ; 2 bytes
sig_str:
	db	"NEZDRV"
	include	"src/pcm.s"
	include	"src/irq.s"
	include	"src/startup.s"
	include	"src/nvm_init.s"
	include	"src/bank.s"
	include	"src/main.s"
	include	"src/mailbox.s"
	include	"src/interface.s"
	include	"src/opn.s"
	include	"src/psg.s"
	include	"src/nvm.s"
	include	"src/mem_context.s"

NvmSfx:                ds NVMSFX.len * SFX_CHANNEL_COUNT
NvmBgm:
NvmOpnBgm:             ds NVMOPN.len * OPN_BGM_CHANNEL_COUNT
NvmPsgBgm:             ds NVMPSG.len * PSG_BGM_CHANNEL_COUNT

; This is where user data (tracks, instruments, etc) lives.
UserBuffer:

	org NEZ_MAILBOX_ADDR
MailBox:        ds NEZMB.len

	IF	$ > Z80_RAM_BYTES
	ERROR "Mailbox extends beyond Z80 memory!"
	ENDIF


