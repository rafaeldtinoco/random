package main

/*
#cgo CFLAGS: -I/usr/include/glib-2.0 -I/usr/lib/x86_64-linux-gnu/glib-2.0/include
#cgo LDFLAGS: -lglib-2.0

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <malloc.h>

#include <glib.h>
#include <glib/gasyncqueue.h>

GAsyncQueue *queue;

struct entries {
	int size;
	char *buffer;
};

int get_size(struct entries *entry) {
	return entry->size;
}

char *get_buffer(struct entries *entry) {
	return entry->buffer;
}

void init(void) {
	queue = g_async_queue_new();
}

void enqueue(void *buffer, int size) {
	struct entries *entry = calloc(sizeof(struct entries), 1);
	entry->size = size;
	entry->buffer = calloc(size, 1);
	memcpy(entry->buffer, buffer, size);
	g_async_queue_push(queue, entry);
}

struct entries *dequeue() {
	struct entries *entry = g_async_queue_pop(queue);
	return entry;
}

void release(struct entries *entry) {
	free(entry->buffer);
	free(entry);
}
*/
import "C"

import (
	"sync"
	"os"
	"io"
	"runtime"
	"log"
	"unsafe"
)

func errExit(why error) {
    _, fn, line, _ := runtime.Caller(1)
    log.Printf("error: %s:%d %v\n", fn, line, why)
    os.Exit(1)
}

func main() {
	var wg sync.WaitGroup

	C.init()

	wg.Add(1)
	go func() {
		defer wg.Done()

		bytes := make([]byte, 1024*1024)

		for {
			bytes := bytes[:cap(bytes)]
			n, e := os.Stdin.Read(bytes)
			if e != nil {
				if e == io.EOF {
					break
				}
				errExit(e)
			}
			bytes = bytes[:n]
			C.enqueue(unsafe.Pointer(&bytes[0]), C.int(n))
		}
	}()

	wg.Add(1)
	go func() {
		defer wg.Done()

		for {
			entry := C.dequeue()
			size := C.int(entry.size)
			buffer := unsafe.Pointer(entry.buffer)
			bytes := C.GoBytes(unsafe.Pointer(buffer), C.int(size))
			os.Stdout.Write(bytes)
			bytes = nil
			C.release(entry)
		}
	}()

	wg.Wait()
}
