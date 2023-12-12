// +build ignore

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <pthread.h>

#include <glib.h>
#include <glib/gprintf.h>

#define chunk_size 1024

GAsyncQueue *queue;

void *readstdin(void *ptr) {
  // int multi = 1000;
  gchar *entry;

  for (;;) {
    entry = g_malloc0(chunk_size);
    read(fileno(stdin), entry, chunk_size);
    g_async_queue_push(queue, entry);

    // if ((multi % 1000) == 0) {
    // 	fprintf(stderr, "buffer size: %d\n", g_async_queue_length(queue));
    // 	fflush(stderr);
    // }
    // multi++;
  }
}

void *writestdout(void *ptr) {
  gchar *entry;

  for (;;) {
    entry = g_async_queue_pop(queue);
    g_printf("%s", (gchar *)entry);
    fflush(stdout);
    g_free(entry);
  }
}

int main(int arc, char **argv) {
  pthread_t read_t, write_t;
  int ret = 0;

  queue = g_async_queue_new();

  ret |= pthread_create(&read_t, NULL, readstdin, NULL);
  ret |= pthread_create(&write_t, NULL, writestdout, NULL);

  if (ret != 0) {
    fprintf(stdout, "error creating threads\n");
    exit(1);
  }

  pthread_join(read_t, NULL);
  pthread_join(write_t, NULL);

  return 0;
}
