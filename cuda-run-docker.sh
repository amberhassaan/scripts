#!/bin/bash
version="12.3.1-devel-ubuntu22.04"
wd=$HOME
docker run -w $wd -v $wd:$wd -it --privileged --device=/dev/dri/card0 nvidia/cuda:$version
