#Set our vars

#I have this set to tmpfs on a read only filesystem. Necessary files will be created.
workpath=/trash/
#Code to get sunrise/sunset times for your area.
locationcode="26554"
#Long-term log file. Any time the TV or light state changes, a timestamped message is written to this file
ltlog=${workpath}ltlog.log
#Path to the on.py and off.py scripts. Script assumes python binary is at /usr/bin/python
pypath=/home/pi/

##########

#Create our state files if they don't exist
echo "on" > ${workpath}tv_state.log
echo "off" > ${workpath}light_state.log

#Check if we are online. If we aren't, die. If we are, set the clock and continue.
#This is necessary for read-only filesystem as the raspberry pi does not have a realtime clock.
#pm2 will restart this script if it dies.
if ping -c 1 www.google.com &> /dev/null
then
	echo "Setting time"
        sudo date -s "$(wget -qSO- --max-redirect=0 google.com 2>&1 | grep Date: | cut -d' ' -f5-8)Z"
else
	echo "Network not ready"
	exit
fi

while [ 1 ]
do

tmpfile=${workpath}$locationcode.out

if [[ $(find "$tmpfile" -mtime +1 -print) ]]; then
    echo "File $tmpfile exists but is over a day old. Removing."
    rm ${workpath}$locationcode.out
    rm ${workpath}sunrise.txt
    rm ${workpath}sunset.txt
fi

if [ ! -f "$tmpfile" ]; then
    echo "$tmpfile does not exist. Fetching sunrise/sunset times now."

wget -q "https://weather.com/weather/today/l/$locationcode" -O "$tmpfile"

SUNR=$(grep -o '<p class="_-_-components-src-molecule-SunriseSunset-SunriseSunset--dateValue--3H780">.*am</p>' "$tmpfile" | grep -o '>.*</p>' | cut -c 2- | rev | cut -c5- | rev)
SUNS=$(grep -o '<p class="_-_-components-src-molecule-SunriseSunset-SunriseSunset--dateValue--3H780">.*pm</p>' "$tmpfile" | grep -o '>.*</p>' | cut -f10,1 -d'>' | cut -c2- | rev | cut -c4- | rev)

sunrise=$(date --date="$SUNR" +%R)
sunset=$(date --date="$SUNS" +%R)

# Use $sunrise and $sunset variables to fit your needs. Example:
echo "$sunrise" > ${workpath}sunrise.txt
echo "$sunset" > ${workpath}sunset.txt

fi

#Timestamp for the log file
logts=`date +"%m-%d-%y %T"`

#Get the last on/off state of the TV from file
filevalue=`cat ${workpath}tv_state.log`

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

#echo "Time now is $now_minutes. Sunrise is $srt_minutes, sunset is $sunset_hour $sunset_min $sst_minutes"

	#Poll power state from TV over HDMI. Check for status: on
	echo 'pow 0.0.0.0' | /usr/bin/cec-client -s -d 1 | grep 'status: on' &> /dev/null
	if [ $? == 0 ]; then
		#TV is on
		echo "TV's on"
		if [[ $filevalue == "off" ]]; then
			#Current TV power state is ON, prior state was OFF
			echo "$logts :: TV just turned on." >> $ltlog
			echo "TV JUST turned on"
			echo "Light should be off"
			#if the light strip is on, turn it off.
			if [[ $lightstate == "on" ]]; then
				sudo /usr/bin/python ${pypath}off.py
				echo "off" > ${workpath}light_state.log
				echo "$logts :: Light turned off." >> $ltlog
			else
				echo "Light is already off"
			fi
			sleep 20
		fi
		echo "on" > ${workpath}tv_state.log
	else
		#TV is off
		echo "TV's off"
                if [[ $filevalue == "on" ]]; then
			#Current TV power state is OFF, prior state was ON
                        echo "TV JUST turned off"
			echo "$logts :: TV just turned off." >> $ltlog
			#if it's before sunrise or after sunset, turn the light strip on.
			if [[ $now_minutes -gt $sst_minutes || $now_minutes -lt $srt_minutes ]]; then
				echo "It's night time. Light should be on"
				if [[ $lightstate == "off" ]]; then
        	                        echo "Light is off, turning it on"
                	                sudo /usr/bin/python ${pypath}on.py
					echo "on" > ${workpath}light_state.log
					echo "$logts :: Light turned on." >> $ltlog
				else
					echo "Light is already on"
				fi

			else
				echo "It's daytime, so the light should be off"
                                if [[ $lightstate == "on" ]]; then
                                        echo "Light is on, turning it off"
                                        sudo /usr/bin/python ${pypath}off.py
					echo "off" > ${workpath}light_state.log
					echo "$logts :: Light turned off." >> $ltlog
                                else
                                        echo "Light is already off"
                                fi

			fi
			sleep 5
		else
			#This code changes the light's state even when the TV is just sitting idle, based on the current time.
			if [ $now_minutes -gt $sst_minutes ] || [ $now_minutes -lt $srt_minutes ]; then
				echo "It's night time and the TV is off, light should be on"
				if [[ $lightstate == "off" ]]; then
					echo "Light is off, turning it on"
					sudo /usr/bin/python ${pypath}on.py
					echo "$logts :: Light turned on." >> $ltlog
					echo "on" > ${workpath}light_state.log
				else
					echo "Light is already on"
				fi
			fi
                        if [[ $now_minutes -gt $srt_minutes && $now_minutes -lt $sst_minutes ]]; then
                                echo "It's daytime, light should be off"
                                if [[ $lightstate == "on" ]]; then
                                        echo "Light is on, turning it off"
					sudo /usr/bin/python ${pypath}off.py
					echo "Light->Off"
					echo "$logts :: Light turned off." >> $ltlog
					echo "off" > ${workpath}light_state.log
                                else
                                        echo "Light is already off"
                                fi
                        fi

		fi
		echo "off" > ${workpath}tv_state.log
	fi

	sleep 0.1
done
