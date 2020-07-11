#Set our vars

#I have this set to tmpfs on a read only filesystem. Necessary files will be created.
workpath=/trash/
#Code to get sunrise/sunset times for your area. Location is determined via IP geolocation unless this is set.
#locationcode="26554"
#Long-term log file. Any time the TV or light state changes, a timestamped message is written to this file
ltlog=${workpath}ltlog.log
#Path to the light.py script. Assumes python binary is at /usr/bin/python
pypath=/home/pi/

#These are the strings we are looking for from cec-client
poweroff_str1="power status changed from 'unknown' to 'standby'"
poweroff_str2="power status changed from 'on' to 'standby'"
poweron_str1="power status changed from 'standby' to 'in transition from standby to on'"
poweron_str2="power status changed from 'unknown' to 'in transition from standby to on'"

#Create our state file if it doesn't exist
echo "off" > ${workpath}light_state.log

#Create our state file if it doesn't exist
echo "on" > ${workpath}tv_state.log

#Check if we are online. If we aren't, die. If we are, set the clock and continue.
#This is necessary for read-only filesystem as the raspberry pi does not have a realtime clock.
#pm2 will restart this script if it dies.
i=0
while [ $i -lt 1 ]
do
	if ping -c 1 www.google.com &> /dev/null
	then
		i=1
		echo "Setting time"
        sudo date -s "$(wget -qSO- --max-redirect=0 google.com 2>&1 | grep Date: | cut -d' ' -f5-8)Z"

		if [ ! -f "${workpath}sunrise.txt" ]; then

			echo "Sunrise time file does not exist. Fetching sunrise/sunset times now."
			if [ -z "$locationcode" ]; then
				#$locationcode is not set; determine zipcode via IP geolocation
				echo "Geolocating you by your IP" 
				tmpfile=${workpath}postalcode
				wget -q "https://tools.keycdn.com/geo" -O "$tmpfile"
				zipcode=$(grep -o 'Postal code</dt><dd class="col-8 text-monospace">.*</dd>' "$tmpfile" | grep -o '>.*</dd>')
				zipcode="${zipcode:34}"
				locationcode="${zipcode:0:5}"
				echo "Got $locationcode"
				rm $tmpfile
			fi

			wget -q "https://weather.com/weather/today/l/$locationcode" -O "$tmpfile"

			SUNR=$(grep -o '<p class="_-_-components-src-molecule-SunriseSunset-SunriseSunset--dateValue--3H780">.*am</p>' "$tmpfile" | grep -o '>.*</p>' | cut -c 2- | rev | cut -c5- | rev)
			SUNS=$(grep -o '<p class="_-_-components-src-molecule-SunriseSunset-SunriseSunset--dateValue--3H780">.*pm</p>' "$tmpfile" | grep -o '>.*</p>' | cut -f10,1 -d'>' | cut -c2- | rev | cut -c4- | rev)

			sunrise=$(date --date="$SUNR" +%R)
			sunset=$(date --date="$SUNS" +%R)
			echo "$sunrise" > ${workpath}sunrise.txt
			echo "$sunset" > ${workpath}sunset.txt
			echo "Done - sunrise at $sunrise, sunset at $sunset"

		fi

	else
		echo "Network not ready, exiting"
		sleep 2
		exit
	fi
done

tail -fn0 ${workpath}cec-monitor.log | \
while read line ; do
	echo "$line" | grep "TV" -q
	if [ $? = 0 ]
	then

		#Timestamp for the log file
		logts=`date +"%m-%d-%y %T"`
			
		#Get the current on/off state of the light strip from file
		lightstate=`cat ${workpath}light_state.log`
			
		#Get today's sunrise and sunset times from file and separate into hours and minutes
		sunrise=`cat ${workpath}sunrise.txt`
		sunset=`cat ${workpath}sunset.txt`
		IFS=: read sunrise_hour sunrise_min <<< "$sunrise"
		IFS=: read sunset_hour sunset_min <<< "$sunset"
			
		#Get the hours and minutes of the current time
		now_hour=`date +"%-H"`
		now_min=`date +"%-M"`
			
		#Convert all times into total minutes since midnight for easy comparison
		srt_minutes=$((sunrise_hour * 60 + sunrise_min))
		sst_minutes=$((sunset_hour * 60 + sunset_min))
		now_minutes=$((now_hour * 60 + now_min))
			
		if grep -q "${poweroff_str1}\|${poweroff_str2}" <<< "$line"; then
			echo "TV turned off."
			echo "off" > ${workpath}tv_state.log
			#if it's night time, turn the light on.
			if [[ $now_minutes -gt $sst_minutes || $now_minutes -lt $srt_minutes ]]; then
				echo "Turning light on"
				sudo /usr/bin/python ${pypath}light.py on
				echo "on" > ${workpath}light_state.log
			fi
		fi
		if grep -q "${poweron_str1}\|${poweron_str2}" <<< "$line"; then
			echo "TV turned on."
			echo "on" > ${workpath}tv_state.log
			#if the light's on, turn it off.
			if [[ $lightstate == "on" ]]; then
				echo "Turning light off"
				sudo /usr/bin/python ${pypath}light.py off
				echo "off" > ${workpath}light_state.log
			fi
		fi
	fi
done