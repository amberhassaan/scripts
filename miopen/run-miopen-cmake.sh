#!/bin/bash

# specify extra flags on commandline 

CXX=/opt/rocm/llvm/bin/clang++ CXXFLAGS='-Werror' cmake -DBUILD_DEV=1 -DMIOPEN_TEST_ALL=1 -DCMAKE_PREFIX_PATH=/opt/rocm -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=1 .. $@
