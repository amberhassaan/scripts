#!/bin/bash


CXX=/opt/rocm/llvm/bin/clang++ cmake -DCMAKE_PREFIX_PATH=/opt/rocm -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=1 ..
