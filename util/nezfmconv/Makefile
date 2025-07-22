APPNAME := nezfmconv

CC := cc
CFLAGS := -O3 -std=gnu23
INSTALL_PREFIX := /usr/bin
ifdef SYSTEMROOT
	APPEXT := .exe
endif

EXECNAME := $(APPNAME)$(APPEXT)

.PHONY: clean

all: $(EXECNAME)

$(EXECNAME): $(APPNAME).c
	$(CC) $< $(CFLAGS) -o $@

install: $(EXECNAME)
	install $< $(INSTALL_PREFIX)/

clean:
	rm -f $(EXECNAME)
