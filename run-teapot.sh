#!/bin/bash
export path_to_pid="/home/teapot/teapot.pid"
if [[ -e ${path_to_pid} ]]; then
	stormpid=$(cat "${path_to_pid}")
	kill "${stormpid}"
	rm "${path_to_pid}"
else
	python3 /usr/share/teapot/teapot.py &>/var/log/teapot/uvicorn.log &
	echo $! >"${path_to_pid}"
fi
