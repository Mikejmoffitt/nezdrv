; ------------------------------------------------------------------------------
;
; Assigns and plays a sound effect, muting the equivalent BGM channel.
;
; in:
;      a = cue ID
;
; ------------------------------------------------------------------------------

nvm_sfx_play_by_cue:
	ld	hl, 6502h  ; Immediate replaced as SfxTrackListPtr
	add	a, a  ; word index
	ld	d, 00h
	ld	e, a
	add	hl, de
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ex	de, hl
	; fall-through to nvm_sfx_play with track head in hl.
SfxTrackListPtr = nvm_sfx_play_by_cue+1

; ------------------------------------------------------------------------------
;
; Plays the sound effect track marked in hl.
;
; in:
;      hl = track head (first byte is the channel ID);
;
; ------------------------------------------------------------------------------
nvm_sfx_play:
	; Set up the SFX loop for the first run, where we want a channel match.
	ld	d, 00h
	ld	a, (hl)
	ld	e, a  ; desired channel ID index
	push	hl  ; will be assigned to the final channel.
	ld	hl, nvm_channel_id_tbl
	add	hl, de
	ld	a, (hl)  ; A now contains the desired channel ID itself.
	ld	c, a     ; get channel id in C.
	; Search for an active SFX channel with the same ID, and replace it.
	ld	b, SFX_CHANNEL_COUNT
	ld	iy, NvmSfx
	ld	de, NVMSFX.len
.loop_sfx:
	ld	a, (iy+NVM.status)
	and	a
	jr	z, +  ; inactive channel.
	ld	a, c
	cp	(iy+NVM.channel_id)
	jr	z, .found_channel
+:
	djnz	.loop_sfx
	; If we didn't find one, just find an open one.

	ld	b, SFX_CHANNEL_COUNT
	ld	iy, NvmSfx
	ld	de, NVMSFX.len
.loop_sfx2:
	ld	a, (iy+NVM.status)
	and	a
	jr	z, .found_channel
	cp	(iy+NVM.channel_id)
	jr	z, .found_channel
+:
	djnz	.loop_sfx2
	ret  ; no open channels; just give up at this point.

; An open SFX channel has been found - initialize it and store the channel ID.
.found_channel:
	ld	a, c
	; Assign channel ID first

	ld	(iy+NVM.channel_id), a  ; record desired channel id
	di
	call	nvm_reset_by_type_sub
	ei

	; assign channel ID and track head, and mark as active.

	; Read the marked channel enum and adopt it as the mute channel.
	pop	hl
	ld	a, (hl)
	ld	(iy+NVMSFX.mute_channel), a

	; Get the start of the head address into the channel program counter
	inc	hl
	ld	(iy+NVM.pc+1), h
	ld	(iy+NVM.pc), l
	ld	(iy+NVM.status), NVM_STATUS_ACTIVE

	; Mute the channel(s) the effect uses (always a single one, unless it is
	; the special noise case.
	jp	nvm_sfx_mute_channel  ; A still contains the channel enum.


; ------------------------------------------------------------------------------
;
; Sets channel in A to muted.
;
; in:
;       a = channel pointer offset (id * 2)
;
; Clobbers b, de, hl
;
; ------------------------------------------------------------------------------
nvm_sfx_mute_channel:
	ld	b, NVM_MUTE_MUTED
.commit:
	push	hl
	and	a
	jp	m, .noise_special
	call	nvm_channel_by_id
	ld	(ix+NVM.mute), b
	pop	hl
	ret

; Mute both PSG 2 and 3 for the special noise case.
.noise_special:
	ld	b, a
	ld	(NvmPsgBgm+NVMPSG.len*2+NVM.mute), a
	ld	(NvmPsgBgm+NVMPSG.len*3+NVM.mute), a
	pop	hl
	ret

nvm_sfx_unmute_channel:
	ld	b, NVM_MUTE_RESTORED
	jr	nvm_sfx_mute_channel.commit
