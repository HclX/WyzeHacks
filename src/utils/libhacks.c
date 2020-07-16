#define _GNU_SOURCE

#include <unistd.h>
#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include <dlfcn.h>
#include <sys/mount.h>

int mount(const char *source, const char *target,
    const char *filesystemtype, unsigned long mountflags, const void *data) {
    
    typedef int (*PFN_mount)(const char *source, const char *target,
        const char *filesystemtype, unsigned long mountflags, const void *data);

    static PFN_mount s_pfn = NULL;
    if (s_pfn == NULL) {
        s_pfn = dlsym(RTLD_NEXT, "mount");
        if (s_pfn == NULL) {
            printf("dlsym returns NULL for 'mount'!\n");
            return -1;
        }
    }

    printf("mount(source=%s, target=%s, filesystemtype=%s)\n", source, target, filesystemtype);
    if (strcmp(target, "/media/mmc") == 0) {
        printf("/media/mmc mount detected, returning success\n");
        return 0;
    } else {
        return s_pfn(source, target, filesystemtype, mountflags, data);
    }
}
