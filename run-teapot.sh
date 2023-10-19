#!/bin/bash

path_to_pid='$HOME/teapot.pid'
if [ -a $path_to_pid ]; then
        stormpid=`cat $path_to_pid`
        kill $stormpid 
        rm $path_to_pid
else
    	python3 /usr/share/teapot/teapot.py &> tmp-storm-proxy.log &
        echo $! > $path_to_pid
fi

