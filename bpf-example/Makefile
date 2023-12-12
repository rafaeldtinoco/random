OUTPUT = ./output
LIBBPF = ./libbpf

CC = gcc
CLANG = clang

ARCH := $(shell uname -m)
ARCH := $(subst x86_64,amd64,$(ARCH))
GOARCH := $(ARCH)

BPFTOOL = $(shell which bpftool || /bin/false)
BTFFILE = /sys/kernel/btf/vmlinux
GIT = $(shell which git || /bin/false)
VMLINUXH = vmlinux.h

# libbpf

LIBBPF_SRC = $(abspath ./libbpf/src)
LIBBPF_OBJ = $(abspath ./$(OUTPUT)/libbpf.a)
LIBBPF_OBJDIR = $(abspath ./$(OUTPUT)/libbpf)
LIBBPF_DESTDIR = $(abspath ./$(OUTPUT))

CFLAGS = -ggdb -gdwarf -O2 -Wall -fpie -Wno-unused-variable -Wno-unused-function
LDFLAGS =

BPF_CFLAGS = "-I$(abspath $(OUTPUT))"
BPF_LDFLAGS = "-lelf -lz $(LIBBPF_OBJ)"

CGO_CFLAGS = "-I$(abspath $(OUTPUT))"
CGO_LDFLAGS = "-lelf -lz $(LIBBPF_OBJ)"
#CGO_EXTLDFLAGS = '-w -extldflags "-static"'
CGO_EXTLDFLAGS = ''

## program

.PHONY: $(PROGRAM)
.PHONY: $(PROGRAM).bpf.c

PROGRAM = example

all:
	$(MAKE) -C . $(PROGRAM)
	$(MAKE) -C . $(PROGRAM)-c

# vmlinux header file

.PHONY: vmlinuxh
vmlinuxh: $(VMLINUXH)

$(VMLINUXH): $(OUTPUT)
ifeq ($(wildcard $(BPFTOOL)),)
	@echo "ERROR: could not find bpftool"
	@exit 1
endif
	@if [ ! -f $(BTFFILE) ]; then \
		echo "ERROR: kernel does not seem to support BTF"; \
		exit 1; \
	fi
	@if [ ! -f $(VMLINUXH) ]; then \
		echo "INFO: generating $(VMLINUXH) from $(BTFFILE)"; \
		$(BPFTOOL) btf dump file $(BTFFILE) format c > $(VMLINUXH); \
	fi

# static libbpf generation for the git submodule

.PHONY: libbpf-static
libbpf-static: $(LIBBPF_OBJ)

$(LIBBPF_OBJ): $(LIBBPF_SRC) $(wildcard $(LIBBPF_SRC)/*.[ch]) | $(OUTPUT)/libbpf
	CC="$(CC)" CFLAGS="$(CFLAGS)" LD_FLAGS="$(LDFLAGS)" \
	   $(MAKE) -C $(LIBBPF_SRC) \
		BUILD_STATIC_ONLY=1 \
		OBJDIR=$(LIBBPF_OBJDIR) \
		DESTDIR=$(LIBBPF_DESTDIR) \
		INCLUDEDIR= LIBDIR= UAPIDIR= prefix= libdir= install

$(LIBBPF_SRC):
ifeq ($(wildcard $@), )
	echo "INFO: updating submodule 'libbpf'"
	$(GIT) submodule update --init --recursive
endif

# output dir

$(OUTPUT):
	mkdir -p $(OUTPUT)

$(OUTPUT)/libbpf:
	mkdir -p $(OUTPUT)/libbpf

## program bpf dependency

$(PROGRAM).bpf.o: $(PROGRAM).bpf.c | vmlinuxh
	$(CLANG) $(CFLAGS) -target bpf -I. -I$(OUTPUT) -c $< -o $@

## C example

.PHONY: $(PROGRAM).c
.PHONY: $(PROGRAM)-c

$(PROGRAM)-c: libbpf-static
	$(CLANG) $(BPF_CFLAGS) -lelf -lz -I. -I$(OUTPUT) $(PROGRAM).c -o $@ $(LIBBPF_OBJ)

## GO example

.PHONY: $(PROGRAM).go
.PHONY: $(PROGRAM)

$(PROGRAM): libbpf-static | $(PROGRAM).bpf.o
	CC=$(CLANG) \
		CGO_CFLAGS=$(CGO_CFLAGS) \
		CGO_LDFLAGS=$(CGO_LDFLAGS) \
                GOARCH=$(GOARCH) \
                go build \
                -tags netgo -ldflags $(CGO_EXTLDFLAGS) \
                -o $(PROGRAM)-static ./$(PROGRAM).go

## clean

clean:
# 	$(MAKE) -C $(LIBBPF_SRC) clean
	rm -rf $(OUTPUT)
	rm -rf $(VMLINUXH)
	rm -rf $(PROGRAM)
	rm -rf $(PROGRAM)-c
	rm -rf $(PROGRAM).bpf.o $(PROGRAM).o
