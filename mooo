#!/bin/bash

fortunePath=`which fortune`

if [ ! -x $fortunePath ]; then
  echo 'Could not find "fortune" program'
  exit 1;
fi;

cowPath=`which cowthink`

if [ ! -x $cowPath ]; then
  echo 'Could not find "cowsay" program'
  exit 1;
fi;

cowDir="$(dirname $cowPath)/../share/cows"
cowfiles=$(find $cowDir -name '*.cow');

cowfilesList=(`echo $cowfiles`);


len=${#cowfilesList[@]}
# using $RANDOM special bash variable
randIndex=$((RANDOM%len))

cowfile=${cowfilesList[$randIndex]}

mstart=' _______'
mend=' -------'
if [ -x `which fortune` -a -x `which cowsay` ]; then
  echo "Using cow file: $cowfile"
  # $fortunePath -ac | $cowPath -n -f $cowfile | sed "/$mstart/,/$mend/ s/^(\\|)$//g"
  $fortunePath -a | $cowPath -n -f $cowfile | sed "/$mstart/,/$mend/ s/^(\\|)$//g"
fi;

