
sleep 5

for file in /home/pi/shared/*;
  do
      source $file;
 done

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

	if [[ $(find ${workpath}sunrise.txt -mtime 1 -print 2>/dev/null) ]]; then
		echo "Sunrise file exists but is over a day old. Removing."
		rm ${workpath}sunrise.txt
		rm ${workpath}sunset.txt
	fi

	if [ ! -f "${workpath}sunrise.txt" ]; then
		echo "Sunrise time file does not exist. Fetching sunrise/sunset times now."
		lat=$(head -1 ${workpath}location.txt)
                long=$(tail -1 ${workpath}location.txt)
                hdate -s -l $lat -L $long -z $tzone | grep 'sunrise' | grep -o '.....$' > ${workpath}sunrise.txt
                hdate -s -l $lat -L $long -z $tzone | grep 'sunset' | grep -o '.....$' > ${workpath}sunset.txt
                sunrise=$(cat ${workpath}sunrise.txt)
                sunset=$(cat ${workpath}sunset.txt)
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

	trimmed_srt_hours=${sunrise_hour#0}
	trimmed_srt_minutes=${sunrise_min#0}
	trimmed_sst_hours=${sunset_hour#0}
	trimmed_sst_minutes=${sunset_min#0}
	
	#Convert all times into total minutes since midnight for easy comparison
	srt_minutes=$((trimmed_srt_hours * 60 + trimmed_srt_minutes))
	sst_minutes=$((trimmed_sst_hours * 60 + trimmed_sst_minutes))
	now_minutes=$((now_hour * 60 + now_min))

	tvstate=`cat ${workpath}tv_state.log`

	if [[ $tvstate == "off" ]]; then
		#TV is off, let's see if the light should be on or off.
		if [[ $now_minutes -gt $sst_minutes || $now_minutes -lt $srt_minutes ]]; then
			#it's before sunrise or after sunset, light should be on.
			if [[ $lightstate == "off" ]]; then
				#TV is off, it's dark, and the light is off. Let's turn it on.
				echo "Turning light on"
				sudo timeout -k 5 10s /usr/bin/python3 ${pypath}light.py on; ec=$?
				case $ec in
					0) echo "on" > ${workpath}light_state.log;;
					124) echo "Python hung up and was killed";;
					*) echo "Python light script unhandled exit code $ec";;
				esac
			fi
		fi
		if [[ $now_minutes -lt $sst_minutes && $now_minutes -gt $srt_minutes ]]; then
			#it's after sunrise and before sunset, light should be off.
			if [[ $lightstate == "on" ]]; then
				#TV is off, it's light outside, and the light is on. Let's turn it off.
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

sleep 60

done
