#!/bin/bash

internal_pattern='LVDS.*'
internal=$(xrandr | grep ' connected '| awk '{ print $1; }' | grep  "$internal_pattern" | sort| head -n 1)
external=$(xrandr | grep ' connected '| awk '{ print $1; }' | grep -v "$internal_pattern" | sort | head -n 1)

echo "Found output: $internal";
echo "Found output: $external";


mode=${1-"single"}
position=${2-"--left-of"}; # replace with "--right-of" or "--above" or "--below"

if [ "X$external" != "X" ]; then
  if [ "$mode" != "single" ] ; then
    cmd="xrandr --output $external --auto $position $internal"
    echo "Executing: $cmd";
    exec $cmd;
  else
    cmd="xrandr --output $external --off"
    echo "Executing: $cmd"
    exec $cmd;
  fi;
else
  if [ "$mode" != "single" ]; then
    echo "Could not find an external output";
  fi;
fi;



