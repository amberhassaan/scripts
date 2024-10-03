#!/bin/bash

# specify extra flags on commandline 

CXX=/opt/rocm/bin/hipcc cmake -DCMAKE_PREFIX_PATH=/opt/rocm -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=1 -DGPU_TARGETS="gfx908" ../host $@
