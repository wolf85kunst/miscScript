#!/bin/bash
# Hugo GUTEKUNST
# Feb. 2020

# DESCRIPTION
# ------------------------------------------------------------------------------------------------------
# Training plan generator
# This script generates a customized training plan for half-marathon and marathon

# SETINGS
# ------------------------------------------------------------------------------------------------------
# Global setings
beginningDate='20200203'	# Date of the first monday of the training plan. Format : "YYYYmmdd"
lastMondayDate='20200323'	# Date of the last week of the training plan. Format : "YYYYmmdd"
numberOfWeekForTraining=8	# Number of weeks for the training plan

declare -a runFrequency		# Running frequency per week (time to go)
				# Declaration syntax : "Number of runs per week ; Number of weeks ; comment"
				# If Number of week is "-" on runFrequency[0] then the number of weeks of each different runFrequency is equal
runFrequency[0]='4;-;3 trainings per week'
runFrequency[1]='5;-;4 trainings per week'

# Running volume
initialVolume=37		# Initial running volume (KM)
volumeTarget=60			# The maximum running volume desired in a week (KM)

# Long Run
firstLongRun=1			# week number of the first long run (week number)
initialLongRun=15		# The first long run in kilometer (KM)
longRunTarget=30 		# The biggest desired run in the training plan (KM)

# Volume reduction (sharpening)
longRunBefore=4			# Number of weeks after the longuest run
declare -a sharpening		# Sharpening period. Declare as many lines as there will be sharpening week after ${volumeTarget}		
				# Declaration syntax : "percent of volume ; Run per week"
sharpening[0]='50;3'
sharpening[1]='20;1'

# Misc settings
scaleNumber=0			# Precision of float number on display
tempFile=/tmp/plan.txt		# Temporary file to draw the array

# Colors definition		# Bash color code library
colorRed="\e[31m"
colorGreen="\e[92m"
colorNormal="\e[97m"
colorMagenta="\e[95m"
colorBackgroundBlue="\e[44m"

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
rewriteRunFrequency(){
	period=$((${numberOfWeekForTraining}-${#sharpening[@]}))
	if [ "$(echo ${runFrequency} | cut -d';' -f2 )" != '-' ]; then
		sum=0 && for i in ${!runFrequency[@]}; do
			sum=$((sum+$(echo ${runFrequency[${i}]} | cut -d';' -f2)))
		done
		if [ ${sum} -ne ${period} ]; then
			echo -e "/!\ \${numberOfWeekForTraining} (${period}) should be equal to sum of \${runFrequency[@]} (${sum}) !" && exit
		fi
	else
		for i in ${!runFrequency[@]} ; do
			if [ ${i} -eq $((${#runFrequency[@]}-1)) ]; then
				numberOfWeek=$((${period}-(${period}/${#runFrequency[@]})*(${#runFrequency[@]}-1)))
			else
				numberOfWeek=$((${period}/${#runFrequency[@]}))
			fi
			numberOfTrainings=$(echo ${runFrequency[${i}]} | cut -d';' -f1)	
			runFrequency[${i}]="${numberOfTrainings};${numberOfWeek}"
		done
	fi
	cpt=1
	for i in ${!sharpening[@]}; do
		numberOfRun=$(echo ${sharpening[${i}]} |cut -d';' -f2)
		runFrequency[$((${#runFrequency[@]}))]="${numberOfRun};1"
		cpt=$((cpt+1))
	done
}
calcVolume(){
	if [ ${i} -lt $((${numberOfWeekForTraining}-${#sharpening[@]})) ]; then
		# Increase volume
		weekVolume=$(bc -l <<<"(${initialVolume}+${interval}*(${i}-1))")
	elif [ ${i} -eq $((${numberOfWeekForTraining}-${#sharpening[@]})) ]; then
		weekVolume=${volumeTarget}
	elif [ ${i} -ge $((${numberOfWeekForTraining}-${#sharpening[@]}+1)) ]; then
		# Shapening phase
		percentageVolume=$( echo ${sharpening[$((${i}-(${numberOfWeekForTraining}-${#sharpening[@]}+1)))]} |cut -d';' -f1 )
		weekVolume=$(bc -l <<<"(${percentageVolume}*${volumeTarget}/100)")
	fi
}
calcRunPerWeek(){
	sum=0
	for j in ${!runFrequency[@]} ; do
		numberOfWeek=$(echo ${runFrequency[${j}]} | cut -d';' -f2)
		if [ ${i} -le $((${numberOfWeek}+${sum})) ]; then
			break
		else
			sum=$((${sum}+${numberOfWeek}))
			continue
		fi
	done
	runPerWeek=$(echo ${runFrequency[${j}]} | cut -d';' -f1)
}
calcAvg(){
	avg=$(bc -l <<<"(${weekVolume}/${runPerWeek})")
}
calcLongRun(){
	if [ ${i} -ge $((${numberOfWeekForTraining}-(${#sharpening[@]}+1))) ]; then
		longRun='-'
	elif [ ${i} -ge ${firstLongRun} ]; then
		longRun=$(bc -l <<<"(${initialLongRun}+((${i}-(${firstLongRun}))*${intervalLongRun}))")
	else
		longRun='-'	
	fi
}
calcAvgSingle(){
	if [ ${i} -ge $((${numberOfWeekForTraining}-(${#sharpening[@]}+1))) ]; then
		avgSingle="${avg}"
	elif [ ${i} -ge ${firstLongRun} ]; then
		avgSingle=$(bc -l <<<"((${weekVolume}-${longRun})/(${runPerWeek}-1))")	
	else
		avgSingle="${avg}"
	fi
}
calcDate(){
	weekDate=$(date '+%Y%m%d' -d "${beginningDate}+$((7*(${i}-1))) days") ;
}
printTrainingPlan(){
	if [ ${i} -ge $((${numberOfWeekForTraining}-${#sharpening[@]}+1)) ]; then weekNumber=${colorRed}S${i}${colorNormal} ; else weekNumber=S${i} ; fi
	
	dateFormat="${colorMagenta}$(date +%d/%m/%Y -d ${2})${colorNormal}"
	
	if [ ${i} -eq $((${numberOfWeekForTraining}-${#sharpening[@]})) ]; then
		weekVolume="${colorRed}$(scaleNumber ${3} ${scaleNumber})${colorNormal}km"
	else
		weekVolume="${colorGreen}$(scaleNumber ${3} ${scaleNumber})${colorNormal}km"
	fi
	
	runPerWeek="${colorGreen}${4}${colorNormal}"
	avg="${colorGreen}$(scaleNumber ${5} 2)${colorNormal}km"
	
	if testNumber ${6}; then
		if [ ${i} -eq $((${numberOfWeekForTraining}-${longRunBefore})) ]; then
			longRun="${colorRed}$(scaleNumber ${6} ${scaleNumber})${colorNormal}km"
		else
			longRun="${colorGreen}$(scaleNumber ${6} ${scaleNumber})${colorNormal}km"
		fi
	else
		longRun="${colorRed}${6}${colorNormal}"
	fi
	
	avgSingle="${colorGreen}$(scaleNumber ${7} 2)${colorNormal}km"

	echo -e "${weekNumber}|[${dateFormat}]|volume=${weekVolume}|run=${runPerWeek}|avg=${avg}|LR=${longRun}|avgS=${avgSingle}" >> ${tempFile}
}

# MAIN
# ------------------------------------------------------------------------------------------------------
# Some control before starting
rewriteRunFrequency
if [ -f ${tempFile} ]; then rm ${tempFile}; fi

longRunPeriod=$((${numberOfWeekForTraining}-${longRunBefore}-${firstLongRun}+1))
volumePeriod=$((${numberOfWeekForTraining}-${#sharpening[@]}))
interval=$(bc -l <<<"(${volumeTarget}-${initialVolume})/(${volumePeriod}-1)")
intervalLongRun=$(bc -l <<<"(${longRunTarget}-${initialLongRun})/(${longRunPeriod}-1)")

# ----------------------------------
# SUMMARY
# ----------------------------------
echo -e "${colorNormal}"
printLine
echo -e " ${colorGreen}SUMMARY${colorNormal}"
printLine
echo -e "* Your training plan will start on [${colorMagenta}$(date '+%d/%m/%Y' -d ${beginningDate})${colorNormal}] and stop on [${colorMagenta}$(date '+%d/%m/%Y' -d ${lastMondayDate})${colorNormal}] !"
echo -e "* Your training plan will last ${colorGreen}${numberOfWeekForTraining}${colorNormal} weeks."
echo
echo -e "* Increase period :"
echo -e "\tYou will increase your volume during ${colorGreen}${volumePeriod}${colorNormal} weeks : \
${initialVolume} Km to ${volumeTarget} Km (+ ~${colorGreen}$(scaleNumber ${interval} 2)${colorNormal} Km each week)."
echo -e "\tYou will increase your long run (LR) during ${colorGreen}${longRunPeriod}${colorNormal} weeks : \
${initialLongRun} Km to ${longRunTarget} (+ ~${colorGreen}$(scaleNumber ${intervalLongRun} 2)${colorNormal} Km each week)."
echo
echo -e "* Different training phase :"

for i in ${!runFrequency[@]}; do
	echo -e "\tP$((${i}+1))) ${colorGreen}$(echo ${runFrequency[${i}]} | cut -d';' -f1)${colorNormal} trainings per week during ${colorGreen}$(echo ${runFrequency[${i}]} |cut -d';' -f2)${colorNormal} weeks."
done
echo
echo


totalRun=0
for i in $(seq 1 ${numberOfWeekForTraining}); do
		calcDate
		calcVolume
		calcRunPerWeek
		calcAvg
		calcLongRun
		calcAvgSingle
		totalRun=$((${totalRun}+${runPerWeek}))

		printTrainingPlan ${i} ${weekDate} ${weekVolume} ${runPerWeek} ${avg} ${longRun} ${avgSingle}
done

# ----------------------------------
# TRAINING PLAN
# ----------------------------------
printLine
echo -e " ${colorGreen}TRAINING PLAN${colorNormal} [${numberOfWeekForTraining} weeks] [${totalRun} runs] [V=${initialVolume}->${volumeTarget},+$(scaleNumber ${interval} 2)] [LR=${initialLongRun}->${longRunTarget},+$(scaleNumber ${intervalLongRun} 2)]"
printLine

# Draw array
column ${tempFile} -t -s "|"
