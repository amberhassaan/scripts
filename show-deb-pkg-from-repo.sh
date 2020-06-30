#!/bin/bash

if [ ! `which aptitude` ] ; then 
  echo "aptitude is required. Please install aptitude via 'apt-get install aptitude'"
fi

REPO="$1"
PKG_STATUS="$2"
if (( $# == 1 )) ; then 
  PKG_STATUS="all"
elif (( $# != 2 )) ; then 
  echo "Usage: $0 {repo-url-partial} {installed|available|all}"
  exit
fi


case $PKG_STATUS in
  installed)
    aptitude search "~O$REPO" --disable-columns -F '%p %v' | grep -v '<none>' | awk '{ print $1}'
    ;;
  available)
    aptitude search "~O$REPO" --disable-columns -F '%p %v' | grep '<none>' | awk '{ print $1}'
    ;;
  all)
    aptitude search "~O$REPO" --disable-columns -F '%p' | awk '{ print $1}'
    ;;
esac;
