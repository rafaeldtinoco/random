.PHONY: all
all:
	$(MAKE) pipebuf
	$(MAKE) pipebufc

CC := clang

INCLUDES := -I.

CFLAGS += -Wall -O2 -g -ggdb
CFLAGS += `pkg-config --cflags glib-2.0`
LDFLAGS += `pkg-config --libs glib-2.0`
LDFLAGS += -lpthread

pipebuf: pipebuf.go
	go build -o pipebuf .

pipebufc: pipebuf.c
	$(CC) $(INCLUDES) $(CFLAGS) $(LDFLAGS) $< -o $@

.PHONY: clean
clean:
	rm -f pipebuf
