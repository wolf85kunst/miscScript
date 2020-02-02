#!/bin/bash
# Hugo GUTEKUNST 2020

# DESCRIPTION
# ------------------------------------------------------------------------------------------------------
# Training plan generator
# This script generates a customized training plan for half-marathon and marathon

# SETINGS
# ------------------------------------------------------------------------------------------------------
# Global training setings
beginningDate='20200101'	# Date of the first monday of the training plan
competitionDate='29/03/2020'	# Date of the half-marathon or marathon
lastMondayDate='20200324'	# Date of the last week of the training plan
numberOfWeekForTraining=20	# Number of weeks for the training plan

declare -a runFrequency		# Running frequency per week (time to go)
				# Declaration syntax : "Number of runs per week ; Number of weeks ; comment"
				# If Number of week is "-" on runFrequency[0] then the number of weeks of each different runFrequency is equal
runFrequency[0]='3;-;3 trainings per week'
runFrequency[1]='4;3;4 trainings per week'
runFrequency[2]='5;2;5 trainings per week'

# Running volume
initialVolume=30		# Initial running volume (KM)
volumeTarget=70			# The maximum running volume desired in a week (KM)

# Long Run
firstLongRun=7			# week number of the first long run (week number)
initialLongRun=10		# The first long run in kilometer (KM)
longRunTarget=30 		# The longest run desired in the training plan (KM)

# Volume reduction
scaleBackP1=50			# The first phase of volume reduction (percentage)
scaleBackP2=10			# The second phase of volume reduction (percentage)

# Global settings
scaleNumber=0			# Precision of float number on display

# FUNCTIONS
# ------------------------------------------------------------------------------------------------------
scaleNumber(){
	# Arg3 = float
	# Arg2 = scale
	float=${1}
	scale=${2}
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
printTrainingPlan(){
	dateFormat="$(date +%d/%m/%Y -d ${weekDate})"
	
	echo -n "S${i} [${dateFormat}] Volume=$(scaleNumber ${weekVolume} ${scaleNumber}) km" 
	echo -n " - ${runPerWeek} runs/week"
	echo -n " - Avg=$(scaleNumber ${avgGlobalSingleRun} ${scaleNumber}) km"
	
	if ! [ -z ${longRun} ]; then 
		echo -n " -- SL=$(scaleNumber ${longRun} ${scaleNumber}) km"
		echo -n " - Avg Sing.Run=$(scaleNumber ${avgSingleRun} ${scaleNumber}) km"
	fi
	echo
}

# MAIN
# ------------------------------------------------------------------------------------------------------
controlRunFrequency
# echo ${runFrequency[@]}

interval=$(bc -l <<<"(${volumeTarget}-${initialVolume})/(${numberOfWeekForTraining}-1)")
intervalLongRun=$(bc -l <<<"((${longRunTarget}-${initialLongRun}))/(${numberOfWeekForTraining}-${firstLongRun}+1)")

# ----------------------------------
# Init var
# ----------------------------------
longRunCpt=0
weekDate=${beginningDate}
weekVolume=${initialVolume}
longRun=''

echo 'SUMMARY'
echo '----------------'
echo "* Your training plan will start on \"$(date '+%d/%m/%Y' -d ${beginningDate})\" and stop on \"$(date '+%d/%m/%Y' -d ${lastMondayDate})\" !"
echo "* Your training plan will last ${numberOfWeekForTraining} weeks."
echo "* On your busiest week, you will run ${volumeTarget} km."
echo "* Your longest run will be ${longRunTarget} km."
echo "* Each week you should add ~$(scaleNumber ${interval} 2) Km to your plan."
echo "* For each long run you should add ~$(scaleNumber ${intervalLongRun} 2) kms." 
echo "* Different training phase :"

for i in ${!runFrequency[@]}; do
	echo -e "\tP$((${i}+1))) $(echo ${runFrequency[${i}]} | cut -d';' -f1) trainings per week during $(echo ${runFrequency[${i}]} |cut -d';' -f2) weeks."
done
echo

echo 'TRAINING PLAN'
echo '----------------'
for i in $(seq 1 ${numberOfWeekForTraining}); do
	
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
			#longRun=$(bc -l <<<"(${initialLongRun}*(${longRunCpt})*${intervalLongRun})")
			longRun=$(bc -l <<<"(${initialLongRun}+(${longRunCpt})*${intervalLongRun})")
			longRunCpt=$((longRunCpt+1))
			#echo "-------> ${longRunCpt}"
		fi
		
		# ----------------------------------
		# Correcting value
		# ----------------------------------
		#case ${i} in
		#	1) 
		#		weekVolume=${initialVolume}
		#		;;
		#	${initialLongRun})
		#		longRun=${initialLongRun}
		#		;;
		#	${numberOfWeekForTraining}) 
		#		#weekVolume=${volumeTarget}
		#		longRun=${longRunTarget}
		#		;;
		#esac
		
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
		#echo "ooo> $avgGlobalSingleRun"
	
		printTrainingPlan	
		
		weekDate=$(date '+%Y%m%d' -d "${weekDate}+7 days")
		weekVolume=$(bc -l <<<"(${weekVolume}+${interval})")
done
