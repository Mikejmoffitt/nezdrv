;
; Channel interpreter.
;


; ------------------------------------------------------------------------------
;
; Initialization
;
; ------------------------------------------------------------------------------
nvm_init:
	ld	hl, .channel_id_tbl
	ld	b, TOTAL_CHANNEL_COUNT
	ld	iy, NvmStart
-:
	ld	a, (hl)
	push	hl
	push	bc
	call	.init_sub
	pop	bc
	pop	hl
	inc	hl

	ld	de, NVM.len
	add	iy, de
	djnz	-
	ret

.channel_id_tbl:
	db	0, 1, 2  ; FM0-FM2 bgm
	db	4, 5, 6  ; FM3-FM6 bgm
	db	00h, 20h, 40h, 60h  ; PSG 0-3 bgm
	db	0, 1, 2 ; FM0-FM2 sound effects
	db	00h, 20h, 40h, 60h  ; PSG 0-3 sound effects

; iy = channel state struct
; a = channel id / offset
.init_sub:
	push	af
	; clear channel struct
	ld	a, iyh
	ld	h, a
	ld	a, iyl
	ld	l, a
	; DE := hl + 1
	ld	e, l
	ld	d, h
	inc	de
	ld	(hl), 00h  ; First byte is initialized with clear value 00h
	ld	bc, NVM.len
	ldir
	; mark channel offset
	pop	af
	ld	(iy+NVM.channel_id), a
	; fall-through to nvm_reset_sub

; iy = NVM head
; clobbers hl
nvm_reset_sub:
	; Zero some defaults to inactive
	xor	a
	ld	(iy+NVM.status), a      ; inactive
	ld	(iy+NVM.portamento), a  ; no portamento
	ld	(iy+NVM.vib_mag), a     ; no vibrato
	ld	(iy+NVM.vib_cnt), a     ; v counter reset
	; Set stack pointer
	ld	a, iyh
	ld	h, a
	ld	a, iyl
	ld	l, a
	ld	de, NVM.stack
	add	hl, de
	ld	(iy+NVM.stack_ptr+1), h
	ld	(iy+NVM.stack_ptr), l
	; channel default
	ld	(iy+NVM.rest_val), nvm_REST_DEFAULT
	; default to both outputs, no modulation
	ld	(iy+NVM.pan), OPN_PAN_L|OPN_PAN_R
	; No portamento for first note.
	ld	(iy+NVM.now_block), 80h
	ret

nvm_bgm_reset:
	ld	b, TOTAL_BGM_CHANNEL_COUNT
	ld	iy, NVMBgmStart
-:
	call	nvm_reset_sub
	ld	de, NVM.len
	add	iy, de
	djnz	-
	ret

; ------------------------------------------------------------------------------
;
; Track Load
;
; ------------------------------------------------------------------------------
nvm_load_track:
	call	nvm_bgm_reset
	; Set up tracks
	ld	b, OPN_BGM_CHANNEL_COUNT
	ld	hl, TrackBuffer+TRACKINFO.track_list_ptr
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ld	hl, 0
	add	hl, de
	ld	iy, NvmBgmStart
-:
	; de takes pointer to track
	ld	a, (hl)
	ld	e, a
	inc	hl
	ld	a, (hl)
	ld	d, a
	inc	hl
	; see if pointer is null, and if so, skip it
	ld	a, e
	or	d
	jr	z, .skip_track
	; copy pointer and set track to active
	ld	a, e
	ld	(iy+NVM.pc), a
	ld	a, d
	ld	(iy+NVM.pc+1), a
	ld	a, nvm_STATUS_ACTIVE
	ld	(iy+NVM.status), a
.skip_track:
	ld	de, NVM.len
	add	iy, de
	djnz	-
	; Set the timers.
	ld	hl, TrackBuffer+TRACKINFO.ta
	ld	de, OPN_ADDR0
	ld	c, OPN_REG_TA_HI
	ld	b, 3
-:
	ld	a, c
	ld	(de), a  ; addr
	inc	de
	ld	a, (hl)
	ld	(de), a  ; data
	dec	de
	inc	hl
	inc	c
	djnz	-
	ret

; Assigns a track to an NVM channel
; de = track head pointer
nvm_set_head:
	; Install the head pointer
	ld	(iy+NVM.pc+1), d
	ld	(iy+NVM.pc), e
	; Mark channel as active
	ld	(iy+NVM.status), nvm_STATUS_ACTIVE
	ret


; ------------------------------------------------------------------------------
;
; Main Poll Function
;
; ------------------------------------------------------------------------------

nvm_poll:
	ld	b, OPN_BGM_CHANNEL_COUNT
	ld	iy, NvmOpnBgm
	call	nvm_poll_opn_sub
	ld	b, OPN_SFX_CHANNEL_COUNT
	ld	iy, NvmOpnSfx
	call	nvm_poll_opn_sub
	ret

; b = count
; iy = NVM head
nvm_poll_opn_sub:
.loop:
	push	bc
	; Skip inactive channels
	ld	a, (iy+NVM.status)
	cp	nvm_STATUS_INACTIVE
	jr	z, .next_chan
	call	nvm_exec_opn
	call	nvm_portamento
	call	nvm_update_output
.next_chan:
	ld	de, NVM.len
	add	iy, de
	pop	bc
	djnz	.loop
	ret

; ------------------------------------------------------------------------------
;
; Execution of NVM Instructions
;
; ------------------------------------------------------------------------------
nvm_exec_opn:
.exec:
	; If rest counter > 0, decrement and proceed
	ld	a, (iy+NVM.rest_cnt)
	and	a
	jr	z, +
	dec	a
	ld	(iy+NVM.rest_cnt), a
	ret
+:
	; Time for instructions
	ld	h, (iy+NVM.pc+1)
	ld	l, (iy+NVM.pc)
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
	jp	nvm_op_opn_reg  ; 16
	jp	nvm_op_stop     ; 17
	jp	nvm_op_note_off ; 18
	jp	nvm_op_slide    ; 19
	jp	nvm_op_pcmrate  ; 20

; ------------------------------------------------------------------------------


; This routine is modified based on whether it is OPN or PSG execution.
nvm_op_finished:
	ld	(iy+NVM.pc+1), h
	ld	(iy+NVM.pc), l
nvm_op_reenter:
	jr	nvm_exec_opn

; ------------------------------------------------------------------------------


nvm_op_jump:     ;  0
	; two bytes - relative pointer to jump to
	call	.set_pc_relative_offs
	jr	nvm_op_reenter

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
	jr	nvm_op_reenter

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
	jr	nvm_op_reenter

nvm_op_loopset:  ;  3
	; Get loop count
	ld	a, (hl)
	ld	(iy+NVM.loop_cnt), a
	inc	hl
	; Store address in the loop pointer field
	ld	(iy+NVM.loop_ptr+1), h
	ld	(iy+NVM.loop_ptr), l
	jp	nvm_op_finished

nvm_op_loopend:  ;  4
	ld	a, (iy+NVM.loop_cnt)
	sub	a, 1
	ld	(iy+NVM.loop_cnt), a
	jr	z, +
	; jump back to loop
	ld	a, (iy+NVM.loop_ptr+1)
	ld	(iy+NVM.pc+1), a
	ld	a, (iy+NVM.loop_ptr)
	ld	(iy+NVM.pc), a
	jr	nvm_op_reenter
+:
	jp	nvm_op_finished

nvm_op_tempo:    ;  5
	ld	ix, OPN_BASE
	ld	(ix+0), OPN_REG_TB
	ld	a, (hl)
	inc	hl
	ld	(ix+1), a
	jp	nvm_op_finished


; Sets the default rest value associated with notes.
nvm_op_length:   ;  6
	ld	a, (hl)
	ld	(iy+NVM.rest_val), a
	inc	hl
	jp	nvm_op_finished

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
	jp	nvm_op_finished

; Sets the octave register value.
nvm_op_oct:      ;  8
	ld	a, (hl)
	inc	hl
	; fall-through
nvm_op_oct_commit_a:
	ld	(iy+NVM.octave), a
	jp	nvm_op_finished

nvm_op_oct_up:   ;  9
	ld	a, (iy+NVM.octave)
	cp	7*8  ; octave already == 7?
	jp	nc, nvm_op_finished
	add	a, 8
	jr	nvm_op_oct_commit_a

nvm_op_oct_down: ; 10
	ld	a, (iy+NVM.octave)
	and	a  ; octave already at 0?
	jp	z, nvm_op_finished
	sub	a, 8
	jr	nvm_op_oct_commit_a

nvm_op_inst:     ;
	; de takes instrument ID / offset into list
	ld	d, 00h
	ld	e, (hl)
	inc	hl
	push	hl
	ld	ix, TrackBuffer
	ld	h, (ix+TRACKINFO.instrument_list_ptr+1)
	ld	l, (ix+TRACKINFO.instrument_list_ptr)
	add	hl, de  ; += instrument id offset
	; de take the patch address, also stored in the ch state
	ld	e, (hl)
	ld	(iy+NVM.patch_ptr+0), e
	inc	hl
	ld	d, (hl)
	ld	(iy+NVM.patch_ptr+1), d
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
	ld	(iy+NVM.tl_conoffs), a
	; pull TL data.
	ld	hl, OPNPATCH.tl
	add	hl, de  ; hl := source TL data
	ld	a, (hl)
	ld	(iy+NVM.tl+0), a
	inc	hl
	ld	a, (hl)
	ld	(iy+NVM.tl+1), a
	inc	hl
	ld	a, (hl)
	ld	(iy+NVM.tl+2), a
	inc	hl
	ld	a, (hl)
	ld	(iy+NVM.tl+3), a
	; write the patch to the OPN
	ld	de, 10000h-OPNPATCH.tl-3  ; why is there no 16-bit sub???
	add	hl, de  ; wind hl back to the patch start
	ld	a, (iy+NVM.channel_id)
	call	opn_set_patch
	pop	hl
	jp	nvm_op_finished

nvm_op_vol:      ; 12
	ld	a, (hl)
	ld	(iy+NVM.volume), a
	inc	hl
	jp	nvm_op_finished

nvm_op_pan:      ; 13
	ld	a, (iy+NVM.pan)
	and	a, 3Fh  ; remove pan bits
	; fall-through to commit
nvm_op_pan_commit_a:
	or	a, (hl)
	inc	hl
	ld	b, a
	ld	(iy+NVM.pan), a
	ld	a, (iy+NVM.channel_id)
	call	opn_set_base_de_sub
	add	a, OPN_REG_MOD
	ld	(de), a
	inc	de
	ld	a, b
	ld	(de), a  ; final pan data from before
	jp	nvm_op_finished

nvm_op_pms:      ; 14
	ld	a, (iy+NVM.pan)
	and	a, 0F8h  ; remove pms bits
	jr	nvm_op_pan_commit_a

nvm_op_ams:      ; 15
	ld	a, (iy+NVM.pan)
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
	jp	nvm_op_finished

nvm_op_stop:     ; 18
	ld	(iy+NVM.status), nvm_STATUS_INACTIVE
	ret

nvm_op_note_off: ; 18
	ld	a, OPN_REG_KEYON
	ld	(OPN_ADDR0), a  ; addr
	ld	a, (iy+NVM.channel_id)
	ld	(OPN_DATA0), a  ; data
	ld	(iy+NVM.now_block), 80h  ; Mark no portamento
	jp	nvm_op_finished

nvm_op_slide:    ; 19
	ld	a, (hl)
	inc	hl
	ld	(iy+NVM.portamento), a
	jp	nvm_op_finished

nvm_op_pcmrate:  ; 20
	inc	hl
	inc	hl

	jp	nvm_op_finished

; ------------------------------------------------------------------------------
;
; Notes
;
; ------------------------------------------------------------------------------

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
	ld	(iy+NVM.key_pending), a
+:

	;
	; Volume modulation
	;

tlmod macro opno
	ld	a, (iy+NVM.tl+opno)
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
	ld	a, (iy+NVM.tl_conoffs)
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

	;
	; Set target octave and frequency.
	;

	; Adopt current octave setting (really, it's the block reg value).
	ld	a, (iy+NVM.octave)
	ld	(iy+NVM.tgt_block), a
	; Look up note
	push	hl      ; we'll need this later for rest processing.
	ld	hl, .freq_tbl
	ld	a, b    ; restore note
	and	a, 1Fh  ; index into freq table
	ld	e, a    ; offset freq tbl index with de
	ld	d, 00h
	add	hl, de
	ld	a, (hl)
	ld	(iy+NVM.tgt_freq), a
	inc	hl
	ld	a, (hl)
	ld	(iy+NVM.tgt_freq+1), a

	;
	; If note was off before, skip portamento.
	;
	ld	a, (iy+NVM.now_block)
	and	a
	jp	p, +
	ld	a, (iy+NVM.tgt_block)
	ld	(iy+NVM.now_block), a
	ld	a, (iy+NVM.tgt_freq)
	ld	(iy+NVM.now_freq), a
	ld	a, (iy+NVM.tgt_freq+1)
	ld	(iy+NVM.now_freq+1), a
+:

	;
	; Optional rest duration byte
	;
	pop	hl
	ld	a, b
	and	a, nvm_NOTE_REST_FLAG
	jp	nz, nvm_op_rest
	; Else just adopt the default rest value.
	ld	a, (iy+NVM.rest_val)
	ld	(iy+NVM.rest_cnt), a
	jp	nvm_op_finished

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

portamento_read_tgt_freq_de macro
	ld	a, (iy+NVM.tgt_freq+1)
	ld	d, a
	ld	a, (iy+NVM.tgt_freq)
	ld	e, a
	endm

portamento_write_tgt_freq_de macro
	ld	a, d
	ld	(iy+NVM.tgt_freq+1), a
	ld	a, e
	ld	(iy+NVM.tgt_freq), a
	endm

portamento_read_now_freq_hl macro
	ld	a, (iy+NVM.now_freq+1)
	ld	h, a
	ld	a, (iy+NVM.now_freq)
	ld	l, a
	endm

portamento_write_now_freq_hl macro
	ld	a, h
	ld	(iy+NVM.now_freq+1), a
	ld	a, l
	ld	(iy+NVM.now_freq), a
	endm

portamento_write_now_freq_de macro
	ld	a, d
	ld	(iy+NVM.now_freq+1), a
	ld	a, e
	ld	(iy+NVM.now_freq), a
	endm

nvm_portamento:
	ld	a, (iy+NVM.portamento)
	or	a
	jr	nz, .port_change ; TODO
	; Portamento of 0 = instant
	ld	a, (iy+NVM.tgt_freq)
	ld	(iy+NVM.now_freq), a
	ld	a, (iy+NVM.tgt_freq+1)
	ld	(iy+NVM.now_freq+1), a
	ld	a, (iy+NVM.tgt_block)
	ld	(iy+NVM.now_block), a
	ret

.port_change:
	portamento_read_now_freq_hl
	; Compare target block to now
	ld	a, (iy+NVM.now_block)
	ld	b, (iy+NVM.tgt_block)
	cp	b
	jr	c, .target_block_higher
	jp	z, .target_block_same
.target_block_lower:
	; sub portamento from now freq
	ld	a, (iy+NVM.portamento)
	sub_a_from_hl
	; Is hl below OPN_NOTE_C?
	ld	de, OPN_NOTE_C
	compare_hl_r16 de
	jr	nc, .now_freq_hl_commit
	; if so, decrement now_block...
	ld	a, (iy+NVM.now_block)
	sub	08h
	and	3Fh
	ld	(iy+NVM.now_block), a
	; ...and add OPN_NOTE_C from freq.
	ld	de, OPN_NOTE_C
	add	hl, de
	jr	.now_freq_hl_commit
.target_block_higher:
	; add portamento to now freq
	ld	a, (iy+NVM.portamento)
	add_a_to_hl
	; Is hl above OPN_NOTE_C*2?
	ld	de, OPN_NOTE_C*2
	compare_hl_r16 de
	jr	c, +
	; if so, increment now_block...
	ld	a, (iy+NVM.now_block)
	add	a, 08h
	and	3Fh
	ld	(iy+NVM.now_block), a
	; ...and subtract OPN_NOTE_C from freq.
	ld	de, 10000h-OPN_NOTE_C
	add	hl, de
+:
	; Write back the freq change and exit.
.now_freq_hl_commit:
	portamento_write_now_freq_hl
	ret

.target_block_same:
	portamento_read_tgt_freq_de
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
	portamento_write_now_freq_de
	ret
.target_freq_higher:
	ld	a, (iy+NVM.portamento)
	add_a_to_hl
	; Did we surpass the target?
	compare_hl_r16 de
	jr	c, .now_freq_hl_commit  ; nope
	; Adopt target and get out.
	portamento_write_now_freq_de
	ret


; ------------------------------------------------------------------------------
;
; Key On/Off and Frequency Output
;
; ------------------------------------------------------------------------------

; iy = channel struct
; if a key is pending, handles key off/on cycle.
nvm_update_output:
	ld	a, (iy+NVM.key_pending)
	or	a
	jr	z, nvm_express_freq_sub
	ret	z
	; First key off.
	ld	a, OPN_REG_KEYON
	ld	(OPN_ADDR0), a  ; addr
	ld	a, (iy+NVM.channel_id)
	ld	(OPN_DATA0), a  ; data

	push	af
	call	nvm_express_freq_sub

	; Then key on.
	; TODO: Can we avoid a second address set here?
	ld	a, OPN_REG_KEYON
	ld	(OPN_ADDR0), a  ; addr
	pop	af  ; channel ID from before. avoid a second iy access
	or	a, 0F0h  ; all operators select.
	ld	(OPN_DATA0), a  ;
	; Clear out pending key flag.
	xor	a  ; a := 0
	ld	(iy+NVM.key_pending), a
	ret

; Writes frequency to fn registers.
nvm_express_freq_sub:
	ld	a, (iy+NVM.channel_id)
	call	opn_set_base_de_sub
	ld	c, a

	; Hi reg sel
	ld	a, c
	add	a, OPN_REG_FN_HI
	ld	(de), a
	inc	de

	; Hi reg data
	ld	a, (iy+NVM.now_freq+1)
	or	a, (iy+NVM.now_block)
	ld	(de), a
	dec	de
	opn_set_delay

	; Low reg sel
	ld	a, c
	add	a, OPN_REG_FN_LO
	ld	(de), a
	inc	de
	ld	a, (iy+NVM.now_freq)
	ld	(de), a
	ret
