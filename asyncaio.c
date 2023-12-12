#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <aio.h>
#include <errno.h>
#include <sys/types.h>

#define BUFFER_SIZE 1024

int find_stack_address(pid_t pid, unsigned long *start, unsigned long *end) {
    char maps_path[256];
    FILE *maps;
    char line[BUFFER_SIZE];

    sprintf(maps_path, "/proc/%d/maps", pid);
    maps = fopen(maps_path, "r");
    if (maps == NULL) {
        perror("fopen");
        return -1;
    }

    while (fgets(line, sizeof(line), maps)) {
        if (strstr(line, "[stack]")) {
            sscanf(line, "%lx-%lx", start, end);
            fclose(maps);
            return 0;
        }
    }

    fclose(maps);
    return -1;
}

int read_stack(pid_t pid, unsigned long start, unsigned long end) {
    char mem_path[256];
    int mem_fd, dump_fd;
    struct aiocb aiocb;
    char buffer[BUFFER_SIZE];
    int status = 0;

    sprintf(mem_path, "/proc/%d/mem", pid);
    mem_fd = open(mem_path, O_RDONLY);
    if (mem_fd == -1) {
        perror("open mem");
        return -1;
    }

    dump_fd = open("stack.dump", O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (dump_fd == -1) {
        perror("open dump");
        close(mem_fd);
        return -1;
    }

    memset(&aiocb, 0, sizeof(struct aiocb));
    aiocb.aio_fildes = mem_fd;
    aiocb.aio_buf = buffer;
    aiocb.aio_nbytes = BUFFER_SIZE;
    aiocb.aio_offset = start;

    while (aiocb.aio_offset < end) {
        if (aio_read(&aiocb) == -1) {
            perror("aio_read");
            status = -1;
            break;
        }

        while (aio_error(&aiocb) == EINPROGRESS) {
            continue;
        }

        int numBytes = aio_return(&aiocb);
        if (numBytes == -1) {
            perror("aio_return");
            status = -1;
            break;
        }

        write(dump_fd, buffer, numBytes);

        aiocb.aio_offset += numBytes;
    }

    close(mem_fd);
    close(dump_fd);

    return status;
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <pid>\n", argv[0]);
        return EXIT_FAILURE;
    }

    pid_t pid = atoi(argv[1]);
    unsigned long stack_start, stack_end;

    if (find_stack_address(pid, &stack_start, &stack_end) != 0) {
        fprintf(stderr, "Failed to find stack address for PID %d\n", pid);
        return EXIT_FAILURE;
    }

    printf("Stack start: %lx, end: %lx\n", stack_start, stack_end);

    if (read_stack(pid, stack_start, stack_end) != 0) {
        fprintf(stderr, "Failed to read stack for PID %d\n", pid);
        return EXIT_FAILURE;
    }

    printf("Stack dump completed for PID %d\n", pid);
    return EXIT_SUCCESS;
}

