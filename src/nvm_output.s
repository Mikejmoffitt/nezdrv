
; ------------------------------------------------------------------------------
;
; Key On/Off and Frequency Output
;
; ------------------------------------------------------------------------------

nvm_enable_noise_ctrl macro
	ld	a, 0E0h
	ld	(NoiseModeCheck), a
	endm

nvm_disable_noise_ctrl macro
	xor	a
	ld	(NoiseModeCheck), a
	endm

nvm_update_output:
	ld	a, (iy+NVM.channel_id)
	and	a
	jp	p, nvmopn_update_output

nvmpsg_update_output:
	call	nvmpsg_env_sub

	ld	c, a
	ld	a, (iy+NVM.mute)
	and	a
	ret	m  ; return if muted (NVM_MUTE_MUTED)
	ld	a, c

	xor	0Fh  ; convert volume to attenuation.
	add	a, (iy+NVM.volume)
	cp	10h
	jr	c, +
	ld	a, 0Fh
+:
	or	a, (iy+NVM.channel_id)  ; register
	or	a, 10h  ; volume command.
	ld	(PSG), a
	; Convert frequency data to register data
	ld	a, (iy+NVM.channel_id)
.noisecheck_cp:
	cp	a, 0FFh  ; Set to 0E0h for noise pitch to control CH3, or 0FFh to not.
	jr	nz, +
	ld	a, 0C0h  ; CH3 address base
+:
	ld	(.chid_orval+1), a

;	or	a, (iy+NVM.channel_id)  ; register
	ld	h, (iy+NVMPSG.now_period+1)
	ld	l, (iy+NVMPSG.now_period+0)
	; period cmd and low data
	ld	a, l
	and	0Fh
.chid_orval:
	or	00h  ; To be replaced with the channel ID above
	ld	b, a  ; save for writing a little later
	; high data
	ld	a, l
	rept	4
	srl	h
	rra
	endm
	ld	l, a
	and	3Fh
	; The writes are spaced this way to prevent strange sounds
	ld	hl, PSG
	ld	(hl), b  ; cmd and low data
	ld	(hl), a  ; high data
	ret

NoiseModeCheck = nvmpsg_update_output.noisecheck_cp+1

; returns in A the attenuation value to set.
nvmpsg_env_sub:
	; Step envelope.
	ld	d, (iy+NVMPSG.env_ptr+1)
	ld	e, (iy+NVMPSG.env_ptr)
.env_interpret:
	ld	a, (de)
	and	a
	jp	p, .env_value
	; Envelope instructions.
	inc	a
	jp	p, .env_op_end
	inc	a
	jp	p, .env_op_lpset
	inc	a
	jp	p, .env_op_lpend
.env_op_end:
	; just scoot back and reinterpret
	dec	de
	jr	.env_interpret
.env_op_lpset:
	inc	de
	ld	(iy+NVMPSG.env_loop_ptr+1), d
	ld	(iy+NVMPSG.env_loop_ptr), e
	jr	.env_interpret
.env_op_lpend:
	; If key is not down, let the macro continue.
	ld	a, (iy+NVMPSG.key_on)
	and	a
	jr	nz, +
	inc	de  ; step past lpend.
	jr	.env_interpret
+:
	ld	d, (iy+NVMPSG.env_loop_ptr+1)
	ld	e, (iy+NVMPSG.env_loop_ptr)
	ld	(iy+NVMPSG.env_ptr+1), d
	ld	(iy+NVMPSG.env_ptr), e
	jr	.env_interpret

.env_value:
	; we will just return A.
.env_step_ptr:
	inc	de
	ld	(iy+NVMPSG.env_ptr+1), d
	ld	(iy+NVMPSG.env_ptr), e
	ret



; iy = channel struct
; if a key is pending, handles key off/on cycle.
nvmopn_update_output:
	ld	a, (iy+NVM.mute)
	and	a
	ret	m  ; return if muted (NVM_MUTE_MUTED)
	ld	a, (iy+NVMOPN.key_pending)
	and	a
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


