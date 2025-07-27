; ------------------------------------------------------------------------------
;
; Context Switching
;
; Sound effects and background music exist in their own worlds, with their own
; instrument tables, volume levels, and PCM playback rates. These functions
; copy the appropriate data into the currently active variables.
;
; ------------------------------------------------------------------------------

nvm_context_sfx_set:
	ld	a, 01h  ; I
	push	hl
	ld	hl, SfxContext
	jr	nvm_context_copy

nvm_context_bgm_set:
	xor	a
	push	hl
	ld	hl, BgmContext
	; fall-through to nvm_context_copy

; ------------------------------------------------------------------------------
;
; in:
;      hl: context pointer
;       a: SFX flag (1 = SFX, 0 = BGM)
;
; note: pops HL afterwards; only meant to be a function tail.
;
; ------------------------------------------------------------------------------
nvm_context_copy:
	ld	(IsSfx), a
	ld	de, CurrentContext
	ld	bc, NVMCONTEXT.len
	ldir
	pcm_service
	pop	hl
	ret

; ------------------------------------------------------------------------------
;
; Context buffers
;
; ------------------------------------------------------------------------------
BgmContext:            ds NVMCONTEXT.len
SfxContext:            ds NVMCONTEXT.len
CurrentContext:        ds NVMCONTEXT.len
