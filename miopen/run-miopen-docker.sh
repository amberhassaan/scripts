#!/bin/bash
version=$1
wd=$HOME
docker run -w $wd -v $wd:$wd -it --privileged --device=/dev/kfd --device=/dev/dri rocm/miopen:$version
