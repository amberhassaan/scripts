#!/bin/bash

# sums and sorts the total amount of memory taken by user processes as reported by 'ps'
# Also sums memory usage of multiple instances of same process
# Useful to find the processes with most memory usage


RSS=6
NAME=11
ps aux | awk "{ sum += \$$RSS; print\$$RSS,\$$NAME} END { print sum, \"Total_user_space_in_use\" }" | sort -k 2 \
  | awk 'BEGIN {prev="";} { array[$2] += $1; if (prev != "" && prev != $2) { print array[prev], prev; } prev = $2; }' \
  | sort -k 1 -nr  | awk '($1 > 1000) { if (NR==1) { tot=$1; }; printf "%2.3f MB, %2.3f%%, %s\n", ($1/1024), 100*$1/tot, $2; }'
