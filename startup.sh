#!/bin/bash
source /home/pi/shared/settings.sh

#geolocation
curl -s https://ipinfo.io/ip | curl -s https://api.ipgeolocationapi.com/geolocate/$(</dev/stdin) |python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["geo"]["latitude"]);print (obj["geo"]["longitude"])'> ${workpath}location.txt
#Create our state file if it doesn't exist
echo "off" > ${workpath}light_state.log
#Create our state file if it doesn't exist
echo "on" > ${workpath}tv_state.log

