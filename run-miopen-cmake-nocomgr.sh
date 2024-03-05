#!/bin/bash

# specify extra flags on commandline 

CXX=/opt/rocm/llvm/bin/clang++ cmake -DMIOPEN_TEST_ALL=1 -DCMAKE_PREFIX_PATH=/opt/rocm -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=1 -DMIOPEN_USE_COMGR=Off .. $@
