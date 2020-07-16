.PHONY: driver utils clean clean_all

all: driver utils

driver: | .tmp/.toolchain .tmp/.kernel
	make -C dummymmc CROSS_COMPILE=$(CURDIR)/.tmp/mips-gcc472-glibc216-64bit-master/bin/mips-linux-gnu- KDIR=$(CURDIR)/.tmp/kernel-master

utils: | .tmp/.toolchain
	make -C utils CROSS_COMPILE=$(CURDIR)/.tmp/mips-gcc472-glibc216-64bit-master/bin/mips-linux-gnu-

clean:
	make -C dummymmc clean CROSS_COMPILE=$(CURDIR)/.tmp/mips-gcc472-glibc216-64bit-master/bin/mips-linux-gnu- KDIR=$(CURDIR)/.tmp/kernel-master
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

.tmp:
	mkdir .tmp