#!/bin/bash

num_gpus=$(rocm-smi -i | grep 'GPU' | wc -l)

for i in `seq 1 $num_gpus`; do 
  g=$((i-1))
  echo "Resetting GPU $g"
  sudo rocm-smi --gpureset -d $g
  echo "Done resetting GPU $g"
done
