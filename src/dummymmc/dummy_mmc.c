/*
 * dummy_mmc.c
 *
 * Copyright (C) 2012 Ingenic Semiconductor Co., Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#include <linux/init.h>
#include <linux/module.h>
#include <linux/proc_fs.h>

struct proc_dir_entry *g_sinfo_proc;
static __init int init_sinfo(void)
{
	g_sinfo_proc = proc_mkdir("jz/mmc0", 0);
	if (!g_sinfo_proc) {
		printk("err: jz_proc_mkdir failed\n");
		return -1;
	}

	return 0;
}

static __exit void exit_sinfo(void)
{
	proc_remove(g_sinfo_proc);
//	misc_deregister(&misc_sinfo);
}

module_init(init_sinfo);
module_exit(exit_sinfo);

MODULE_DESCRIPTION("A dummy driver to create /proc/jz/mmc0 directory.");
MODULE_LICENSE("GPL");
