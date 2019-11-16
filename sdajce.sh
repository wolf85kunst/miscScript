#!/bin/bash
# Hugo GUTEKUNST

# Description
# -----------------------------------------------------------
# OCTGN Images Pack Converter
# Created by Hugo GUTEKUNST 2019
# tested on full archive got here : https://onedrive.live.com/?authkey=%21AK2mGg3JAz51FJY&id=790DD05B99D7DC86%2186761&cid=790DD05B99D7DC86

# Settings
# -----------------------------------------------------------
if [ -z "${1}" ]; then src='/home/hugo/Téléchargements/OTGN/OneDrive-2019-11-13.zip' ; else src="${1}" ; fi
targetDir="/home/$USER/Images/sdajce"
unzipDir='/tmp/sdajce'

# Choose extraction mode
#    - list : all images cards are extracted in the same folder
#    - byfolder : all different o8c package are extracted in separte folder
extractionMode='byfolder'

colorRed="\e[31m"
colorGreen="\e[92m"
colorNormal="\e[0m"
colorBackgroundBlue="\e[44m"

# Main
# -----------------------------------------------------------
rm -rf ${unzipDir}
mkdir -p "${targetDir}"
mkdir -p "${unzipDir}"
globalCpt=0

# Unzip archive
unzip "${src}" -d "${unzipDir}"

while read line; do
	archiveName=$(basename "${line}")
	archiveName=$(echo "${archiveName}" |iconv -f utf8 -t ascii//TRANSLIT//IGNORE) #Purge accents from archiveName
	echo -e "${colorBackgroundBlue}Current Archive : ${archiveName}${colorNormal}"
	cpt=1
	listCard=$(unzip -Z1 "${line}" |grep '.jpg$')
	nbCard=$(echo "${listCard}" | wc -l)
	while read card; do
		cardName=$(basename "${card}")
		finaleCardName="$(echo ${archiveName}|sed 's/ /_/g' |sed 's/.o8c$//')_${cpt}.jpg"
		
		case "${extractionMode}" in
		'list') 
			unzip -q -j "${line}" "${card}" -d "${targetDir}" && \
			mv "${targetDir}/${cardName}" "${targetDir}/${finaleCardName}" ; status="$?" ;;
		'byfolder') 
			cardsFolder="$(echo ${archiveName} |sed 's/.o8c$//')"
			mkdir -p "${targetDir}/${cardFolder}"
			unzip -q -j "${line}" "${card}" -d "${targetDir}/${cardsFolder}" && \
			mv "${targetDir}/${cardsFolder}/${cardName}" "${targetDir}/${cardsFolder}/${finaleCardName}" ; status="$?" ;;
		*) echo '--> Incorrect value for "${extractionMode}" param. Please read documentation ! Exit' && exit 1;;
		esac

		if [ "${status}" == 0 ]; then
			echo -e "\t* [${cpt}/${nbCard}] ${cardName} saved as ${finaleCardName} [ ${colorGreen}OK${colorNormal} ]"
		else 
			echo -e "\t* [${cpt}/${nbCard}] ${cardName} saved as ${finaleCardName} [ ${colorRed}ERROR${colorNormal} ]"
		fi
		
		cpt=$((cpt+1))
		globalCpt=$((globalCpt+1))
	done < <(echo "${listCard}")
done < <(ls -1 "${unzipDir}/"*.o8c)
echo -e "\n--> ${globalCpt} files extracred successfully to ${targetDir}."
rm -r ${unzipDir}
