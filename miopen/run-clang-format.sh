#!/bin/bash

# Script for running clang-format manually.
# Usage: 
# ./<script-name> 
#
# Or
#
# ./<script-name> <branch-or-commit-to-compare-against>
#
# The argument above can be for example 'main' branch where you want to format all
# the files in your branch that are different from the 'main' branch

REF=${1:-"HEAD"}

for f in `git diff $REF --name-only | grep -iE '\.([hc]pp|[hc]|cl)'`; do
  echo "Formatting: $f"
  clang-format-12 -i -style=file $f
done
