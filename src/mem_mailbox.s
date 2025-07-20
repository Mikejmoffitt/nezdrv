
	org NEZ_MAILBOX_ADDR
MailBoxMemStart:
MailBoxSfxQueue:       ds SFX_CHANNEL_COUNT
	align	10h
MailBoxCommand:        ds 0Dh
MailBoxReadySig:       ds 03h
MailBoxMemEnd:
