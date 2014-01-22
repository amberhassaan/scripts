#!/bin/bash

internal_pattern='LVDS.*'
internal=$(xrandr | grep ' connected '| awk '{ print $1; }' | grep  "$internal_pattern" | sort| head -n 1)
external=$(xrandr | grep ' connected '| awk '{ print $1; }' | grep -v "$internal_pattern" | sort | head -n 1)

echo "Found internal: $internal";
echo "Found external: $external";


mode=${1-"single"}
position=${2-"--left-of"}; # replace with "--right-of" or "--above" or "--below"

if [ "$mode" != "single" ] ; then
  if [ "X$external" != "X" ]; then
    cmd="xrandr --output $external --auto $position $internal"
    echo "Executing: $cmd";
    eval $cmd;
  else
    echo "Could not find an external output";
  fi;
else
  outputs=$(xrandr | grep ' disconnected ' | awk '{ print $1; }' | tr '\n' ' ');
  echo $outputs;
  for o in $outputs; do 
    cmd="xrandr --output $o --off"
    echo "Executing: $cmd"
    eval $cmd;
  done;
fi;



