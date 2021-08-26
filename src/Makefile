.PHONY: driver utils busybox dropbear clean clean_all

INSTALLDIR ?= .
INSTALLDIR := $(abspath $(INSTALLDIR))

all: utils busybox dropbear

driver: | .tmp/.toolchain .tmp/.kernel $(INSTALLDIR)/bin
	make -C dummymmc CROSS_COMPILE=$(CURDIR)/.tmp/mips-gcc472-glibc216-64bit-master/bin/mips-linux-gnu- KDIR=$(CURDIR)/.tmp/kernel-master

utils: | .tmp/.toolchain $(INSTALLDIR)/bin
	make -C utils CROSS_COMPILE=$(CURDIR)/.tmp/mips-gcc472-glibc216-64bit-master/bin/mips-linux-gnu-

busybox dropbear: | .tmp/.toolchain $(INSTALLDIR)/bin
	cd $@ && \
		CROSS_COMPILE=$(CURDIR)/.tmp/mips-gcc472-glibc216-64bit-master/bin/mips-linux-gnu- \
		INSTALLDIR=$(INSTALLDIR) \
		./build.sh 

clean:
#	make -C dummymmc clean CROSS_COMPILE=$(CURDIR)/.tmp/mips-gcc472-glibc216-64bit-master/bin/mips-linux-gnu- KDIR=$(CURDIR)/.tmp/kernel-master
	make -C utils clean CROSS_COMPILE=$(CURDIR)/.tmp/mips-gcc472-glibc216-64bit-master/bin/mips-linux-gnu-

clean_all: |clean
	rm -rf .tmp

.tmp/.kernel: .tmp/kernel.zip
	unzip -q $< -d .tmp
	touch $@

.tmp/.toolchain: .tmp/toolchain.zip
	unzip -q $< -d .tmp
	touch $@

.tmp/kernel.zip: | .tmp
	wget -O $@ https://github.com/Dafang-Hacks/kernel/archive/master.zip

.tmp/toolchain.zip: | .tmp
	wget -O $@ https://github.com/Dafang-Hacks/mips-gcc472-glibc216-64bit/archive/master.zip

.tmp $(INSTALLDIR)/bin:
	mkdir $@