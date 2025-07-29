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
	db	"_DRV10"
	include	"src/pcm.s"

	; Cramming some stuff between end of PCM and IRQ at 0038h
nvm_psg_default_envelope:
	db	00h, NVM_MACRO_END


nvm_store_hl_pc_sub:
	ld	(iy+NVM.pc+1), h
	ld	(iy+NVM.pc), l
	ret

	; Two bytes remain between here.

	include	"src/irq.s"
	include	"src/startup.s"
	include	"src/nvm_init.s"
	include	"src/bank.s"
	include	"src/main.s"
	include	"src/mailbox.s"
	include	"src/interface.s"
	include	"src/opn.s"
	include	"src/psg.s"
	include	"src/nvm_setup.s"
	include	"src/nvm_sfx.s"
	include	"src/nvm_context.s"
	include	"src/nvm_inst.s"
	include	"src/nvm_pitch.s"
	include	"src/nvm_output.s"
	include	"src/nvm_note.s"
	include	"src/nvm.s"


; ------------------------------------------------------------------------------
;
; NVM channel state
;
; ------------------------------------------------------------------------------
	align	10h
; Sound effects - SFX_CHANNEL_COUNT independent channels, not hardware bound.
NvmSfx:                ds NVMSFX.len * SFX_CHANNEL_COUNT
NvmBgm:
NvmOpnBgm:             ds NVMOPN.len * OPN_BGM_CHANNEL_COUNT
NvmPsgBgm:             ds NVMPSG.len * PSG_BGM_CHANNEL_COUNT


; This is where user data (tracks, instruments, etc) lives.
UserBuffer:

	IF	$ > NEZ_MAILBOX_ADDR
	ERROR "User Buffer runs into mailbox memory!"
	ENDIF

	org NEZ_MAILBOX_ADDR
MailBox:        ds NEZMB.len

	IF	$ > Z80_RAM_BYTES
	ERROR "Mailbox extends beyond Z80 memory!"
	ENDIF


