CC = $(CROSS_COMPILE)gcc
CPLUSPLUS = $(CROSS_COMPILE)g++
LD = $(CROSS_COMPILE)ld
AR = $(CROSS_COMPILE)ar cr
STRIP = $(CROSS_COMPILE)strip
CFLAGS = $(INCLUDES) -O2 -Wall -march=mips32r2 -muclibc -std=c99
LDFLAG = -muclibc -Wl,-gc-sections


all: libhacks.so hackutils

clean:
	@rm -rf *.o libhacks.so hackutils

libhacks.so: libhacks.c
	$(CC) $(CFLAGS) --shared -fPIC -ldl $^ -o $@

hackutils: hackutils.c
	$(CC) $(CFLAGS) -L. -Wl,-rpath='$$ORIGIN' -lhacks $^ -o $@