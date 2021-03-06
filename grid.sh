#!/bin/bash

str="${@}"

process=${str:0:4}

arguments=${str:5}
ary=($arguments)

# Parse browser
for i in "${!ary[@]}"
    do
        if [[ "${ary[$i]}" == "BROWSER"* ]]; then
        	browser=${ary[$i]:8}
        elif [[ "${ary[$i]}" == "-vBROWSER"* ]]; then
        	browser=${ary[$i]:10}
        fi
    done

browsers=("gc" "GC" "chrome" "CHROME" "Chrome" "googlechrome" "GOOGLECHROME" "GoogleChrome")
shm=""
if [[ "${browsers[@]}" =~ "${browser}" ]]; then
	node_type="chrome"
	
elif [[ "${browser}" == "phantomjs" ]]; then
	node_type="phantomjs"

else
	node_type="firefox"
	shm="--shm-size=384m"
fi

# Get number of processes
if [[ $process == -p* ]]; then
	p=${process:2}
else
	echo "Error: provide number of processes"
	exit
fi

# Start hub and nodes
hub_cmd="docker run -d --shm-size=512m -e 'TZ=Asia/Calcutta' -p 5700:4444 --name selenium-hub selenium/hub"
echo "Starting Hub"
eval ${hub_cmd}

echo "Starting nodes"
for i in $(seq 1 $p)
	do
		node_cmd="docker run -d ${shm} -e 'TZ=Asia/Calcutta' --link selenium-hub:hub selenium/node-${node_type}"
		eval ${node_cmd}
		sleep 0.5
	done

# Run using pybot or pabot
if [[ $p -le "1" ]]; then
	pybot_cmd="pybot $arguments"
	eval ${pybot_cmd}
else
	pabot_cmd="pabot --processes $p $arguments"
	echo ${pabot_cmd}
	eval ${pabot_cmd}
fi

# Cleanup
stop_all_containers="docker stop $(docker ps -aq)"
remove_all_containers="docker rm $(docker ps -aq)"
eval ${stop_all_containers}
eval ${remove_all_containers}
