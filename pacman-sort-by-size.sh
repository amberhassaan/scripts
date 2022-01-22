#!/bin/bash
pacman -Qi | egrep '^Name|^Installed Size' | xargs -d '\n' -n 2 | grep 'MiB' | awk '{ print $3, " ", $7, " ", $8 }' | sort -k 2 -n

