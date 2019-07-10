CC = $(CROSS_COMPILE)gcc
CPLUSPLUS = $(CROSS_COMPILE)g++
LD = $(CROSS_COMPILE)ld
AR = $(CROSS_COMPILE)ar cr
STRIP = $(CROSS_COMPILE)strip
CFLAGS = $(INCLUDES) -O2 -Wall -march=mips32r2 -muclibc -std=c99
LDFLAG = -muclibc -Wl,-gc-sections


all: uevent_send uevent_recv

