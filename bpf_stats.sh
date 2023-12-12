#!/bin/bash

# sysctl -w kernel.bpf_stats_enabled=1

bpftool prog show > /tmp/progshow.$$

checkfile() {
    prognum=$(echo $line | cut -d' ' -f1)
    progname=$(echo $line | cut -d' ' -f2)

    runtime=$(cat /tmp/progshow.$$ | grep ^$prognum | awk '{print $9}')
    amount=$(cat /tmp/progshow.$$ | grep ^$prognum | awk '{print $11}')
    if [[ $runtime -eq 0 ]]; then runtime=1; fi
    if [[ $amount -eq 0 ]]; then amount=1; fi
    average=$((runtime/amount))

    echo "PROGRAM: $progname (runtime: $runtime ns, amount: $amount times, average: $average ns)"

}

# kprobes
bpftool perf | grep kprobe | awk '{print $6" "$9}' | \
while read line; do
    checkfile
done

# traces
bpftool perf | grep trace | awk '{print $6" "$8}' | \
while read line; do
    checkfile
done

rm -f /tmp/progshow.$$
