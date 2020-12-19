#define _GNU_SOURCE

#include <unistd.h>
#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include <dlfcn.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/mount.h>
#include <sys/vfs.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <sys/socket.h>
#include <linux/magic.h>
#include <linux/netlink.h>
#include "libhacks.h"


#define NLINK_MSG_LEN 1024

#define SHM_KEY         0x11223344
#define HACKDATA_MAGIC  0xDEADBEEF
#define MAX_PATH        255

typedef struct {
    uint32_t    magic;
    uint32_t    nfs_mounted;
    char        mmc_gpio_path[MAX_PATH];
} hackdata_t;

hackdata_t*     g_hackdata;
static void  __attribute__((constructor)) init()  {
    int shmid = shmget(SHM_KEY, sizeof(*g_hackdata), IPC_CREAT);
    if (shmid < 0) {
        perror("shmget failed");
        abort();
    }

    g_hackdata = (hackdata_t*)shmat(shmid, NULL, 0);
    if (g_hackdata == NULL) {
        perror("shmat failed");
        abort();
    }

    if (g_hackdata->magic != HACKDATA_MAGIC) {
        memset(g_hackdata, 0, sizeof(*g_hackdata));
        g_hackdata->magic = HACKDATA_MAGIC;
    }
}

#define DLSYM(func) \
    static PFN_##func s_pfn = NULL; \
    if (s_pfn == NULL) { \
        s_pfn = (PFN_##func)dlsym(RTLD_NEXT, #func); \
        if (s_pfn == NULL) { \
            perror("dlsym returns NULL for '" #func "'"); \
            abort(); \
        } \
    }

int mount(const char *source, const char *target,
    const char *filesystemtype, unsigned long mountflags, const void *data) {

    typedef int (*PFN_mount)(const char *, const char *, const char *, unsigned long, const void *);
    DLSYM(mount);

    printf("mount(source=%s, target=%s, filesystemtype=%s)\n", source, target, filesystemtype);
    if (strcmp(target, "/media/mmc") == 0 ||
        strcmp(target, "/media/mmcblk0p1") == 0) {
        printf("mount(%s, %s, %s) ==> 0\n", source, target, filesystemtype);
        return 0;
    } else {
        return s_pfn(source, target, filesystemtype, mountflags, data);
    }
}

int umount(const char *target) {
    typedef int (*PFN_umount)(const char*);
    DLSYM(umount);

    if (strcmp(target, "/media/mmc") == 0 ||
        strcmp(target, "/media/mmcblk0p1") == 0) {
        printf("umount(%s) ==> 0\n", target);
        return 0;
    } else {
        return s_pfn(target);
    }
}

int statfs(const char *path, struct statfs *buf) {
    typedef int (*PFN_statfs)(const char *path, struct statfs *buf);
    DLSYM(statfs);

    int ret = s_pfn(path, buf);
    if (strncmp(path, "/media/mmc", strlen("/media/mmc")) != 0) {
        return ret;
    }

    if (ret) {
        perror("statfs failed.\n");
        return ret;
    }

    printf(
        "statfs('%s'), orignal return values: "
        "f_type=%0lX, f_bsize=%lX, f_bfree=%lX, "
        "f_bavail=%lX, f_blocks=%lX\n",
        path,
        buf->f_type, buf->f_bsize, buf->f_bfree,
        buf->f_bavail, buf->f_blocks);

    if (buf->f_type == TMPFS_MAGIC) {
        printf("Not NFS share\n");
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
        "statfs('%s'), modified return values: "
        "f_type=%lX, f_bsize=%lX, f_bfree=%lX, "
        "f_bavail=%lX, f_blocks=%lX\n",
        path,
        buf->f_type, buf->f_bsize, buf->f_bfree,
        buf->f_bavail, buf->f_blocks);
    return ret;
}

int access(const char *pathname, int mode) {
    typedef int (*PFN_access)(const char*, int);
    DLSYM(access);

    if (strcmp(pathname, "/proc/jz/mmc0") == 0 || 
        strcmp(pathname, "/dev/mmcblk0p1") == 0 ||
        strcmp(pathname, "/dev/mmcblk0") == 0) {
        return g_hackdata->nfs_mounted ? 0 : ENOENT;
    } else {
        return s_pfn(pathname, mode);
    }
}

int open(char * file, int oflag) {
    typedef int (*PFN_open)(const char*, int);
    DLSYM(open);

    if (strcmp(file, g_hackdata->mmc_gpio_path) == 0) {
        // TODO: Replace hardcoded wyzehack path
        return s_pfn("/tmp/run/wyze_hack/mmc_gpio_value.txt", oflag);
    } else {
        return s_pfn(file, oflag);
    }
}

int hack_init(int mmc_gpio_num) {
    if (g_hackdata->magic != HACKDATA_MAGIC) {
        return -1;
    }

    snprintf(
        g_hackdata->mmc_gpio_path,
        sizeof(g_hackdata->mmc_gpio_path),
        "/sys/class/gpio/gpio%d/value", mmc_gpio_num);

    return 0;
}

static int uevent_send(const char* msg) {
    int fd = socket(PF_NETLINK, SOCK_RAW, NETLINK_KOBJECT_UEVENT);
    if (fd < 0) {
        perror("socket failed");
        return -1;
    }

    /* Declare for src NL sockaddr, dest NL sockaddr, nlmsghdr, iov, msghr */
    struct sockaddr_nl src_addr;
    src_addr.nl_family = AF_NETLINK;   //AF_NETLINK socket protocol
    src_addr.nl_pid = getpid();        //application unique id
    src_addr.nl_groups = 1;            //specify not a multicast communication

    //attach socket to unique id or address
    bind(fd, (struct sockaddr *)&src_addr, sizeof(src_addr));

    struct sockaddr_nl dest_addr;
    dest_addr.nl_family = AF_NETLINK; // protocol family
    dest_addr.nl_pid = 0;           //destination process id
    dest_addr.nl_groups = 1; 

    ssize_t size = sendto(fd, msg, strlen(msg) + 1, 0, (struct sockaddr*)&dest_addr, sizeof(dest_addr));
    close(fd);

    if (size != strlen(msg) + 1) {
        perror("sendto failed");
        return -1;
    }

    return 0;
}

#define MMC_INSERT_UEVENT_MSG "add@/devices/platform/jzmmc_v1.2.0/mmc_host/mmc0/mmc0:e624/block/mmcblk0/mmcblk0p1"
#define MMC_REMOVE_UEVENT_MSG "add@/devices/platform/jzmmc_v1.2.0/mmc_host/mmc0/mmc0:e624/block/mmcblk0/mmcblk0p1"

int hack_nfs_event(int nfs_mounted) {
    g_hackdata->nfs_mounted = nfs_mounted;
    uevent_send(nfs_mounted ? MMC_INSERT_UEVENT_MSG : MMC_REMOVE_UEVENT_MSG);

    return 0;
}
