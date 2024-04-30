#!/bin/bash
# taken from https://mutelight.org/practical-tmux

if [[ -z "$1" ]]; then
    echo "Specify session name as the first argument"
    exit
fi

base_session="$1"
# This actually works without the trim() on all systems except OSX
tmux_nb=$(tmux ls | grep "^$base_session" | wc -l)
if [[ "$tmux_nb" == "0" ]]; then
    echo "Launching tmux base session $base_session ..."
    tmux new-session -s $base_session
else
    # Make sure we are not already in a tmux session
    if [[ -z "$TMUX" ]]; then
        # Kill defunct sessions first
        old_sessions=$(tmux ls 2> /dev/null | egrep '^[0-9]{14}.*[0-9]+)$' | cut -f 1 -d:)
        for old_session_id in $old_sessions; do
            tmux kill-session -t $old_session_id
        done

        echo "Launching copy of base session $base_session ..."
        # Session is is date and time to prevent conflict
        session_id=`date +%Y%m%d%H%M%S`
        # Create a new session (without attaching it) and link to base session 
        # to share windows
        tmux new-session -t $base_session -s $session_id
        # When we detach from it, kill the session
        tmux kill-session -t $session_id
    fi
fi 
