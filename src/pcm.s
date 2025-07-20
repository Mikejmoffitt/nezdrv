;
; pcm_poll is at 8 so it may be called by `rst pcm_poll`.
;

; trashes a, flags
pcm_service macro
	ld	a, (OPN_BASE)
	rrca  ; Timer A status bit goes into carry
	rst	pcm_poll
	endm

pcm_poll_disable macro
	ld	a, 0C9h  ; ret
	ld	(pcm_poll), a
	endm

pcm_poll_enable macro
	ld	a, 0D0h  ; ret NC
	ld	(pcm_poll), a
	endm

; The technique here is cribbed from Echo. Thanks
	align	08h
pcm_poll:
	; set to C9h for ret if PCM is not playing and D0h for ret NC when in use.
	ret

	di
	exx
	ex	af, af'

	; Ack timer
	ld	hl, OPN_ADDR0
	ld	(hl), OPN_REG_TCTRL
	inc	hl
	ld	(hl), OPN_TA_ACK
	dec	hl

	; Read sample
	ld	de, (PcmAddr)
	ld	a, (de)
	inc	a
	jr	z, .finished  ; if end marker, bail out and kill pcm
	ld	(hl), OPN_REG_DACDAT
	inc	hl
	ld	(hl), a
	inc	de
	ld	(PcmAddr), de
.done:
	exx
	ex	af, af'
	ei

	ret

.finished:
	pcm_poll_disable
	jr	pcm_poll.done
