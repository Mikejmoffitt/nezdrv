;
; pcm_poll is at 8 so it may be called by `rst pcm_poll`.
;

; trashes a, flags
pcm_service macro
	rst	pcm_poll
	endm

pcm_poll_disable macro
	ld	a, 0C9h  ; ret
	ld	(pcm_poll), a
	endm

pcm_poll_enable macro
	ld	a, 3Ah  ; ld a, (NN)
	ld	(pcm_poll), a
	endm

; The technique here is cribbed from Echo. Thanks
	align	08h
pcm_poll:
	ld	a, (OPN_BASE)
	rrca  ; Timer A status bit goes into carry
	ret nc

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
.pcmaddr_load:
	ld	de, 6502h  ; immediate replaced as PcmAddr
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

PcmAddr = .pcmaddr_load+1
