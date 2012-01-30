#!/bin/bash

# sums the amount of memory taken by multiple instances of a process
# e.g. run footprint.sh 'chrom*'
# pattern provided as command line parameter
# matching of pattern is case insensitive


MEM_PCNT=4
RSS=6
NAME=11

echo -n "$1, "

ps aux | awk "{ print \$$MEM_PCNT, \$$RSS, \$$NAME; }" | grep -i "$1" | \
  awk '{ mem+=$1; rss+=$2; } END{ printf "memory usage=%2.3f%%, rss=%2.3f MB\n", mem, (rss/1024)}'
