#!/bin/bash
source settings

#geolocation
curl -s https://ipinfo.io/ip | curl -s https://ipvigilante.com/$(</dev/stdin) |python -c 'import json,sys;obj=json.load(sys.stdin);print obj["data"]["latitude"];print obj["data"]["lo$
#Create our state file if it doesn't exist
echo "off" > ${workpath}light_state.log
#Create our state file if it doesn't exist
echo "on" > ${workpath}tv_state.log

