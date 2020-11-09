#define _GNU_SOURCE

#include <unistd.h>
#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include <dlfcn.h>
#include <sys/mount.h>
#include <sys/vfs.h>
#include <linux/magic.h>

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

int umount(const char *target) {
        printf("umount called for %s. Ignore.\n", target);
        return 0;
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
    if (strncmp(path, "/media/mmc", strlen("/media/mmc")) != 0) {
        return ret;
    }

    if (ret) {
        perror("statfs failed.\n");
        return ret;
    }

    printf(
        "statfs('/media/mmc'), orignal return values: "
        "f_type=%0lX, f_bsize=%lX, f_bfree=%lX, "
        "f_bavail=%lX, f_blocks=%lX\n",
        buf->f_type, buf->f_bsize, buf->f_bfree,
        buf->f_bavail, buf->f_blocks);

    if (buf->f_type == TMPFS_MAGIC) {
        printf("NFS share not mounted\n");
        return ret;
    }

    unsigned long blocks_per_gb = 0x40000000 / buf->f_bsize;
    if (buf->f_bavail > blocks_per_gb * 16) {
        // If there are more than 16GB free space, we will emulate an
        // empty SD card whose total space equals to the free space up
        // to 128GB
        if (buf->f_bavail > blocks_per_gb * 128) {
            // Limit free space to 128GB
            buf->f_bavail = blocks_per_gb * 128;
        }
        buf->f_blocks = buf->f_bfree = buf->f_bavail;
    } else {
        // If there are less than 16GB free space, we will emulate an 
        // SD card of 16GB, with free space to whatever left.
        buf->f_blocks = blocks_per_gb * 16;
        buf->f_bfree = buf->f_bavail;
    }

    printf(
        "statfs('/media/mmc'), modified return values: "
        "f_type=%lX, f_bsize=%lX, f_bfree=%lX, "
        "f_bavail=%lX, f_blocks=%lX\n",
        buf->f_type, buf->f_bsize, buf->f_bfree,
        buf->f_bavail, buf->f_blocks);
    return ret;
}
