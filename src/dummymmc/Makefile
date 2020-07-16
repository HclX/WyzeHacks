CROSS_COMPILE ?= $(pwd)/../.tmp/mips-gcc472-glibc216-64bit-master/bin/mips-linux-gnu-
KDIR ?= $(pwd)/../.tmp/kernel-master

MODULE_NAME := dummy_mmc

all: modules

.PHONY: modules clean

#$(MODULE_NAME)-objs := dummy_mmc.o
obj-m := $(MODULE_NAME).o

modules:
	@$(MAKE) -C $(KDIR) modules_prepare
	@$(MAKE) -C $(KDIR) M=$(shell pwd) $@

clean:
	@$(MAKE) -C $(KDIR) clean
	@rm -rf *.o *~ .depend .*.cmd  *.mod.c .tmp_versions *.ko *.symvers modules.order
	@rm -f dummy_mmc.ko
