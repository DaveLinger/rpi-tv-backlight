#!/bin/bash
source /home/pi/rpi-tv-backlight/shared/settings.sh

#geolocation
curl -s https://ipinfo.io/ip | curl -s http://ip-api.com/json/$(</dev/stdin) |python -c 'import json,sys;obj=json.load(sys.stdin);print (obj["lat"]);print (obj["lon"])'> ${workpath}location.txt
#Create our state file if it doesn't exist
echo "off" > ${workpath}light_state.log
#Create our state file if it doesn't exist
echo "on" > ${workpath}tv_state.log
