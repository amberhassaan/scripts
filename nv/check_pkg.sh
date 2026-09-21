#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

source $HOME/scripts/conda-init.sh

if ! which conda ; then
  echo "conda command not found"
  exit -1
fi

PKG_VER="25.01.00"

ENV_NAME="test_pkg"
conda create -n $ENV_NAME
# eval $(conda shell.bash hook)
conda activate $ENV_NAME
conda config --env --add channels conda-forge
conda config --env --add channels legate/label/branch-25.01

conda install legate=$PKG_VER=*_ucx_gpu cupynumeric=$PKG_VER=*_gpu


