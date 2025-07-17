AS=asl
P2BIN=p2bin
SRC=src/nezdrv.s
BSPLIT=bsplit
MAME=mame

ASFLAGS=-i . -L -OLIST $(OUTDIR)/listing.txt

WRKDIR=wrk
OUTDIR=out

PRGNAME=nezdrv

all: $(OUTDIR)/$(PRGNAME).bin

.PHONY: $(WRKDIR)/$(PRGNAME).o
$(WRKDIR)/$(PRGNAME).o:
	mkdir -p $(@D)
	mkdir -p $(OUTDIR)
	$(AS) $(SRC) $(ASFLAGS) -o $@

.PHONY: $(OUTDIR)/$(PRGNAME).bin
$(OUTDIR)/$(PRGNAME).bin: $(WRKDIR)/$(PRGNAME).o
	mkdir -p $(@D)
	$(P2BIN) $< $@

.PHONY: clean
clean:
	@-rm -rf $(WRKDIR) $(OUTDIR)
