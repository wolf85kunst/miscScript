#!/bin/bash
# Hugo GUTEKUNST
# Feb. 2020

# DESCRIPTION
# ------------------------------------------------------------------------------------------------------
# Display your "temps de passage" for given distance and speed or pace.

# SETINGS
# ------------------------------------------------------------------------------------------------------
distance='42.195'			# Integer or float. Distance you want to run in KM. Exemple : "10" or "42.175"
timeToGo='08:30:00'			# String. Start time in "HH:MM:SS" format

# Choose either to set "${speed} or ${pace} or totalTime. Uncomment wish variable you want to set.
#speed='11.25'				# Interger or float format. Exemple : "12" or "12.5"
#pace="5'20"				# String format "5'20" or "5'00"
totalTime='03:45:00'			# String format : "HH:MM:SS"

tempFile='/tmp/tempsDePassage.txt'	# String. Temporary file to generate array
modulo_ImportantKm=5			# Integer (modulo). Wish line to highlight. 

# Color
colorRed="\e[31m"
colorGreen="\e[92m"
colorNormal="\e[97m"

# FUNCTIONS
# ------------------------------------------------------------------------------------------------------
printLine(){
        char='='
        repetition=75
        for i in $(seq 1 ${repetition}) ; do echo -n ${char} ; done
        echo
}
testNumber(){
	regex='^[0-9]+([.][0-9]+)?$'
	if [[ ${1} =~ ${regex} ]]; then
		return 0
	else
		return 1
	fi
}
scaleNumber(){
	float=${1}
	scale=${2}
	if $(testNumber ${float}); then
		if [ ${scale} -eq 0 ]; then
			echo -n ${float} | cut -d'.' -f1
		else
			echo -n ${float} | sed -r "s/([0-9]*\.[0-9]{${scale}}).*/\1/"
		fi
	fi
}
paceToSpeed(){
	# Input : string in format "5'20" (pace)
	# Output : integer or float (speed in km)
	pace=${1}
	secPerKm=$(($(echo ${pace} |cut -d"'" -f1)*60+$(echo ${pace} |cut -d"'" -f2 |sed 's/\"//')))
	echo $(bc -l <<<"(3600/${secPerKm})")
}
speedToPace(){
	# Input : integer or float (speed in km)
	# Output : string in format "5'20" (pace)
	speed=${1}
	secPerKm=$(bc <<<"(3600/${speed})")
	echo "$((${secPerKm}/60))'$((${secPerKm}-(${secPerKm}/60)*60))"
}
addSecToDate(){
	# Input : string = "HH:MM:SS" (time)
	# Output : string = "HH:MM:SS" (time)
	sec=${2}
	epoch=$(date '+%s' -d "02/08/2020 ${1}")
	epoch=$((${epoch}+${sec}))
	echo $(date '+%H:%M:%S' -d@${epoch})
}
paceToSecondPerKm(){
	# Input : string in format "5'20" (pace)
	# Output : integer (Number of seconds)
	pace="${1}"
	echo $(($(echo "${pace}" |cut -d"'" -f1)*60+$(echo "${pace}" |cut -d"'" -f2)))
}
secondPerKmToPace(){
	# Input : interger (Number of seconds)
	# Output : string in format "5'20" (Pace)
	minutes=$((${1}/60))
	secondes=$((${1}-${minutes}*60))
	if [ ${#secondes} -eq 1 ]; then secondes="0${secondes}" ; fi
	echo "${minutes}'${secondes}"
}
timeFormatToSec(){
	# Input : string "HH:MM:SS" (total time)
	hours=$(echo ${1} |cut -d':' -f1)
	minutes=$(echo ${1} |cut -d':' -f2)
	secondes=$(echo ${1} |cut -d':' -f3)
	echo $((${hours}*60*60+${minutes}*60+${secondes}))
}
secToTimeFormat(){
	# Input : interger (number of seconds)
	# Output : string in format "1h 5'40"" (pace)
	hours=$((${1}/60/60))
	minutes=$(((${1}/60)-(${hours}*60)))
	secondes=$((${1}-(${hours}*60*60)-(${minutes}*60)))

	if [ ${#minutes} -eq 1 ]; then minutes="0${minutes}" ; fi
	if [ ${#secondes} -eq 1 ]; then secondes="0${secondes}" ; fi

	if [ ${hours} -ne 0 ]; then hours="${hours}h" ; else hours='' ; fi
	echo "${hours} ${minutes}'${secondes}\""
}
printPassage(){
	if ! echo ${i} |grep -q '\.' ; then
		if [ $((${i}%${modulo_ImportantKm})) -eq 0 ]; then
			color=${colorRed}
		else
			color=${colorNormal}
		fi
		km="[ KM ${i} ]"
	else 
		km="[ KM ${distance} ]"
		secPerKm=$(bc <<<"(0.$(echo ${distance} |cut -d'.' -f2)*${secPerKm})")
		secPerKm=$(echo ${secPerKm} |cut -d'.' -f1)
	fi
	
	elapsedSec=$((${elapsedSec}+${secPerKm}))
	elapsedTimeFormat=$(secToTimeFormat ${elapsedSec})
	ttime="$(addSecToDate ${ttime} ${secPerKm})"

	echo -e "${color}${km}|${elapsedTimeFormat}|${ttime}${colorNormal}" >>${tempFile}
}
printHeader(){
	printLine
	echo -e "start=${colorGreen}${timeToGo}${colorNormal} End=${colorGreen}${ttime}${colorNormal} time=${colorGreen}${elapsedTimeFormat}${colorNormal} Pace=${colorGreen}${pace}/Km${colorNormal} Speed=${colorGreen}$(scaleNumber ${speed} 2)Km/h${colorNormal}" 
	printLine
}
# MAIN
# ------------------------------------------------------------------------------------------------------

# Control
echo -en "${colorNormal}"
if [ -f ${tempFile} ]; then rm ${tempFile}; fi

# Calculate information
if ! [ -z ${speed} ]; then 
	pace=$(speedToPace ${speed})
	secPerKm=$(paceToSecondPerKm "${pace}")
	echo '* Speed set'
elif ! [ -z ${pace} ]; then
	speed=$(paceToSpeed ${pace})
	secPerKm=$(paceToSecondPerKm "${pace}")
	echo '* Pace set'
elif ! [ -z ${totalTime} ]; then
	secPerKm=$(bc -l <<<"($(timeFormatToSec ${totalTime})/${distance})")
	secPerKm=$(scaleNumber ${secPerKm} 0)
	pace=$(secondPerKmToPace ${secPerKm})
	speed=$(paceToSpeed ${pace})
	echo '* TotalTime set'
fi

# init var
elapsedSec=0
ttime=${timeToGo}

for i in $(seq 1 $(echo ${distance} |cut -d'.' -f1)); do
	printPassage
done

# Last meters
if echo ${distance} |grep -q '\.' ; then
	i=${distance}
	printPassage
fi

printHeader

# Display flow
column ${tempFile} -t -s "|"
