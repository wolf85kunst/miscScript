#!/bin/bash
# Hugo GUTEKUNST
# Feb. 2020

# DESCRIPTION
# ------------------------------------------------------------------------------------------------------
# Display your "temps de passage" for given distance and speed or allure.

# SETINGS
# ------------------------------------------------------------------------------------------------------
distance=42				# Integer or float. Distance you want to run in KM. Exemple : "10" or "42.175"
timeToGo=08:30:00			# String. Start time in "HH:MM:SS" format

# Choose either to set "${speed} or ${allure}. Uncomment either.
#speed=					# Interger or float format. Exemple : "12" or "12.5"
allure="5'20"				# String format "5'20" or "5'00"

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
allureToSpeed(){
	# Input : string in format "5'20" (allure)
	# Output : integer or float (speed in km)
	allure=${1}
	secPerKm=$(($(echo ${allure} |cut -d"'" -f1)*60+$(echo ${allure} |cut -d"'" -f2 |sed 's/\"//')))
	echo $(bc -l <<<"(3600/${secPerKm})")
}
speedToAllure(){
	# Input : integer or float (speed in km)
	# Output : string in format "5'20" (allure)
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
allureToSecondPerKm(){
	# Input : string in format "5'20" (allure)
	# Output : integer (Number of seconds)
	allure="${1}"
	echo $(($(echo "${allure}" |cut -d"'" -f1)*60+$(echo "${allure}" |cut -d"'" -f2)))
}
secToTimeFormat(){
	# Input : interger (number of seconds)
	# Output : string in format "1h 5'40"" (allure)
	hours=$((${1}/60/60))
	minutes=$(((${1}/60)-(${hours}*60)))
	secondes=$((${1}-(${hours}*60*60)-(${minutes}*60)))
	if [ ${hours} -ne 0 ]; then hours="${hours}h" ; else hours='' ; fi
	echo "${hours} ${minutes}'${secondes}\""
}
printPassage(){
	if [ $((${i}%${modulo_ImportantKm})) -eq 0 ]; then
		km="${colorRed}[ KM ${i} ]${colorNormal}"
	else
		km="[ KM ${i} ]"
	fi
	elapsedSec=$((${elapsedSec}+${secPerKm}))
	elapsedTimeFormat=$(secToTimeFormat ${elapsedSec})
	ttime="$(addSecToDate ${ttime} ${secPerKm})"
	echo -e "${km}|${elapsedTimeFormat}|${ttime}" >>${tempFile}
}
printHeader(){
	printLine
	echo -e "start=${colorGreen}${timeToGo}${colorNormal} End=${colorGreen}${ttime}${colorNormal} Allure=${colorGreen}${allure}/Km${colorNormal} Speed=${colorGreen}$(scaleNumber ${speed} 2)Km/h${colorNormal}" 
	printLine
}
# MAIN
# ------------------------------------------------------------------------------------------------------

# Control
echo -en "${colorNormal}"
if [ -f ${tempFile} ]; then rm ${tempFile}; fi
if [ -z ${speed} ]; then speed=$(allureToSpeed ${allure}) ; fi
if [ -z ${allure} ]; then allure=$(speedToAllure ${speed}) ; fi

#echo "speed=$speed ; allure=$allure"
#allureToSecondPerKm ${allure}
#exit

# init var
secPerKm=$(allureToSecondPerKm "${allure}")
elapsedSec=0
ttime=${timeToGo}

for i in $(seq 1 ${distance}); do
	printPassage
done

printHeader

# Display flow
column ${tempFile} -t -s "|"
