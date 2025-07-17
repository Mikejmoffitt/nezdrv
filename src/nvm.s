; ------------------------------------------------------------------------------
;
; Initialization
;
; ------------------------------------------------------------------------------
nvm_init:
	; The OPN channels
	ld	de, NVMOPN.len

	ld	hl, .opn_channel_id_tbl
	ld	iy, NvmOpnBgm
	ld	b, OPN_BGM_CHANNEL_COUNT
	call	.grp_init_sub

	ld	iy, NvmOpnSfx
	ld	b, OPN_SFX_CHANNEL_COUNT
	call	.grp_init_sub

	; The PSG channels
	ld	de, NVMPSG.len
	ld	hl, .psg_channel_id_tbl
	ld	b, PSG_BGM_CHANNEL_COUNT
	ld	iy, NvmPsgBgm
	call	.grp_init_sub

	ld	b, PSG_SFX_CHANNEL_COUNT
	ld	iy, NvmPsgSfx
	call	.grp_init_sub
	; All buffers start at UserBuffer. It is expected that SFX and PCM are
	; set once, while BGM can be exchanged. It's also okay to omit SFX and
	; PCM loads.
	ld	hl, UserBuffer
	ld	(UserBufferLoadPtr), hl
	ld	(BgmContext+NVMCONTEXT.buffer_ptr), hl
	ld	(SfxContext+NVMCONTEXT.buffer_ptr), hl
	ld	(PcmListPtr), hl
	xor	a
	ld	(BgmContext+NVMCONTEXT.global_volume), a
	ld	(SfxContext+NVMCONTEXT.global_volume), a
	ret

.opn_channel_id_tbl:
	db	0, 1, 2, 4, 5, 6  ; bgm
	db	0, 1, 2           ; sfx
.psg_channel_id_tbl:
	db	00h, 20h, 40h     ; bgm
	db	00h, 20h, 40h     ; sfx


; hl = channel id assignment tbl
; iy = start of block
; de = struct offset per
; b = count
.grp_init_sub:
-:
	ld	a, (hl)
	inc	hl
	ld	(iy+NVM.channel_id), a

	call	nvm_reset_sub

	add	iy, de
	djnz	-
	ret

; iy = NVM head
nvm_reset_sub:
	exx
	; Zero some defaults to inactive
	xor	a
	ld	(iy+NVM.status), a      ; inactive
	ld	(iy+NVM.mute), a        ; unmuted
	ld	(iy+NVM.portamento), a  ; no portamento
;	ld	(iy+NVM.vib_mag), a     ; no vibrato
;	ld	(iy+NVM.vib_cnt), a     ; v counter reset
	ld	(iy+NVM.rest_cnt), a
	; Set stack pointer
	push	iy
	pop	hl
	ld	de, NVM.stack
	add	hl, de
	ld	(iy+NVM.stack_ptr+1), h
	ld	(iy+NVM.stack_ptr), l
	; channel default
	ld	(iy+NVM.rest_val), NVM_REST_DEFAULT
	; Default highest volume.
	ld	(iy+NVM.volume), 7Fh
	exx
	ret

; ------------------------------------------------------------------------------
;
; Resets channels to an inactive state.
;
; ------------------------------------------------------------------------------
nvm_bgm_reset:
	pcm_poll_disable
	ld	b, OPN_BGM_CHANNEL_COUNT
	ld	iy, NvmOpnBgm
	ld	de, NVMOPN.len
-:
	call	nvm_reset_sub
	; default to both outputs, no modulation
	ld	(iy+NVMOPN.pan), OPN_PAN_L|OPN_PAN_R
	; No portamento for first note.
	ld	(iy+NVMOPN.now_block), 80h
	add	iy, de
	djnz	-

	; iy is at NvmPsgBgm now.
	ld	b, PSG_BGM_CHANNEL_COUNT
	ld	iy, NvmPsgBgm
	ld	de, NVMPSG.len
	; fall-through to .reset_lp
-:
	call	nvm_reset_sub
	; TODO: PSG shit
	add	iy, de
	djnz	-
	jp	opn_reset

; ------------------------------------------------------------------------------
;
; Main Poll Function
;
; ------------------------------------------------------------------------------

nvm_context_iter_opn_sfx_set:
	call	nvm_context_sfx_set
	ld	b, OPN_SFX_CHANNEL_COUNT
	ld	iy, NvmOpnSfx
	ret

nvm_context_iter_opn_bgm_set:
	call	nvm_context_bgm_set
	ld	b, OPN_BGM_CHANNEL_COUNT
	ld	iy, NvmOpnBgm
	ret

nvm_context_sfx_set:
	push	hl
	ld	hl, SfxContext
	jr	nvm_context_copy
nvm_context_bgm_set:
	push	hl
	ld	hl, BgmContext
nvm_context_copy:
	ld	de, CurrentContext
	ld	bc, NVMCONTEXT.len
	ldir
	pop	hl
	pcm_service
	ret

; b = count
; iy = NVMOPN head
nvm_poll_opn:
.loop:
	push	bc
	; Skip inactive channels
	ld	a, (iy+NVM.status)
	and	a  ; NVM_STATUS_INACTIVE?
	jr	z, .next_chan
	call	nvm_exec
	pcm_service
	call	nvm_opn_portamento
	pcm_service
	call	nvmopn_update_output
.next_chan:
	ld	de, NVMOPN.len
	add	iy, de
	pcm_service
	pop	bc
	djnz	.loop
	ret

; b = count
; iy = NVMPSG head
nvm_poll_psg:
.loop:
	push	bc
	; Skip inactive channels
	ld	a, (iy+NVM.status)
	and	a  ; NVM_STATUS_INACTIVE?
	jr	z, .next_chan
	call	nvm_exec
	pcm_service
;	call	nvm_opn_portamento
;	pcm_service
;	call	nvmopn_update_output
.next_chan:
	ld	de, NVMPSG.len
	add	iy, de
	pcm_service
	pop	bc
	djnz	.loop
	ret

; ------------------------------------------------------------------------------
;
; Execution of NVM Instructions
;
; ------------------------------------------------------------------------------

nvm_op_finished_yield:
	ld	(iy+NVM.pc+1), h
	ld	(iy+NVM.pc), l
nvm_exec:
.top:
	; If rest counter > 0, decrement and proceed
	ld	a, (iy+NVM.rest_cnt)
	and	a
	jr	z, .instructions_from_pc
	dec	a
	ld	(iy+NVM.rest_cnt), a
	ret

.instructions_from_pc:
	; Time for instructions
	ld	h, (iy+NVM.pc+1)
	ld	l, (iy+NVM.pc)
.instructions_from_hl:
	ld	a, (hl)
	inc	hl

	; If A is >= 80h, it's a note, and is handled differently.
	and	a
	jp	m, nvm_op_note
.dispatch_opn:
	; Else, it's a control instruction.
	jptbl_dispatch

	jp	nvm_op_jump     ;  0
	jp	nvm_op_call     ;  1
	jp	nvm_op_ret      ;  2
	jp	nvm_op_loopset  ;  3
	jp	nvm_op_loopend  ;  4
	jp	nvm_op_tempo    ;  5
	jp	nvm_op_length   ;  6
	jp	nvm_op_rest     ;  7
	jp	nvm_op_oct      ;  8
	jp	nvm_op_oct_up   ;  9
	jp	nvm_op_oct_down ; 10
	jp	nvm_op_inst     ; 11
	jp	nvm_op_vol      ; 12
	jp	nvm_op_pan      ; 13
	jp	nvm_op_pms      ; 14
	jp	nvm_op_ams      ; 15
	jp	nvm_op_opn_reg  ; 16
	jp	nvm_op_stop     ; 17
	jp	nvm_op_note_off ; 18
	jp	nvm_op_slide    ; 19
	jp	nvm_op_pcmrate  ; 20
	jp	nvm_op_pcmmode  ; 21
	jp	nvm_op_pcmplay  ; 22
	jp	nvm_op_pcmstop  ; 23


; ------------------------------------------------------------------------------


nvm_op_jump:     ;  0
	; two bytes - relative pointer to jump to
	call	.set_pc_relative_offs
	jr	nvm_exec.instructions_from_hl

; hl = start of relative label offset argument
; clobbers bc, messes with hl
.set_pc_relative_offs:
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	add	hl, bc
	ld	(iy+NVM.pc+1), h
	ld	(iy+NVM.pc), l
	ret


nvm_op_call:     ;  1
	; get stack pointer in de
	ld	d, (iy+NVM.stack_ptr+1)
	ld	e, (iy+NVM.stack_ptr)
	; store call address in the pc
	push	hl
	call	nvm_op_jump.set_pc_relative_offs
	pop	hl
	inc	hl
	inc	hl
	; write hl - address after call instruction - to stack.
	ld	a, h
	ld	(de), a
	inc	de
	ld	a, l
	ld	(de), a
	inc	de
	; store moved stack pointer
	ld	(iy+NVM.stack_ptr+1), d
	ld	(iy+NVM.stack_ptr), e
	jp	nvm_exec.instructions_from_pc

nvm_op_ret:      ;  2
	; decrement stack pointer, and place contents in pc.
	ld	h, (iy+NVM.stack_ptr+1)
	ld	l, (iy+NVM.stack_ptr)
	dec	hl
	dec	hl
	ld	(iy+NVM.stack_ptr+1), h
	ld	(iy+NVM.stack_ptr), l
	ld	a, (hl)
	ld	(iy+NVM.pc+1), a
	inc	hl
	ld	a, (hl)
	ld	(iy+NVM.pc), a
	jp	nvm_exec.instructions_from_pc

nvm_op_loopset:  ;  3
	; Get loop count
	ld	a, (hl)
	ld	(iy+NVM.loop_cnt), a
	inc	hl
	; Store address in the loop pointer field
	ld	(iy+NVM.loop_ptr+1), h
	ld	(iy+NVM.loop_ptr), l
	jp	nvm_exec.instructions_from_hl

nvm_op_loopend:  ;  4
	ld	a, (iy+NVM.loop_cnt)
	dec	a
	ld	(iy+NVM.loop_cnt), a
	jp	z, nvm_exec.instructions_from_hl
	; jump back to loop
	ld	a, (iy+NVM.loop_ptr+1)
	ld	(iy+NVM.pc+1), a
	ld	a, (iy+NVM.loop_ptr)
	ld	(iy+NVM.pc), a
	jp	nvm_exec.instructions_from_pc

nvm_op_tempo:    ;  5
	ld	ix, OPN_BASE
	ld	(ix+0), OPN_REG_TB
	ld	a, (hl)
	inc	hl
	ld	(ix+1), a
	jp	nvm_exec.instructions_from_hl


; Sets the default rest value associated with notes.
nvm_op_length:   ;  6
	ld	a, (hl)
	ld	(iy+NVM.rest_val), a
	inc	hl
	jp	nvm_exec.instructions_from_hl

; Consumes the following byte as a rest count value.
nvm_op_rest:     ;  7
	ld	a, (hl)
	inc	hl
	cp	00h
	jr	nz, +
	; argument was 0 - used default
	ld	a, (iy+NVM.rest_val)
+:
	ld	(iy+NVM.rest_cnt), a
	jp	nvm_op_finished_yield

; Sets the octave register value.
nvm_op_oct:      ;  8
	ld	a, (hl)
	inc	hl
	; fall-through
nvm_op_oct_commit_a:
	ld	(iy+NVM.octave), a
	jp	nvm_exec.instructions_from_hl

nvm_op_oct_up:   ;  9
	ld	a, (iy+NVM.octave)
	cp	7*8  ; octave already == 7?
	jp	nc, nvm_exec.instructions_from_hl
	add	a, 8
	jr	nvm_op_oct_commit_a

nvm_op_oct_down: ; 10
	ld	a, (iy+NVM.octave)
	and	a  ; octave already at 0?
	jp	z, nvm_exec.instructions_from_hl
	sub	a, 8
	jr	nvm_op_oct_commit_a

nvm_op_inst:     ;
	; de takes instrument ID / offset into list
	ld	d, 00h
	ld	e, (hl)
	inc	hl
	push	hl
	ld	hl, (CurrentContext+NVMCONTEXT.instrument_list_ptr)
	add	hl, de  ; += instrument id offset
	; de take the patch address, also stored in the ch state
	ld	e, (hl)
	ld	(iy+NVMOPN.patch_ptr+0), e
	inc	hl
	ld	d, (hl)
	ld	(iy+NVMOPN.patch_ptr+1), d
	; pull con data.
	IF	OPNPATCH.con_fb == 0  ; this is how I avoid self-owning later
	ld	a, (de)  ; OPNPATCh begins with con_fb
	ELSE
	ld	hl, OPNPATCH.con_fb
	add	hl, de  ; hl := source fb data
	ld	a, (hl)
	ENDIF  ; OPNPATCH.con_fb == 0
	and	a, 07h
	add	a, a
	ld	(iy+NVMOPN.tl_conoffs), a
	; pull TL data.
	ld	hl, OPNPATCH.tl
	add	hl, de  ; hl := source TL data
	ld	a, (hl)
	ld	(iy+NVMOPN.tl+0), a
	inc	hl
	ld	a, (hl)
	ld	(iy+NVMOPN.tl+1), a
	inc	hl
	ld	a, (hl)
	ld	(iy+NVMOPN.tl+2), a
	inc	hl
	ld	a, (hl)
	ld	(iy+NVMOPN.tl+3), a
	; write the patch to the OPN
	ld	de, 10000h-OPNPATCH.tl-3  ; why is there no 16-bit sub???
	add	hl, de  ; wind hl back to the patch start
	ld	a, (iy+NVM.channel_id)
	call	opn_set_patch
	pop	hl
	jp	nvm_exec.instructions_from_hl

nvm_op_vol:      ; 12
	ld	a, (hl)
	ld	(iy+NVM.volume), a
	inc	hl
	jp	nvm_exec.instructions_from_hl

nvm_op_pan:      ; 13
	ld	a, (iy+NVMOPN.pan)
	and	a, 3Fh  ; remove pan bits
	; fall-through to commit
nvm_op_pan_commit_a:
	or	a, (hl)
	inc	hl
	ld	b, a
	ld	(iy+NVMOPN.pan), a
	ld	a, (iy+NVM.channel_id)
	call	opn_set_base_de_sub
	add	a, OPN_REG_MOD
	ld	(de), a
	inc	de
	ld	a, b
	ld	(de), a  ; final pan data from before
	jp	nvm_exec.instructions_from_hl

nvm_op_pms:      ; 14
	ld	a, (iy+NVMOPN.pan)
	and	a, 0F8h  ; remove pms bits
	jr	nvm_op_pan_commit_a

nvm_op_ams:      ; 15
	ld	a, (iy+NVMOPN.pan)
	and	a, 0CFh  ; remove ams bits
	jr	nvm_op_pan_commit_a

nvm_op_opn_reg:  ; 16
	call	opn_set_base_de_sub
	add	a, (hl)
	inc	hl
	ld	(de), a
	inc	de
	ld	a, (hl)
	ld	(de), a
	inc	hl
	jp	nvm_exec.instructions_from_hl

nvm_op_stop:     ; 18
	ld	(iy+NVM.status), NVM_STATUS_INACTIVE
	ret

nvm_op_note_off: ; 18
	ld	a, OPN_REG_KEYON
	ld	(OPN_ADDR0), a  ; addr
	ld	a, (iy+NVM.channel_id)
	ld	(OPN_DATA0), a  ; data
	ld	(iy+NVMOPN.now_block), 80h  ; Mark no portamento
	jp	nvm_exec.instructions_from_hl

nvm_op_slide:    ; 19
	ld	a, (hl)
	inc	hl
	ld	(iy+NVM.portamento), a
	jp	nvm_exec.instructions_from_hl

nvm_op_pcmrate:  ; 20
	ld	a, OPN_REG_TA_HI
	ld	(OPN_ADDR0), a
	ld	a, (hl)
	inc	hl
	ld	(OPN_DATA0), a
	nop
	ld	a, OPN_REG_TA_LO
	ld	(OPN_ADDR0), a
	ld	a, (hl)
	inc	hl
	ld	(OPN_DATA0), a
	jp	nvm_exec.instructions_from_hl

nvm_op_pcmmode:  ; 21
	ld	a, OPN_REG_DACSEL
	ld	(OPN_ADDR0), a  ; addr
	ld	a, (hl)
	ld	(OPN_DATA0), a  ; addr
	inc	hl
	jp	nvm_exec.instructions_from_hl

nvm_op_pcmplay:  ; 22
	ld	d, 00h
	ld	e, (hl)
	inc	hl
	push	hl
	ld	hl, (PcmListPtr)
	add	hl, de  ; += pcm id offset
	ld	a, (hl)
	call	bank_set
	inc	hl
	; de take the PCM address
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ld	(PcmAddr), de
	; Enable PCM
	pcm_poll_enable
	pop	hl
	jp	nvm_exec.instructions_from_hl

nvm_op_pcmstop:  ; 23
	pcm_poll_disable
	jp	nvm_exec.instructions_from_hl

; ------------------------------------------------------------------------------
;
; Notes
;
; ------------------------------------------------------------------------------

nvm_opn_tlmod_sub:

tlmod macro opno
	ld	a, (CurrentContext+NVMCONTEXT.global_volume)
	add	a, (iy+NVMOPN.tl+opno)
	add	a, (iy+NVM.volume)
	cp	80h
	jr	c, +
	ld	a, 7Fh
+:
	ld	i, a
	ld	a, c
	add	a, OPN_REG_TL+(4*opno)
	ld	(de), a
	inc	de
	ld	a, i
	ld	(de), a  ; updated TL value
	dec	de
	endm

	; Modify tl. Must leave B alone for use afterwards.
	ld	a, (iy+NVMOPN.tl_conoffs)
	jptbl_dispatch
	jr	.note_volmod_op4
	jr	.note_volmod_op4
	jr	.note_volmod_op4
	jr	.note_volmod_op4
	jr	.note_volmod_op24
	jr	.note_volmod_op234
	jr	.note_volmod_op234
	jr	.note_volmod_op1234
.note_volmod_op24:
	tlmod	1
	jr	.note_volmod_op4
.note_volmod_op1234:
	tlmod	0
.note_volmod_op234:
	tlmod	1
.note_volmod_op34:
	tlmod	2
.note_volmod_op4:
	tlmod	3

	ret

nvm_op_note:
	ld	b, a  ; back up the note data in b

	;
	; Prepare OPN offset
	;
	ld	a, (iy+NVM.channel_id)
	opn_set_base_de
	ld	c, a

	;
	; Mark pending key press (if applicable)
	;
	ld	a, b
	and	a, nvm_NOTE_NO_KEY_ON_FLAG
	jr	nz, +
	ld	a, 01h
	ld	(iy+NVMOPN.key_pending), a
+:

	;
	; Volume modulation
	;

	call	nvm_opn_tlmod_sub

	;
	; Set target octave and frequency.
	;

	; Adopt current octave setting (really, it's the block reg value).
	ld	a, (iy+NVM.octave)
	ld	(iy+NVMOPN.tgt_block), a

	; Note lookup
	ld	a, b    ; restore note
	exx  ; avoid pushing hl and bc


;	push	hl      ; we'll need this later for rest processing.
	ld	hl, .freq_tbl
	and	a, 1Fh  ; index into freq table
	ld	e, a    ; offset freq tbl index with de
	ld	d, 00h
	add	hl, de
	ld	a, (hl)
	ld	(iy+NVMOPN.tgt_freq), a
	inc	hl
	ld	a, (hl)
	ld	(iy+NVMOPN.tgt_freq+1), a

	;
	; If note was off before, skip portamento.
	;
	ld	a, (iy+NVMOPN.now_block)
	and	a
	jp	p, +
	ld	a, (iy+NVMOPN.tgt_block)
	ld	(iy+NVMOPN.now_block), a
	ld	a, (iy+NVMOPN.tgt_freq)
	ld	(iy+NVMOPN.now_freq), a
	ld	a, (iy+NVMOPN.tgt_freq+1)
	ld	(iy+NVMOPN.now_freq+1), a
+:

	;
	; Optional rest duration byte
	;
;	pop	hl
	exx
	ld	a, b
	and	a, nvm_NOTE_REST_FLAG
	jp	nz, nvm_op_rest
	; Else just adopt the default rest value.
	ld	a, (iy+NVM.rest_val)
	ld	(iy+NVM.rest_cnt), a
	jp	nvm_op_finished_yield

.freq_tbl:
	dw	OPN_NOTE_C
	dw	OPN_NOTE_Cs
	dw	OPN_NOTE_D
	dw	OPN_NOTE_Ds
	dw	OPN_NOTE_E
	dw	OPN_NOTE_F
	dw	OPN_NOTE_Fs
	dw	OPN_NOTE_G
	dw	OPN_NOTE_Gs
	dw	OPN_NOTE_A
	dw	OPN_NOTE_As
	dw	OPN_NOTE_B

; ------------------------------------------------------------------------------
;
; Portamento
;
; ------------------------------------------------------------------------------

nvm_opn_port_read_tgt_freq_de macro
	ld	a, (iy+NVMOPN.tgt_freq+1)
	ld	d, a
	ld	a, (iy+NVMOPN.tgt_freq)
	ld	e, a
	endm

nvm_opn_port_write_tgt_freq_de macro
	ld	a, d
	ld	(iy+NVMOPN.tgt_freq+1), a
	ld	a, e
	ld	(iy+NVMOPN.tgt_freq), a
	endm

nvm_opn_port_read_now_freq_hl macro
	ld	a, (iy+NVMOPN.now_freq+1)
	ld	h, a
	ld	a, (iy+NVMOPN.now_freq)
	ld	l, a
	endm

nvm_opn_port_write_now_freq_hl macro
	ld	a, h
	ld	(iy+NVMOPN.now_freq+1), a
	ld	a, l
	ld	(iy+NVMOPN.now_freq), a
	endm

nvm_opn_port_write_now_freq_de macro
	ld	a, d
	ld	(iy+NVMOPN.now_freq+1), a
	ld	a, e
	ld	(iy+NVMOPN.now_freq), a
	endm

nvm_opn_portamento:
	ld	a, (iy+NVM.portamento)
	or	a
	jr	nz, .port_change ; TODO
	; Portamento of 0 = instant
	ld	a, (iy+NVMOPN.tgt_freq)
	ld	(iy+NVMOPN.now_freq), a
	ld	a, (iy+NVMOPN.tgt_freq+1)
	ld	(iy+NVMOPN.now_freq+1), a
	ld	a, (iy+NVMOPN.tgt_block)
	ld	(iy+NVMOPN.now_block), a
	ret

.port_change:
	nvm_opn_port_read_now_freq_hl
	; Compare target block to now
	ld	a, (iy+NVMOPN.now_block)
	ld	b, (iy+NVMOPN.tgt_block)
	cp	b
	jr	c, .target_block_higher
	jp	z, .target_block_same
; Target block is an octave below. Freq sweeps down, then if the frequency dips
; below the OPN_NOTE_C threshhold, we decrement the octave and wrap freq.
.target_block_lower:
	; sub portamento from now freq
	ld	a, (iy+NVM.portamento)
	sub_a_from_hl
	; Is hl below OPN_NOTE_C?
	ld	de, OPN_NOTE_C
	compare_hl_r16 de
	jr	nc, .now_freq_hl_commit
	; if so, decrement now_block and add OPN_NOTE_C.
	ld	de, OPN_NOTE_C  ; for addition
	ld	a, (iy+NVMOPN.now_block)
	sub	08h
	jr	.new_block_mask_and_set

; Target block is an octave above. Freq sweeps up, then if it dips above
; OPN_NOTE_C*2, increment the octave and wrap req.
.target_block_higher:
	; add portamento to now freq
	ld	a, (iy+NVM.portamento)
	add_a_to_hl
	; Is hl above OPN_NOTE_C*2?
	ld	de, OPN_NOTE_C*2
	compare_hl_r16 de
	jr	c, .now_freq_hl_commit
	; if so, increment now_block and subtract OPN_NOTE_C.
	ld	de, 10000h-OPN_NOTE_C  ; subtraction of OPN_NOTE_C
	ld	a, (iy+NVMOPN.now_block)
	add	a, 08h
.new_block_mask_and_set
	and	3Fh  ; TODO: Remove? is there any harm to those upper bits?
	ld	(iy+NVMOPN.now_block), a
	add	hl, de
+:
	; Write back the freq change and exit.
.now_freq_hl_commit:
	nvm_opn_port_write_now_freq_hl
	ret

.target_block_same:
	nvm_opn_port_read_tgt_freq_de
	; Is the target frequency higher?
	compare_hl_r16 de
	ret	z  ; same block, same freq. get outta here
	jr	c, .target_freq_higher
.target_freq_lower:
	ld	a, (iy+NVM.portamento)
	sub_a_from_hl
	; Did we surpass the target?
	compare_hl_r16 de
	jr	nc, .now_freq_hl_commit  ; nope
	; Adopt target and get out.
.now_freq_de_commit:
	nvm_opn_port_write_now_freq_de
	ret
.target_freq_higher:
	ld	a, (iy+NVM.portamento)
	add_a_to_hl
	; Did we surpass the target?
	compare_hl_r16 de
	jr	c, .now_freq_hl_commit  ; nope
	jr	.now_freq_de_commit  ; adopt target and get out.


; ------------------------------------------------------------------------------
;
; Key On/Off and Frequency Output (OPN)
;
; ------------------------------------------------------------------------------

; iy = channel struct
; if a key is pending, handles key off/on cycle.
nvmopn_update_output:
	ld	a, (iy+NVM.status)
	and	a
	ret	m  ; return if muted.
	ld	a, (iy+NVMOPN.key_pending)
	or	a
	jr	z, .express_freq_sub
	ret	z
	; First key off.
	ld	a, OPN_REG_KEYON
	ld	(OPN_ADDR0), a  ; addr
	ld	a, (iy+NVM.channel_id)
	ld	(OPN_DATA0), a  ; data

	push	af
	call	.express_freq_sub

	; Then key on.
	; TODO: Can we avoid a second address set here?
	ld	a, OPN_REG_KEYON
	ld	(OPN_ADDR0), a  ; addr
	pop	af  ; channel ID from before. avoid a second iy access
	or	a, 0F0h  ; all operators select.
	ld	(OPN_DATA0), a  ;
	; Clear out pending key flag.
	xor	a  ; a := 0
	ld	(iy+NVMOPN.key_pending), a
	ret

; Writes frequency to fn registers.
.express_freq_sub:
	ld	a, (iy+NVM.channel_id)
	call	opn_set_base_de_sub
	ld	c, a

	; Hi reg sel
	ld	a, c
	add	a, OPN_REG_FN_HI
	ld	(de), a
	inc	de

	; Hi reg data
	ld	a, (iy+NVMOPN.now_freq+1)
	or	a, (iy+NVMOPN.now_block)
	ld	(de), a
	dec	de
	opn_set_delay

	; Low reg sel
	ld	a, c
	add	a, OPN_REG_FN_LO
	ld	(de), a
	inc	de
	ld	a, (iy+NVMOPN.now_freq)
	ld	(de), a
	ret
