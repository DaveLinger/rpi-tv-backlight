#Set our vars

#I have this set to tmpfs on a read only filesystem. Necessary files will be created.
workpath=/trash/
#Long-term log file. Any time the TV or light state changes, a timestamped message is written to this file
ltlog=${workpath}ltlog.log
#Path to the light.py script. Assumes python binary is at /usr/bin/python
pypath=/home/pi/
#Timezone
tzone=$(date +%z |  python -c 'import sys;z=int(sys.stdin.readline().strip());z=str(z);print(z[:-2] + ":" + z[-2:])')
#Path to the temporary weather file
tmpfile=${workpath}$locationcode.out

##########

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
                        curl -s https://ipinfo.io/ip | curl -s https://ipvigilante.com/$(</dev/stdin) |python -c 'import json,sys;obj=json.load(sys.stdin);print obj["data"]["latitude"];print obj["data"]["longitude"]' > ${workpath}location.txt
			lat=$(head -1 ${workpath}location.txt)
			long=$(tail -1 ${workpath}location.txt)
			hdate -s -l $lat -L $long -z $tzone | grep 'sunrise' | grep -o '.....$' > ${workpath}sunrise.txt
			hdate -s -l $lat -L $long -z $tzone | grep 'sunset' | grep -o '.....$' > ${workpath}sunset.txt
                        sunrise=$(cat ${workpath}sunrise.txt)
                	sunset=$(cat ${workpath}sunset.txt)
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

			#echo "Line found referencing TV: $line"

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
			
                        trimmed_srt_hours=${sunrise_hour#0}
                        trimmed_srt_minutes=${sunrise_min#0}
                        trimmed_sst_hours=${sunset_hour#0}
                        trimmed_sst_minutes=${sunset_min#0}

                        #Convert all times into total minutes since midnight for easy comparison
                        srt_minutes=$((trimmed_srt_hours * 60 + trimmed_srt_minutes))
                        sst_minutes=$((trimmed_sst_hours * 60 + trimmed_sst_minutes))
                        now_minutes=$((now_hour * 60 + now_min))
			
                        if grep -q standby\'$  <<< "$line"; then
				echo "TV turned off."
				echo "off" > ${workpath}tv_state.log
					#if it's night time, turn the light on.
					if [[ $now_minutes -gt $sst_minutes || $now_minutes -lt $srt_minutes ]]; then
						echo "Turning light on"
						sudo timeout -k 5 10s /usr/bin/python3 ${pypath}light.py on; ec=$?
						case $ec in
							0) echo "on" > ${workpath}light_state.log;;
							124) echo "Python hung up and was killed";;
							*) echo "Python light script unhandled exit code $ec";;
						esac
					fi
			fi
			if grep -q on\'$ <<< "$line"; then	
                                echo "TV turned on."
				echo "on" > ${workpath}tv_state.log
					#if the light's on, turn it off.
					if [[ $lightstate == "on" ]]; then
						echo "Turning light off"
						sudo timeout -k 5 10s /usr/bin/python3 ${pypath}light.py off; ec=$?
						case $ec in
							0) echo "off" > ${workpath}light_state.log;;
							124) echo "Python hung up and was killed";;
							*) echo "Python light script unhandled exit code $ec";;
						esac
					fi
			fi

        fi
done
