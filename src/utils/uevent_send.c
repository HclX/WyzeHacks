#include "uevent.h"

int main(int argc, const char* argv[]) {
  if (argc <= 1) {
    printf("What to send?\n");
    return -1;
  }

  int fd = socket(PF_NETLINK, SOCK_RAW, NETLINK_KOBJECT_UEVENT);
  if (fd < 0) {
    printf("Socket creation failed. try again\n");
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

#if 0
  const char* msgs[] = {
    "add@/devices/platform/jzmmc_v1.2.0/mmc_host/mmc0/mmc0:e624",
    "add@/devices/platform/jzmmc_v1.2.0/mmc_host/mmc0/mmc0:e624/block/mmcblk0",
    "add@/devices/platform/jzmmc_v1.2.0/mmc_host/mmc0/mmc0:e624/block/mmcblk0/mmcblk0p1",
  };

Recevied: remove@/devices/platform/jzmmc_v1.2.0/mmc_host/mmc0/mmc0:e624/block/mmcblk0/mmcblk0p1
Recevied: remove@/devices/virtual/bdi/179:0
Recevied: remove@/devices/platform/jzmmc_v1.2.0/mmc_host/mmc0/mmc0:e624/block/mmcblk0
Recevied: remove@/devices/platform/jzmmc_v1.2.0/mmc_host/mmc0/mmc0:e624  
#endif

  for (int i = 1; i < argc; i ++)
  {
    const char* msg = argv[i];
    printf("Sending: %s\n", msg);
    ssize_t size = sendto(fd, msg, strlen(msg) + 1, 0, (struct sockaddr*)&dest_addr, sizeof(dest_addr));
    printf("Result: %d\n", size);
  }

  close(fd); // close the socket
  return 0;
}
