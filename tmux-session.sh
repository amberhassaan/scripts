#!/bin/bash
name="$1"

if tmux list-sessions | grep $name; then 
  tmux attach -t $name
else
  tmux new-session -s "$1"
fi
