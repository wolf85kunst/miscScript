#!/bin/bash
# Hugo GUTEKUNST Feb. 2020

# DESCRIPTION
# ------------------------------------------------------------------------------------------------------
# Training plan generator
# This script generates a customized training plan for half-marathon and marathon

# SETINGS
# ------------------------------------------------------------------------------------------------------
# Global training setings
beginningDate='20200101'	# Date of the first monday of the training plan. Format : "YYYYmmdd"
lastMondayDate='20200324'	# Date of the last week of the training plan. Format : "YYYYmmdd"
numberOfWeekForTraining=16	# Number of weeks for the training plan

declare -a runFrequency		# Running frequency per week (time to go)
				# Declaration syntax : "Number of runs per week ; Number of weeks ; comment"
				# If Number of week is "-" on runFrequency[0] then the number of weeks of each different runFrequency is equal
runFrequency[0]='3;-;3 trainings per week'
runFrequency[1]='4;-;4 trainings per week'
runFrequency[2]='5;-;5 trainings per week'

# Running volume
initialVolume=30		# Initial running volume (KM)
volumeTarget=70			# The maximum running volume desired in a week (KM)

# Long Run
firstLongRun=7			# week number of the first long run (week number)
initialLongRun=10		# The first long run in kilometer (KM)
longRunTarget=30 		# The longest run desired in the training plan (KM)

# Rest
sharpening=2			# Number of weeks before competition for sharpening
longRunBefore=4			# Number of weeks after the longuest run

# Volume reduction
scaleBackP1=50			# The first phase of volume reduction (percentage)
scaleBackP2=10			# The second phase of volume reduction (percentage)

declare -a sharpening
sharpening[0]='50'
sharpening[1]='10'

# Global settings
scaleNumber=2			# Precision of float number on display

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
	repetition=40
	for i in $(seq 1 ${repetition}) ; do echo -n ${char} ; done
	echo
}
scaleNumber(){
	# Arg3 = float
	# Arg2 = scale
	float=${1}
	scale=${2}
	#if ! [[ ${float} =~ '^[0-9.]+$' ]]; then
	if [ ${scale} -eq 0 ]; then
		echo -n ${float} | cut -d'.' -f1
	else
		echo -n ${float} | sed -r "s/([0-9]*\.[0-9]{${scale}}).*/\1/"
	fi
}
controlRunFrequency(){
	if [ "$(echo ${runFrequency} | cut -d';' -f2 )" != '-' ]; then
		sum=0 && for i in ${!runFrequency[@]}; do
			sum=$((sum+$(echo ${runFrequency[${i}]} | cut -d';' -f2)))
		done
		if [ ${sum} -ne ${numberOfWeekForTraining} ]; then
			echo -e "/!\ \${numberOfWeekForTraining} (${numberOfWeekForTraining}) should be equal to sum of \${runFrequency[@]} (${sum}) !" && exit
		fi
	else
		for i in ${!runFrequency[@]} ; do
			if [ ${i} -eq $((${#runFrequency[@]}-1)) ]; then
				numberOfWeek=$((${numberOfWeekForTraining}-(${numberOfWeekForTraining}/${#runFrequency[@]})*(${#runFrequency[@]}-1)))
			else
				numberOfWeek=$((${numberOfWeekForTraining}/${#runFrequency[@]}))
			fi
			numberOfTrainings=$(echo ${runFrequency[${i}]} | cut -d';' -f1)	
			runFrequency[${i}]="${numberOfTrainings};${numberOfWeek}"
		done
	fi
}
printVolume(){
	shapeningPeriod=$((${numberOfWeekForTraining}-${#sharpening[@]}))
	case ${i} in
		${shapeningPeriod})
			weekVolume=100
		;;
		*)
			#weekVolume=$(bc -l <<<"(${weekVolume}+${interval})")
			#30 + 3,7 * (3-1)
			weekVolume=$(bc -l <<<"(${initialVolume}+${interval}*(${i}-1))")
		;;
	esac
	echo "${weekVolume} ${shapeningPeriod}"
}
printTrainingPlan(){
	dateFormat="$(date +%d/%m/%Y -d ${weekDate})"
	
	echo -ne "S${i} [${colorMagenta}${dateFormat}${colorNormal}] Volume=${colorGreen}$(scaleNumber ${weekVolume} ${scaleNumber})${colorNormal} km" 
	echo -ne " - ${colorGreen}${runPerWeek}${colorNormal} runs/week"
	echo -ne " - Avg=${colorGreen}$(scaleNumber ${avgGlobalSingleRun} 2)${colorNormal} km"
	
	if ! [ -z ${longRun} ]; then 
		echo -ne " -- SL=${colorGreen}$(scaleNumber ${longRun} ${scaleNumber})${colorNormal} km"
		echo -ne " - Avg Sing.Run=${colorGreen}$(scaleNumber ${avgSingleRun} 2)${colorNormal} km"
	fi
	echo
}

# MAIN
# ------------------------------------------------------------------------------------------------------
controlRunFrequency

longRunPeriod=$((${numberOfWeekForTraining}-${longRunBefore}-${firstLongRun}+1))
volumePeriod=$((${numberOfWeekForTraining}-${#sharpening[@]}))

interval=$(bc -l <<<"(${volumeTarget}-${initialVolume})/(${volumePeriod}-1)")
intervalLongRun=$(bc -l <<<"(${longRunTarget}-${initialLongRun})/(${longRunPeriod}-1)")

# ----------------------------------
# Init var
# ----------------------------------
longRunCpt=0
weekDate=${beginningDate}
weekVolume=${initialVolume}
longRun=''

# ----------------------------------
# SUMMARY
# ----------------------------------
echo -e "${colorNormal}"
printLine
echo -e "${colorRed}SUMMARY${colorNormal}"
printLine
echo -e "* Your training plan will start on [${colorMagenta}$(date '+%d/%m/%Y' -d ${beginningDate})${colorNormal}] & stop on [${colorMagenta}$(date '+%d/%m/%Y' -d ${lastMondayDate})${colorNormal}] !"
echo -e "* Your training plan will last ${colorGreen}${numberOfWeekForTraining}${colorNormal} weeks."
echo
echo -e "* On your busiest week, you will run ${colorGreen}${volumeTarget}${colorNormal} km."
echo -e "* Your longest run will be ${colorGreen}${longRunTarget}${colorNormal}${colorNormal} km."
echo
#echo -e "* Each week you should add ~${colorGreen}$(scaleNumber ${interval} 2)${colorNormal} Km to your plan."
#echo -e "* Each long run you should add ~${colorGreen}$(scaleNumber ${intervalLongRun} 2)${colorNormal} kms." 
#echo
echo -e "* Increase period :"
echo -e "\tYou will increase your volume during ${colorGreen}${volumePeriod}${colorNormal} weeks : \
${initialVolume} Km to ${volumeTarget} Km (+ ~${colorGreen}$(scaleNumber ${interval} 2)${colorNormal} Km each week)."
echo -e "\tYou will increase your long run during ${colorGreen}${longRunPeriod}${colorNormal} weeks : \
${initialLongRun} Km to ${longRunTarget} (+ ~${colorGreen}$(scaleNumber ${intervalLongRun} 2)${colorNormal} Km each week)."
echo
echo -e "* Different training phase :"

for i in ${!runFrequency[@]}; do
	echo -e "\tP$((${i}+1))) ${colorGreen}$(echo ${runFrequency[${i}]} | cut -d';' -f1)${colorNormal} trainings per week during ${colorGreen}$(echo ${runFrequency[${i}]} |cut -d';' -f2)${colorNormal} weeks."
done
echo
# ----------------------------------
# TRAINING PLAN
# ----------------------------------
printLine
echo -e "${colorRed}TRAINING PLAN${colorNormal}"
printLine
for i in $(seq 1 ${numberOfWeekForTraining}); do
		echo "---------===> $(printVolume)"
		# ----------------------------------
		# Calculate ${runPerWeek}
		# ----------------------------------
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

		# ----------------------------------
		# Long run
		# ----------------------------------
		if [ ${i} -ge ${firstLongRun} ]; then
			longRun=$(bc -l <<<"(${initialLongRun}+(${longRunCpt}*${intervalLongRun}))")
			longRunCpt=$((longRunCpt+1))
		fi
		
		# ----------------------------------
		# Average single Run
		# ----------------------------------
		if [ ${i} -ge ${firstLongRun} ]; then
			avgSingleRun=$(bc -l <<<"((${weekVolume}-${longRun})/(${runPerWeek}-1))")
		fi
		
		# ----------------------------------
		# Average single Run without long Run
		# ----------------------------------
		avgGlobalSingleRun=$(bc -l <<<"(${weekVolume}/${runPerWeek})")
		
		# ----------------------------------
		# longRunBefore
		# ----------------------------------
		if [ ${i} -ge $((${longRunPeriod}+${firstLongRun})) ]; then
			longRun="${colorRed}off${colorNormal}"
		fi
		
		# ----------------------------------
		# Sharpening
		# ----------------------------------
		if [ ${i} -ge $((${volumePeriod}+1)) ]; then
			weekVolume='10'
		fi	
		
		# ----------------------------------
		# Correcting/ajust value
		# ----------------------------------
		case ${i} in
			$((${longRunPeriod}+${firstLongRun}-1)))
				longRun=${longRunTarget}
				;;
			${volumePeriod}) 
				weekVolume=${volumeTarget}
				;;
		esac

		# ----------------------------------
		# Print Training Plan
		# ----------------------------------
		printTrainingPlan	
		
		# ----------------------------------
		# Increase weekDate & weekVolume
		# ----------------------------------
		weekDate=$(date '+%Y%m%d' -d "${weekDate}+7 days")
		weekVolume=$(bc -l <<<"(${weekVolume}+${interval})")
done
