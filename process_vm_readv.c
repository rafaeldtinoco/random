#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/uio.h>

// NOTE: compile with "gcc -D_GNU_SOURCE"

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
    int output_fd = open("stack.dump", O_WRONLY | O_CREAT | O_TRUNC, 0666);
    if (output_fd < 0) {
        perror("open");
        return -1;
    }

    char buffer[BUFFER_SIZE];
    struct iovec local[1];
    struct iovec remote[1];

    local[0].iov_base = buffer;
    remote[0].iov_base = (void *)start;
    size_t remaining = end - start;

    while (remaining > 0) {
        local[0].iov_len = remote[0].iov_len = (remaining > BUFFER_SIZE) ? BUFFER_SIZE : remaining;
        ssize_t nread = process_vm_readv(pid, local, 1, remote, 1, 0);

        if (nread <= 0) {
            perror("process_vm_readv");
            close(output_fd);
            return -1;
        }

        write(output_fd, buffer, nread);
        remote[0].iov_base += nread;
        remaining -= nread;
    }

    close(output_fd);
    return 0;
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

    if (read_stack(pid, stack_start, stack_end) != 0) {
        fprintf(stderr, "Failed to read stack for PID %d\n", pid);
        return EXIT_FAILURE;
    }

    printf("Stack dump completed for PID %d\n", pid);
    return EXIT_SUCCESS;
}

