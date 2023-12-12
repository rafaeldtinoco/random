#include <linux/syscalls.h>
#include <linux/utsname.h>

static asmlinkage long (*orig_uname)(const struct pt_regs *);
static asmlinkage long hooked_uname(const struct pt_regs *);

// Example of a kernel module hijacking a system call.

MODULE_LICENSE("GPL");

ulong table;
module_param(table, ulong, 0);

#define RO 0
#define RW 1

static void set_page(u64 addr, int flag)
{
    u32 level;
    pte_t *pte = lookup_address(addr, &level);

    if (pte && pte_present(*pte))
        pte->pte = flag ? pte->pte | _PAGE_RW : pte->pte & ~_PAGE_RW;
}

static asmlinkage long hooked_uname(const struct pt_regs *pt_regs)
{
    struct new_utsname new, *orig = (struct new_utsname *) pt_regs->di;
    long ret = orig_uname(pt_regs);

    if (copy_from_user(&new, orig, sizeof(new)))
        return -EFAULT;

    strncpy(new.release, "5.10.0-00-booooo", sizeof(new.release) - 1);
    new.release[sizeof(new.release) - 1] = '\0';

    if (copy_to_user(orig, &new, sizeof(new)))
        return -EFAULT; 

    return ret;
}

static int __init hijack_init(void)
{
    if (!table)
        return -EINVAL;

    set_page(table, RW);
    orig_uname = (void *) ((u64 **) table)[__NR_uname];
    ((u64 **) table)[__NR_uname] = (u64 *) hooked_uname;
    set_page(table, RO);

    return 0;
}

static void __exit hijack_exit(void)
{
    set_page(table, RW);
    ((u64 **) table)[__NR_uname] = (u64 *) orig_uname;
    set_page(table, RO);
}

module_init(hijack_init);
module_exit(hijack_exit);
