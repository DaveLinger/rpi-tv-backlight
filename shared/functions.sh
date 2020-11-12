#sundial() uses geoloaction to calculate the sunrise and sunset time for your location.
sundial () {
  echo "Sunrise time file does not exist. Fetching sunrise/sunset times now."
  lat=$(head -1 ${workpath}location.txt)
  long=$(tail -1 ${workpath}location.txt)
  hdate -s -l $lat -L $long -z $tzone -q| grep 'sunrise' | grep -o '.....$' > ${workpath}sunrise.txt
  hdate -s -l $lat -L $long -z $tzone -q| grep 'sunset' | grep -o '.....$' > ${workpath}sunset.txt
  sunrise=$(cat ${workpath}sunrise.txt)
  sunset=$(cat ${workpath}sunset.txt)
  echo "Done - sunrise at $sunrise, sunset at $sunset"
}


lights_out () {
	if [[ $lightstate == "on" ]]; then
        	echo "Turning light off"
                sudo timeout -k 5 10s /usr/bin/python3 ${pypath}light.py off; ec=$?
                case $ec in
                	0) echo "off" > ${workpath}light_state.log;;
                        124) echo "Python hung up and was killed";;
                        *) echo "Python light script unhandled exit code $ec";;
                esac
        fi
}
