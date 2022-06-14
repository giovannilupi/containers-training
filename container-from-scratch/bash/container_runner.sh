#!/bin/sh

if [ $TERM = "screen" ] ; then
    tmux split-window "../bin/container_example run /bin/sh"
    sudo ./container_manager.sh
else
    echo "This script must be run inside tmux"
fi