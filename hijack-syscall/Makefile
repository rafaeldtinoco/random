obj-m += hijack.o

PWD := $(shell pwd)

KBUILD_CFLAGS += -g -Wall
KERNELDIR ?= /lib/modules/$(shell uname -r)/build

default:
	@$(MAKE) -C $(KERNELDIR) M=$(PWD) modules

clean:
	@rm -f *.o *.symvers *.ko *.mod.c .*.cmd *.mod *.order
