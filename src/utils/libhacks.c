#define _GNU_SOURCE

#include <unistd.h>
#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include <dlfcn.h>
#include <sys/mount.h>
#include <sys/vfs.h>

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

int statfs(const char *path, struct statfs *buf) {
    typedef int (*PFN_statfs)(const char *path, struct statfs *buf);

    static PFN_statfs s_pfn = NULL;
    if (s_pfn == NULL) {
        s_pfn = dlsym(RTLD_NEXT, "statfs");
        if (s_pfn == NULL) {
            printf("dlsym returns NULL for 'statfs'!\n");
            return -1;
        }
    }

    printf("statfs(path=%s, buf=%p)\n", path, buf);
    int ret = s_pfn(path, buf);
    if (ret) {
        return ret;
    }

    if (strncmp(path, "/media/mmc", strlen("/media/mmc")) == 0) {
        unsigned long blocks_per_gb = 0x40000000 / buf->f_bsize;

        if (buf->f_bfree > blocks_per_gb * 2048) {
            // Limit maximum free space to 2TB
            buf->f_bfree = blocks_per_gb * 2048;
            buf->f_bavail = blocks_per_gb * 2048;
        }

        buf->f_blocks = buf->f_bfree;
        if (buf->f_blocks < blocks_per_gb * 64 ) {
            // Limit minimum total space to be 64GB
            buf->f_blocks = blocks_per_gb * 64;
        }
    }

    return ret;
}
