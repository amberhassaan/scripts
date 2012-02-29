#!/bin/bash

# sums and sorts the total amount of memory taken by user processes as reported by 'ps'
# Also sums memory usage of multiple instances of same process
# Useful to find the processes with most memory usage
# a cutoff limit can be provided at the command line
# e.g. userMem.sh 0.5


CUTOFF=${1:-"0.5"}

RSS=6
NAME=11
ps aux | awk "{ sum += \$$RSS; print\$$RSS,\$$NAME} END { print sum, \"Total_user_space_in_use\" }" | sort -k 2 \
  | awk 'BEGIN {prev="";} { array[$2] += $1; if (prev != "" && prev != $2) { print array[prev], prev; } prev = $2; }' \
  | sort -k 1 -nr  | awk \
  "BEGIN { \
    cutoff=$CUTOFF; \
    printf \"INFO: Showing user space processes using >= %0.1f%% of RAM\\n\", cutoff; \
  } \
  { \
    if (NR==1) { tot=\$1; }; \
    pct=100*\$1/tot; sum += pct; \
    if (pct >= cutoff) { \
      printf \"%-60s, %4.3f MB, %2.3f%%, running_sum=%2.3f%%\\n\", \$2, (\$1/1024), pct, (sum-100); \
    } \
  }"
