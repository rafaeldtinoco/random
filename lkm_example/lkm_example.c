#include <linux/debugfs.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Robert W. Oliver II");
MODULE_DESCRIPTION("A simple example Linux module.");
MODULE_VERSION("0.01");

extern struct dentry *usb_debug_root;

static ssize_t lkm_example_read(struct file *, char __user *, size_t, loff_t *);

struct dentry *ptr;

const struct file_operations lkm_example_fops = {
    .read = lkm_example_read,
};

static int __init lkm_example_init(void) {
  ptr = debugfs_create_file("testing123", 0600, usb_debug_root, NULL,
                            &lkm_example_fops);

  return 0;
}

static void __exit lkm_example_exit(void) { debugfs_remove(ptr); }

static ssize_t lkm_example_read(struct file *file, char __user *buf,
                                size_t nbytes, loff_t *ppos) {
  return 0;
}

module_init(lkm_example_init);
module_exit(lkm_example_exit);
