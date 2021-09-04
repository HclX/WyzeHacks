#ifndef DROPBEAR_LOCAL_OPTIONS_H_
#define DROPBEAR_LOCAL_OPTIONS_H_
/* Encryption - at least one required.
 * AES128 should be enabled, some very old implementations might only
 * support 3DES.
 * Including both AES keysize variants (128 and 256) will result in 
 * a minimal size increase */
#define DROPBEAR_AES128 1
#define DROPBEAR_AES256 1
#define DROPBEAR_3DES 0
#define DROPBEAR_TWOFISH256 0
#define DROPBEAR_TWOFISH128 0

/* Hostkey/public key algorithms - at least one required, these are used
 * for hostkey as well as for verifying signatures with pubkey auth.
 * Removing either of these won't save very much space.
 * RSA is recommended
 * DSS may be necessary to connect to some systems though
   is not recommended for new keys */
#define DROPBEAR_RSA 0
#define DROPBEAR_DSS 0
/* ECDSA is significantly faster than RSA or DSS. Compiling in ECC
 * code (either ECDSA or ECDH) increases binary size - around 30kB
 * on x86-64 */
#define DROPBEAR_ECDSA 1
/* Ed25519 is faster than ECDSA. Compiling in Ed25519 code increases
   binary size - around 7,5kB on x86-64 */
#define DROPBEAR_ED25519 0

/* RSA must be >=1024 */
#define DROPBEAR_DEFAULT_RSA_SIZE 1024
/* DSS is always 1024 */
/* ECDSA defaults to largest size configured, usually 521 */
/* Ed25519 is always 256 */

/* Add runtime flag "-R" to generate hostkeys as-needed when the first 
   connection using that key type occurs.
   This avoids the need to otherwise run "dropbearkey" and avoids some problems
   with badly seeded /dev/urandom when systems first boot. */
#define DROPBEAR_DELAY_HOSTKEY 1

/* Default hostkey paths - these can be specified on the command line */
//#define DSS_PRIV_FILENAME "/system/sdcard/config/dropbear_dss_host_key"
//#define RSA_PRIV_FILENAME "/system/sdcard/config/dropbear_rsa_host_key"
#define ECDSA_PRIV_FILENAME "/configs/.ssh/host_key"
#define ED25519_PRIV_FILENAME "/configs/.ssh/host_key"

/* The default path. This will often get replaced by the shell */
#define DEFAULT_PATH "/usr/bin:/bin:/system/bin:/system/sdcard/bin/"


/* Set this if you want to use the DROPBEAR_SMALL_CODE option. This can save
 * several kB in binary size however will make the symmetrical ciphers and hashes
 * slower, perhaps by 50%. Recommended for small systems that aren't doing
 * much traffic. */
#define DROPBEAR_SMALL_CODE 1

/* Enable X11 Forwarding - server only */
#define DROPBEAR_X11FWD 0

/* Enable TCP Fowarding */
/* 'Local' is "-L" style (client listening port forwarded via server)
 * 'Remote' is "-R" style (server listening port forwarded via client) */
#define DROPBEAR_CLI_LOCALTCPFWD 0
#define DROPBEAR_CLI_REMOTETCPFWD 0

#define DROPBEAR_SVR_LOCALTCPFWD 0
#define DROPBEAR_SVR_REMOTETCPFWD 0

/* Enable Authentication Agent Forwarding */
#define DROPBEAR_SVR_AGENTFWD 0
#define DROPBEAR_CLI_AGENTFWD 0

#endif /* DROPBEAR_LOCAL_OPTIONS_H_ */