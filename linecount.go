package main

import (
    "bufio"
    "fmt"
    "os"
    "time"
)

func main() {
    lineChan := make(chan int)
    ticker := time.NewTicker(1 * time.Second)
    count := 0

    // Start a goroutine for reading lines
    go func() {
        scanner := bufio.NewScanner(os.Stdin)
        for scanner.Scan() {
            lineChan <- 1
        }
        if err := scanner.Err(); err != nil {
            fmt.Fprintln(os.Stderr, "Error reading standard input:", err)
            close(lineChan)
        }
    }()

    // Process lines and ticker events
    for {
        select {
        case _, ok := <-lineChan:
            if !ok {
                // If the channel is closed, exit the loop
                return
            }
            count++
        case <-ticker.C:
            fmt.Printf("%d lines/sec\n", count)
            count = 0
        }
    }
}
