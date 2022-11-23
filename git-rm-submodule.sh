#!/bin/bash

name="$1"
echo "Removing submodule $name"

if [[ "x$name" == "x" ]] ; then
  echo "Submodule path empty"
  exit 1;
fi

git submodule deinit $name
rmdir $name
rm -rf .git/modules/$name

git commit -a -m "removing submodule $name"

