; ------------------------------------------------------------------------------
;
; Main Poll Function
;
; A group of channels is executed for one tick.
;
; in:
;      a = count
;     iy = NVM head
;     de = struct size (increment for iy when iterating)
;
; ------------------------------------------------------------------------------

nvm_poll:
	ld	(ChannelIterCount), a
	ld	(ChannelIterSize), de
.loop:
	pcm_service
	; Skip inactive channels
	ld	a, (iy+NVM.status)
	and	a  ; NVM_STATUS_INACTIVE?
	jr	z, .next_chan
	call	nvm_exec
	pcm_service
	call	nvm_pitch
	pcm_service
	call	nvm_update_output
.next_chan:
	ld	de, 6502h  ; to be replaced as ChannelIterSize
	add	iy, de
.iter_count_ld:
	ld	a, 42h  ; to be replaced as ChannelIterCount
	dec	a
	ld	(ChannelIterCount), a
	jr	nz, .loop
	ret

ChannelIterCount = nvm_poll.iter_count_ld+1
ChannelIterSize = nvm_poll.next_chan+1

; ------------------------------------------------------------------------------
;
; Execution of NVM Instructions
;
; ------------------------------------------------------------------------------

nvm_op_finished_yield:
	call	nvm_store_hl_pc_sub
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
	pcm_service
	; Time for instructions
	ld	h, (iy+NVM.pc+1)
	ld	l, (iy+NVM.pc)
.instructions_from_hl:
	ld	a, (hl)
	inc	hl

	; If A is >= 80h, it's a note, and is handled differently.
	and	a
	jp	m, nvm_op_note
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
	jp	nvm_op_lfo      ; 16
	jp	nvm_op_stop     ; 17
	jp	nvm_op_note_off ; 18
	jp	nvm_op_slide    ; 19
	jp	nvm_op_pcmrate  ; 20
	jp	nvm_op_pcmmode  ; 21
	jp	nvm_op_pcmplay  ; 22
	jp	nvm_op_pcmstop  ; 23
	jp	nvm_op_opn_reg  ; 24
	jp	nvm_op_trn      ; 25
	jp	nvm_op_trn_add  ; 26
	jp	nvm_op_trn_sub  ; 27
	jp	nvm_op_noise    ; 28

; ------------------------------------------------------------------------------
;
; NVM Opcodes
;
; ------------------------------------------------------------------------------


nvm_op_jump:     ;  0
	; two bytes - relative pointer to jump to
	call	nvm_deref_hl_relative_offs_sub
	jr	nvm_exec.instructions_from_hl

nvm_op_call:     ;  1
	call	nvm_get_stack_ptr_de_sub
	; store call address in the pc
	push	hl
	call	nvm_deref_hl_relative_offs_sub
	call	nvm_store_hl_pc_sub
	pop	hl
	inc	hl
	inc	hl
	; write hl - address after call instruction - to stack.
	ld	a, l
	ld	(de), a
	inc	de
	ld	a, h
	ld	(de), a
	inc	de
	; store moved stack pointer
	call	nvm_set_stack_ptr_de_sub
	jp	nvm_exec.instructions_from_pc

nvm_op_ret:      ;  2
	; decrement stack pointer, and place contents in pc.
	call	nvm_get_stack_ptr_de_sub
	dec	de
	dec	de
	call	nvm_set_stack_ptr_de_sub
	ex	de, hl
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ex	de, hl
	jp	nvm_exec.instructions_from_hl

nvm_op_loopset:  ;  3
	; Get loop count
	ld	a, (hl)
	inc	hl
	; Advance loop stack ptr and set count.
	call	nvm_get_loop_stack_ptr_de_sub
	inc	de
	call	nvm_set_loop_stack_ptr_de_sub
	ld	(de), a
	jp	nvm_exec.instructions_from_hl

nvm_get_loop_stack_ptr_de_sub:
	ld	d, (iy+NVM.loop_stack_ptr+1)
	ld	e, (iy+NVM.loop_stack_ptr)
	ret

nvm_set_loop_stack_ptr_de_sub:
	ld	(iy+NVM.loop_stack_ptr+1), d
	ld	(iy+NVM.loop_stack_ptr), e
	ret

nvm_get_stack_ptr_de_sub:
	ld	d, (iy+NVM.stack_ptr+1)
	ld	e, (iy+NVM.stack_ptr)
	ret

nvm_set_stack_ptr_de_sub:
	ld	(iy+NVM.stack_ptr+1), d
	ld	(iy+NVM.stack_ptr), e
	ret

nvm_op_loopend:  ;  4
	call	nvm_get_loop_stack_ptr_de_sub
	ld	a, (de)
	dec	a
	ld	(de), a
	jr	nz, nvm_op_jump  ; Branch backwards
	; Bump back loop stack ptr and proceed.
	dec	de
	call	nvm_set_loop_stack_ptr_de_sub
	inc	hl
	inc	hl
	jp	nvm_exec.instructions_from_hl

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
	cp	7  ; octave already == 7?
	jp	nc, nvm_exec.instructions_from_hl
	inc	a
	jr	nvm_op_oct_commit_a

nvm_op_oct_down: ; 10
	ld	a, (iy+NVM.octave)
	and	a  ; octave already at 0?
	jp	z, nvm_exec.instructions_from_hl
	dec	a
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
	ld	(iy+NVM.instrument_ptr+0), e
	inc	hl
	ld	d, (hl)
	ld	(iy+NVM.instrument_ptr+1), d

	ld	a, (iy+NVM.mute)
	and	a
	call	p, nvm_load_inst
	pop	hl
	jp	nvm_exec.instructions_from_hl

nvm_op_vol:      ; 12
	ld	b, 7Fh
	ld	a, (iy+NVM.channel_id)
	and	a
	jp	p, +
	ld	b, 0Fh
+:
	ld	a, b
	and	a, (hl)
	ld	(iy+NVM.volume), a
	inc	hl
	; OPN needs a TL update
	ld	a, (iy+NVM.channel_id)  ; bit 7 if PSG
	or	a, (iy+NVM.mute)        ; bit 7 if muted
	and	a
	jp	m, +
	call	nvmopn_tlmod
+
	jp	nvm_exec.instructions_from_hl

nvm_op_pan:      ; 13
	ld	a, 3Fh  ; remove pan bits
	; fall-through to commit
nvm_op_pan_commit_mask_a:
	and	a, (iy+NVMOPN.pan)
	or	a, (hl)
	inc	hl
	ld	(iy+NVMOPN.pan), a
	call	nvmopn_set_mod_sub
	jp	nvm_exec.instructions_from_hl

nvm_op_pms:      ; 14
	ld	a, 0F8h  ; remove pms bits
	jr	nvm_op_pan_commit_mask_a

nvm_op_ams:      ; 15
	ld	a, 0CFh  ; remove ams bits
	jr	nvm_op_pan_commit_mask_a

nvm_op_lfo:      ; 15
	ld	a, OPN_REG_LFO
	call	nvm_write_opn_global_hl_sub
	jp	nvm_exec.instructions_from_hl

nvm_op_note_off: ; 18
	call	nvm_note_off_sub
	jp	nvm_exec.instructions_from_hl

nvm_op_slide:    ; 19
	ld	a, (hl)
	inc	hl
	ld	(iy+NVM.portamento), a
	jp	nvm_exec.instructions_from_hl

nvm_op_pcmrate:  ; 20
	ld	de, CurrentContext+NVMCONTEXT.pcm_rate
	ldi
	ldi
	jp	nvm_exec.instructions_from_hl

nvm_op_pcmmode:  ; 21
	ld	a, OPN_REG_DACSEL
	call	nvm_write_opn_global_hl_sub
	jp	nvm_exec.instructions_from_hl

nvm_op_pcmplay:  ; 22
	ld	d, 00h
	ld	e, (hl)
	inc	hl
	push	hl
.pcm_list_ptr_load:
	ld	hl, 6502h ; Immedaite replaced as PcmListPtr
	add	hl, de  ; += pcm id offset
	ld	a, (hl)
	call	bank_set
	inc	hl
	; de take the PCM address
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ld	(PcmAddr), de
	; Set timer A rate
	ld	hl, CurrentContext+NVMCONTEXT.pcm_rate
	ld	a, OPN_REG_TA_HI
	call	nvm_write_opn_global_hl_sub
	ld	a, OPN_REG_TA_LO
	call	nvm_write_opn_global_hl_sub
	; Enable PCM
	pcm_poll_enable
	pop	hl
	jp	nvm_exec.instructions_from_hl

PcmListPtr = .pcm_list_ptr_load+1

nvm_op_pcmstop:  ; 23
	pcm_poll_disable
	jp	nvm_exec.instructions_from_hl

nvm_op_opn_reg:  ; 24
	call	opn_set_base_de_sub
	add	a, (hl)
	inc	hl
	ld	(de), a
	inc	de
	ld	a, (hl)
	ld	(de), a
	inc	hl
	jp	nvm_exec.instructions_from_hl

nvm_op_trn:      ; 25
	ld	a, (hl)
.set:
	ld	(iy+NVM.transpose), a
	inc	hl
	jp	nvm_exec.instructions_from_hl

nvm_op_stop:     ; 18
	ld	(iy+NVM.status), NVM_STATUS_INACTIVE
	; fall-through to note off
.note_off_mute_unset_load:
	ld	a, 00h  ; to be replaced; this becomes "IsSfx"
IsSfx = .note_off_mute_unset_load+1
	and	a
	jr	z, +
	; If it's a sound effect, unmute corresponding channel.
	ld	a, (iy+NVMSFX.mute_channel)
	call	nvm_sfx_unmute_channel
+:
	jr	nvm_note_off_sub.unconditional


nvm_op_noise:    ; 28
	ld	a, 0E0h  ; noise
	or	(hl)  ; noise value
	inc	hl
	ld	(PSG), a
	; A key-on is only triggered if it's not complex noise.
	and	03h
	cp	a, 03h
	jr	z, .noise_special_en
	nvm_disable_noise_ctrl
	jp	nvm_exec.instructions_from_hl
.noise_special_en:
	nvm_enable_noise_ctrl
	jp	nvm_exec.instructions_from_hl


;
; These tiny support functions are here for things that are done just often
; enough that a 3-byte call saves a tiny bit of space compared to inlining
; the functionality. With 8K between program, work RAM, and track data, every
; saved byte helps towards the cause...
;

nvm_op_trn_add:   ; 26
	ld	a, (iy+NVM.transpose)
	add	a, (hl)
	jr	nvm_op_trn.set

nvm_op_trn_sub:   ; 27
	ld	a, (iy+NVM.transpose)
	sub	a, (hl)
	jr	nvm_op_trn.set

; a = reg
; (hl) = data to write
; increments hl by one byte, clobbers a.
nvm_write_opn_global_hl_sub:
	ld	(OPN_ADDR0), a  ; addr
	ld	a, (hl)
	ld	(OPN_DATA0), a  ; data
	inc	hl
	ret

; hl = start of relative label offset argument
; clobbers bc, messes with hl
nvm_deref_hl_relative_offs_sub:
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	add	hl, bc
	ret

nvm_note_off_sub:
	ld	a, (iy+NVM.mute)
	and	a
	ret	m  ; return if muted (NVM_MUTE_MUTED)
.unconditional:
	ld	a, (iy+NVM.channel_id)
	and	a
	jp	p, .opn
	xor	a
	ld	(iy+NVMPSG.key_on), a  ; let envelope take care of the rest
	ret
.opn:
	ld	a, OPN_REG_KEYON
	ld	(OPN_ADDR0), a  ; addr
	ld	a, (iy+NVM.channel_id)
	ld	(OPN_DATA0), a  ; data
	ld	(iy+NVMOPN.now_block), 80h  ; Mark no portamento
	ret

nvmopn_set_mod_sub:
	ld	a, (iy+NVM.mute)
	and	a
	ret	m  ; return if muted (NVM_MUTE_MUTED)

.direct:
	ld	a, (iy+NVM.channel_id)
	call	opn_set_base_de_sub
	add	a, OPN_REG_MOD
	ld	(de), a
	inc	de
	ld	a, (iy+NVMOPN.pan)
	ld	(de), a  ; final pan data from before
	ret


