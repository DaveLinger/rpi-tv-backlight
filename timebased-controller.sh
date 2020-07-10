#Set our vars

#I have this set to tmpfs on a read only filesystem. Necessary files will be created.
workpath=/trash/
#Code to get sunrise/sunset times for your area.
locationcode="26554"
#Long-term log file. Any time the TV or light state changes, a timestamped message is written to this file
ltlog=${workpath}ltlog.log
#Path to the light.py script. Assumes python binary is at /usr/bin/python
pypath=/home/pi/
#Path to the temporary weather file
tmpfile=${workpath}$locationcode.out

##########

sleep 30

i=0
while [ $i -lt 1 ]
do
        if ping -c 1 www.google.com &> /dev/null
        then
                i=1
		true
                #We are online, continuing.
        else
                echo "Network not ready, exiting"
                exit
        fi
done

while [ 1 ]
do

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
                        SUNS=$(grep -o '<p class="_-_-components-src-molecule-SunriseSunset-SunriseSunset--dateValue--3H780">.*pm</p>' "$tmpfile" | grep -o '>.*</p>' | cut -f10,1 -d'>' | cut -c2- | rev)

                        sunrise=$(date --date="$SUNR" +%R)
                        sunset=$(date --date="$SUNS" +%R)
                        echo "$sunrise" > ${workpath}sunrise.txt
                        echo "$sunset" > ${workpath}sunset.txt
			echo "Done - sunrise at $sunrise, sunset at $sunset"

                fi

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

	tvstate=`cat ${workpath}tv_state.log`

	if [[ $tvstate == "off" ]]; then
		#TV is off, let's see if the light should be on or off.

		if [[ $now_minutes -gt $sst_minutes || $now_minutes -lt $srt_minutes ]]; then
			#it's before sunrise or after sunset, light should be on.

			if [[ $lightstate == "off" ]]; then
				#TV is off, it's dark, and the light is off. Let's turn it on.
                        	echo "Turning light on"
                                sudo /usr/bin/python ${pypath}light.py on
                                echo "on" > ${workpath}light_state.log
			fi
		fi

	fi

sleep 60

done
