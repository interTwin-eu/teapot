#!/bin/bash

if [ -a $path_to_pid ]; then
        stormpid=`cat $path_to_pid`
        kill $stormpid 
        rm $path_to_pid
else
python3 $HOME/teapot/teapot.py &> $/var/log/teapot/tmp-storm-proxy.log &
        echo $! > $path_to_pid
fi