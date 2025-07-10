;
; Channel interpreter.
;

;
; Default data
;
avm_data_nulltrk:
	db	AVM_JUMP
	dw	avm_data_nulltrk

avmg_data_default_instrument_list:
	dw	avm_data_default_patch

avm_data_default_patch:
	;          con, fb
	opnp_con_fb  0,  1
	opnp_mul_dt  7,  0  ; 0
	opnp_mul_dt  0,  3  ; 2
	opnp_mul_dt  0, -3  ; 1
	opnp_mul_dt  0,  0  ; 3
	opnp_tl     31      ; 0
	opnp_tl     17      ; 2
	opnp_tl     43      ; 1
	opnp_tl      7      ; 3
	opnp_ar_ks  31,  2  ; 0
	opnp_ar_ks  31,  2  ; 2
	opnp_ar_ks  31,  2  ; 1
	opnp_ar_ks  31,  2  ; 3
	opnp_dr_am  18,  0  ; 0
	opnp_dr_am  10,  0  ; 2
	opnp_dr_am  14,  0  ; 1
	opnp_dr_am  10,  0  ; 3
	opnp_sr      0      ; 0
	opnp_sr      0      ; 2
	opnp_sr      0      ; 1
	opnp_sr      0      ; 3
	opnp_rr_sl   8,  2  ; 0
	opnp_rr_sl   5,  2  ; 2
	opnp_rr_sl   5,  2  ; 1
	opnp_rr_sl   5,  2  ; 3
	opnp_ssg_eg  0      ; 0
	opnp_ssg_eg  0      ; 2
	opnp_ssg_eg  0      ; 1
	opnp_ssg_eg  0      ; 3
;
; Initializes all channels.
;
avm_init:
	ld	hl, .channel_id_tbl
	; Initialize channels
	ld	b, TOTAL_CHANNEL_COUNT
	ld	iy, AvmOpn
-:
	ld	a, (hl)
	push	hl
	push	bc
	call	.init_sub
	pop	bc
	pop	hl
	inc	hl

	ld	a, AVM.len
	add_a_to_iy
	djnz	-

	; Set global state
	ld	iy, AvmGlobal
	ld	hl, avmg_data_default_instrument_list
	ld	(iy+AVMG.instrument_list_ptr+1), h
	ld	(iy+AVMG.instrument_list_ptr), l
	ret

.channel_id_tbl:
	db	0, 1, 2  ; FM0-FM2
	db	4, 5, 6  ; FM3-FM6
	db	0, 1, 2 ; FM0-FM2 sound effects
	db	00h, 20h, 40h, 60h  ; PSG 0-3
	db	00h, 20h  ; PSG 0-1 sound effects

; iy = channel state struct
; a = channel id / offset
.init_sub:
	push	af
	; clear channel struct
	ld	a, iyh
	ld	h, a
	ld	a, iyl
	ld	l, a
	push	hl
	; DE := hl + 1
	ld	e, l
	ld	d, h
	inc	de
	ld	(hl), 00h  ; First byte is initialized with clear value 00h
	ld	bc, AVM.len
	ldir
	; Install null track
	ld	hl, avm_data_nulltrk
	ld	(iy+AVM.pc+1), h
	ld	(iy+AVM.pc), l
	; Set stack pointer
	pop	hl
	ld	a, AVM.stack
	add_a_to_hl
	; hl now points to the stack start.
	ld	(iy+AVM.stack_ptr+1), h
	ld	(iy+AVM.stack_ptr), l
	; channel default
	ld	(iy+AVM.rest_val), AVM_REST_DEFAULT
	; patch default
	ld	hl, avm_data_default_patch
	ld	(iy+AVM.patch_ptr+1), h
	ld	(iy+AVM.patch_ptr), l

	; mark channel offset
	pop	af
	ld	(iy+AVM.channel_id), a

	ret

; Assigns a track to an AVM channel
; de = track head pointer
avm_set_head:
	; Install the head pointer
	ld	(iy+AVM.pc+1), d
	ld	(iy+AVM.pc), e
	; Mark channel as active
	ld	(iy+AVM.status), AVM_STATUS_ACTIVE
	ret

;
; Iterates through all active channels
;
avm_poll:
	; Initialize channels
	ld	b, TOTAL_CHANNEL_COUNT-1  ; let it fall through for the final
	ld	iy, AvmOpn
-:
	push	bc
	; Skip inactive channels
	ld	a, (iy+AVM.status)
	cp	AVM_STATUS_INACTIVE
	jr	z, .next_chan
	call	.exec
.next_chan:
	ld	a, AVM.len
	add_a_to_iy
	pop	bc
	djnz	-
	ret
	

.exec:
	; TODO: macros / envelopes here
	; If rest counter > 0, decrement and proceed
	ld	a, (iy+AVM.rest_cnt)
	cp	00h
	jr	z, +
	dec	a
	ld	(iy+AVM.rest_cnt), a
	ret
+:
	; Time for instructions
	ld	h, (iy+AVM.pc+1)
	ld	l, (iy+AVM.pc)
	ld	a, (hl)
	inc	hl
	; If A is >= 80h, it's a note, and is handled differently.
	bit	7, a
	jp	nz, .handle_note
	; Else, it's a control instruction.
	jptbl_dispatch
	jp	.avm_op_jump     ;  0
	jp	.avm_op_call     ;  1
	jp	.avm_op_ret      ;  2
	jp	.avm_op_loopset  ;  3
	jp	.avm_op_loopend  ;  4
	jp	.avm_op_timer    ;  5
	jp	.avm_op_length   ;  6
	jp	.avm_op_rest     ;  7
	jp	.avm_op_oct      ;  8
	jp	.avm_op_oct_up   ;  9
	jp	.avm_op_oct_down ; 10
	jp	.avm_op_inst     ; 11
	jp	.avm_op_vol      ; 12
	jp	.avm_op_pan      ; 13
	jp	.avm_op_lfo      ; 14
	jp	.avm_op_opn_reg  ; 15
	jp	.avm_op_stop     ; 16

.avm_op_jump:     ;  0
	; two bytes - pointer to jump to
	ld	a, (hl)
	ld	(iy+AVM.pc), a
	inc	hl
	ld	a, (hl)
	ld	(iy+AVM.pc+1), a
	jp	.exec

.avm_op_call:     ;  1
; Read address argument and set pc to it
; Push address after this instruction to stack
; advance stack
	; get stack pointer in de
	ld	d, (iy+AVM.stack_ptr+1)
	ld	e, (iy+AVM.stack_ptr)
	; store call address in the pc
	ld	a, (hl)
	ld	(iy+AVM.pc), a
	inc	hl
	ld	a, (hl)
	ld	(iy+AVM.pc+1), a
	inc	hl
	; write hl - address after call instruction - to stack.
	ld	a, h
	ld	(de), a
	inc	de
	ld	a, l
	ld	(de), a
	inc	de
	; store moved stack pointer
	ld	(iy+AVM.stack_ptr+1), d
	ld	(iy+AVM.stack_ptr), e
	jp	.exec

.avm_op_ret:      ;  2
.avm_op_loopset:  ;  3
.avm_op_loopend:  ;  4
	; TODO
	jp	.instruction_finished
.avm_op_timer:    ;  5
	ld	ix, OPN_BASE
	ld	(ix+0), OPN_REG_TB
	ld	a, (hl)
	inc	hl
	ld	(ix+1), a
	jp	.instruction_finished


; Sets the default rest value associated with notes.
.avm_op_length:   ;  6
	ld	a, (hl)
	ld	(iy+AVM.rest_val), a
	inc	hl
	jp	.instruction_finished

; Sets the octave register value.
.avm_op_oct:      ;  8
	ld	a, (hl)
	inc	hl
.avm_op_oct_commit_a
	ld	(iy+AVM.octave), a
	jp	.instruction_finished

.avm_op_oct_up:   ;  9
	ld	a, (iy+AVM.octave)
	or	a    ; carry reset
	cp	7*8  ; octave already > 7?
	jp	nc, .instruction_finished
	add	a, 8
	jr	.avm_op_oct_commit_a

.avm_op_oct_down: ; 10
	ld	a, (iy+AVM.octave)
	cp	0*8  ; octave already > 7?
	jp	z, .instruction_finished
	sub	a, 8
	jr	.avm_op_oct_commit_a

.avm_op_inst:     ; 11
.avm_op_vol:      ; 12
.avm_op_pan:      ; 13
.avm_op_lfo:      ; 14
.avm_op_opn_reg:  ; 15
	jp	.instruction_finished
.avm_op_stop:     ; 16
	ld	(iy+AVM.status), AVM_STATUS_INACTIVE
	jp	.instruction_finished

.instruction_finished:
	ld	(iy+AVM.pc+1), h
	ld	(iy+AVM.pc), l
	jp	.exec

.handle_note:
	push	hl  ; store note pointer

	ld	b, a  ; back up note in b
	ld	a, (iy+AVM.channel_id)
	opn_set_base_ix
	ld	c, a  ; Keep channel offset around in C.
	; First key off
	ld	(ix+0), OPN_REG_KEYON
	ld	(ix+1), c
;	call	opn_keyon_delay_sub

	; High frequency + octave.
	ld	hl, .freq_tbl

	; Regsel with ch offs
	ld	a, c
	add	a, OPN_REG_FN_HI
	ld	(ix+0), a
	; Regdata high
	ld	a, b    ; restore note
	and	a, 1Fh  ; index into freq table
	add_a_to_hl
	ld	a, (hl)
	or	a, (iy+AVM.octave)
	ld	(ix+1), a

	; Low frequency
	inc	hl
	; Regsel with ch offs
	ld	a, c
	add	a, OPN_REG_FN_LO
	ld	(ix+0), a
	; Regdata low
	ld	a, (hl)
	ld	(ix+1), a

	; The key on.
	ld	a, c  ; Keep channel offset around in C.
	ld	(ix+0), OPN_REG_KEYON
	or	a, 0F0h
	ld	(ix+1), a  ; turn on all operators

	; TODO: Reapply TL with volume argument applied.

	; Finally - if the note had bit 5 set (20h), then rest with the specified value.
	pop	hl
	ld	a, b
	and	a, AVM_NOTE_REST_FLAG
	jr	nz, .avm_op_rest
	; Else just adopt the default rest value.
	ld	a, (iy+AVM.rest_val)
	ld	(iy+AVM.rest_cnt), a
	jp	.instruction_finished

.freq_tbl:
	db	(OPN_NOTE_C  >> 8) & 07h, OPN_NOTE_C  & 0FFh
	db	(OPN_NOTE_Cs >> 8) & 07h, OPN_NOTE_Cs & 0FFh
	db	(OPN_NOTE_D  >> 8) & 07h, OPN_NOTE_D  & 0FFh
	db	(OPN_NOTE_Ds >> 8) & 07h, OPN_NOTE_Ds & 0FFh
	db	(OPN_NOTE_E  >> 8) & 07h, OPN_NOTE_E  & 0FFh
	db	(OPN_NOTE_F  >> 8) & 07h, OPN_NOTE_F  & 0FFh
	db	(OPN_NOTE_Fs >> 8) & 07h, OPN_NOTE_Fs & 0FFh
	db	(OPN_NOTE_G  >> 8) & 07h, OPN_NOTE_G  & 0FFh
	db	(OPN_NOTE_Gs >> 8) & 07h, OPN_NOTE_Gs & 0FFh
	db	(OPN_NOTE_A  >> 8) & 07h, OPN_NOTE_A  & 0FFh
	db	(OPN_NOTE_As >> 8) & 07h, OPN_NOTE_As & 0FFh
	db	(OPN_NOTE_B  >> 8) & 07h, OPN_NOTE_B  & 0FFh

; Consumes the following byte as a rest count value.
.avm_op_rest:     ;  7
	ld	a, (hl)
	inc	hl
	cp	00h
	jr	nz, +
	; argument was 0 - used default
	ld	a, (iy+AVM.rest_val)
+:
	ld	(iy+AVM.rest_cnt), a
	jp	.instruction_finished
