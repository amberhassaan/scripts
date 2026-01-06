#!/usr/bin/false
#

if [[ -z $(which nvcc) ]] ; then

  if [[ -d /usr/local/cuda ]] ; then 
    export PATH="$PATH:/usr/local/cuda/bin"
  elif [[ -d /opt/cuda ]] ; then
    export PATH="$PATH:/opt/cuda/bin"
  fi;
  
fi;
