#sundial() uses geoloaction to calculate the sunrise and sunset time for your location.
sundial () {
  echo "Sunrise time file does not exist. Fetching sunrise/sunset times now."
  lat=$(head -1 ${workpath}location.txt)
  long=$(tail -1 ${workpath}location.txt)
  hdate -s -l $lat -L $long -z $tzone | grep 'sunrise' | grep -o '.....$' > ${workpath}sunrise.txt
  hdate -s -l $lat -L $long -z $tzone | grep 'sunset' | grep -o '.....$' > ${workpath}sunset.txt
  sunrise=$(cat ${workpath}sunrise.txt)
  sunset=$(cat ${workpath}sunset.txt)
  echo "Done - sunrise at $sunrise, sunset at $sunset"
}
