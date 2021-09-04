#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "libhacks.h"

int main(int argc, char* argv[]) {
    if (argc < 2) {
        printf("hackutils init|mmc_insert|mmc_remove [args]\n");
        return -1;
    }

    if (strcmp(argv[1], "init") == 0) {
        return hack_init();
    } else if (strcmp(argv[1], "mmc_insert") == 0) {
        return hack_nfs_event(1);
    } else if (strcmp(argv[1], "mmc_remove") == 0) {
        return hack_nfs_event(0);
    } else {
        return -1;
    }
}
