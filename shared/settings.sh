#I have this set to tmpfs on a read only filesystem. Necessary files will be created.
workpath=/trash/
#Long-term log file. Any time the TV or light state changes, a timestamped message is written to this file
ltlog=${workpath}ltlog.log
#Path to the light.py script. Assumes python binary is at /usr/bin/python
pypath=/home/pi/rpi-tv-backlight/
#Timezone
tzone=$(date +%-:z)
