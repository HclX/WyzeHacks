#include "uevent.h"

int main() {
  int fd = socket(PF_NETLINK, SOCK_RAW, NETLINK_KOBJECT_UEVENT);
  printf("Inside recv main\n");

  if (fd < 0) {
    printf("Socket creation failed. try again\n");
    return -1;
  }

  struct sockaddr_nl src_addr;
  src_addr.nl_family = AF_NETLINK;  //AF_NETLINK socket protocol
  src_addr.nl_pid = getpid();       //application unique id
  src_addr.nl_groups = 1;           //specify not a multicast communication

  //attach socket to unique id or address
  bind(fd, (struct sockaddr *)&src_addr, sizeof(src_addr));

  /* Listen forever in a while loop */
  char msg[0x800];
  while (1) {
    //receive the message
    memset(msg, 0, sizeof(msg));
    int size = recv(fd, msg, sizeof(msg), 0);
    if (size > 0) {
      msg[size] = '\0';
      printf("Recevied: %s\n", msg);
    }
    else {
      printf("recv failed\n");
    }
  }
  close(fd); // close the socket
}
