#!/bin/bash

tmux new-session -s tsprd -d

outputfolder=$1
th=$2

threads=$(($th*4))
for (( w=0; w<$th; w++ ))
do
    ex=$(($w*4+1))
    tmux send-keys -t tsprd:$w "echo \"Thread 1/${threads}\" && julia executor.jl ${outputfolder} ${threads} ${ex}" C-m

    ex=$(($w*4+2))
    tmux split-window -t tsprd:$w -h -p 50
    tmux send-keys -t tsprd:$w "echo \"Thread 2/${threads}\" && julia executor.jl ${outputfolder} ${threads} ${ex}" C-m

    ex=$(($w*4+4))
    tmux split-window -t tsprd:$w -v -p 50
    tmux send-keys -t tsprd:$w "echo \"Thread 4/${threads}\" && julia executor.jl ${outputfolder} ${threads} ${ex}" C-m

    ex=$(($w*4+3))
    tmux select-pane -t 0
    tmux split-window -t tsprd:$w -v -p 50
    tmux send-keys -t tsprd:$w "echo \"Thread 3/${threads}\" && julia executor.jl ${outputfolder} ${threads} ${ex}" C-m

    tmux new-window -t tsprd
done

tmux kill-window -t tsprd
tmux attach -t tsprd
