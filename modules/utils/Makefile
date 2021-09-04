CC = $(CROSS_COMPILE)gcc
CPLUSPLUS = $(CROSS_COMPILE)g++
LD = $(CROSS_COMPILE)ld
AR = $(CROSS_COMPILE)ar cr
STRIP = $(CROSS_COMPILE)strip
CFLAGS = $(INCLUDES) -O2 -Wall -march=mips32r2 -muclibc -std=c99
LDFLAG = -muclibc -Wl,-gc-sections

INSTALLDIR ?= .
INSTALLDIR := $(INSTALLDIR)/bin

all: $(INSTALLDIR)/libhacks.so $(INSTALLDIR)/hackutils

clean:
	@rm -rf *.o $(INSTALLDIR)/libhacks.so $(INSTALLDIR)/hackutils

$(INSTALLDIR)/libhacks.so: libhacks.c
	$(CC) $(CFLAGS) --shared -fPIC -ldl $^ -o $@

$(INSTALLDIR)/hackutils: hackutils.c
	$(CC) $(CFLAGS) -L$(INSTALLDIR) -Wl,-rpath='$$ORIGIN' -lhacks $^ -o $@