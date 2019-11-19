CROSS_COMPILE ?= mips-linux-uclibc-gnu-

ifeq (${ISVP_ENV_KERNEL_DIR}, )
	ISVP_ENV_KERNEL_DIR = ../kernel
endif

KDIR := ${ISVP_ENV_KERNEL_DIR}
MODULE_NAME := dummy_mmc

all: modules

.PHONY: modules clean

#$(MODULE_NAME)-objs := dummy_mmc.o
obj-m := $(MODULE_NAME).o

modules:
	@$(MAKE) -C $(KDIR) M=$(shell pwd) $@

clean:
	@rm -rf *.o *~ .depend .*.cmd  *.mod.c .tmp_versions *.ko *.symvers modules.order
	@rm -f dummy_mmc.ko
