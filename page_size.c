#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define KERNEL_VERSION(a, b, c) (((a) << 16) + ((b) << 8) + (c))

#define __AC(X,Y)   (X##Y)
#define _AC(X,Y)    __AC(X,Y)

#define TEMP(X)     (X##1L)

#define PAGE_SHIFT 12
#define PAGE_SIZE  (_AC(1,UL) << PAGE_SHIFT)
#define PAGE_MASK  (~(PAGE_SIZE-1))

int main(int argc, char **argv) {

	printf("%lu\n", 1UL << 12);

}
