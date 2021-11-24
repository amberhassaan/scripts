#!/bin/bash
# Usage: debug_rank.sh <rank to debug> <executable> <arguments>

DEBUG_RANK=$1
shift;
echo "MPI RANK == $OMPI_COMM_WORLD_RANK"
if [ $OMPI_COMM_WORLD_RANK -eq $DEBUG_RANK ] ; then
  exec gdb -ex=run --args $*
else
  exec $*
fi
# The -ex=run tells GDB to automatically execute the run command after loading
# the executable. You may omit it if you need to set breakpoints first. Use the
# wrapper like this, for example to debug rank 3:
# 
# $ mpiexec ... --stdin 3 ./debug_rank.sh 3 batSRTest shortpass.bat
