#!/bin/bash

outputfolder=$1
threads=$2

tmux new-session -s tsprd -d

for (( ex=1; ex<=$threads; ex++ ))
do
    tmux send-keys -t tsprd "echo \"Thread ${ex}/${threads}\" && julia executor.jl ${outputfolder} ${threads} ${ex}" C-m
    tmux split-window -t tsprd -v
done

tmux select-layout even-vertical
tmux attach -t tsprd

