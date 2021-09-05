.PHONY: driver utils busybox dropbear clean clean_all

INSTALLDIR ?= .
INSTALLDIR := $(abspath $(INSTALLDIR))

all: utils busybox dropbear

utils busybox dropbear: | .tmp/.toolchain $(INSTALLDIR)/bin
	cd $@ && INSTALLDIR=$(INSTALLDIR) ./build.sh

clean:
	rm -rf .tmp

.tmp/.toolchain: .tmp/toolchain.zip
	unzip -q $< -d .tmp
	touch $@

.tmp/toolchain.zip: | .tmp
	wget -O $@ https://github.com/Dafang-Hacks/mips-gcc472-glibc216-64bit/archive/master.zip

.tmp $(INSTALLDIR)/bin:
	mkdir $@
