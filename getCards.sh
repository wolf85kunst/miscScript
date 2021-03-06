#!/bin/bash
# Hugo GUTEKUNST - november 2019
# Extract OTGN images pack from sda.builder.fr and convert to pictures library

# SETTINGS
# ------------------------------------------------------------------
srcUrl='https://sda.cgbuilder.fr/pack_octgn/'
workDir='sdajce2'
destDir="/home/${USER}/Images/${workDir}"
destArchives="/tmp/${workDir}"
curlOutput='/tmp/sdajce.html'

maxThread=10

colorRed="\e[31m"
colorGreen="\e[92m"
colorNormal="\e[0m"

# FUNCTIONS
# ------------------------------------------------------------------
threadLimit(){
	running=$(jobs -rp |wc -l)
	while [ ${running} -ge ${1} ]; do
		sleep 1
		running=$(jobs -rp |wc -l)
	done
}
downloadArchive(){
	packageName=$(echo "${1}" |grep -o '[a-zA-Z_]*.o8c')
	startTime=$(date +%s)
	wget -q ${1} -P ${destArchives} && status=$?
	endTime=$(date +%s)
	totalTime=$((endTime-startTime))
	if [ "${status}" -eq 0 ]; then
		echo -e " - ${packageName} downloaded in ${totalTime} secs. [${colorGreen} Done ${colorNormal}]"
	else
		echo -e " - ${packageName} [${colorRed} Failed ${colorNormal}]"
	fi
}

# MAIN
# ------------------------------------------------------------------
mkdir -p ${destArchives}
mkdir -p ${destDir}

curl -so "${curlOutput}" "${srcUrl}"
packagesList=$(cat ${curlOutput} |grep -io "href=\"https://[a-z._:/-]*/ressources/octgn/[a-z_]*.o8c\"" |sed -e 's/href="//;s/"//g')
packagesNb=$(echo "${packagesList}" |wc -l)

cpt=1
echo "---> Downloading octgn pack from ${srcUrl} (${packagesNb} found)"
startTime=$(date +%s)
while read url; do
	threadLimit ${maxThread}
	downloadArchive "${url}" &
	cpt=$((cpt+1))
done < <(echo "${packagesList}")
endTime=$(date +%s) ; totalTime=$((endTime-startTime))
wait
echo
echo "> Finished in ${totalTime} secs."
echo
while read archive; do
	listCard=$(unzip -Z1 "${destArchives}/${archive}" |grep '.jpg$')
	listCardNb=$(echo "${listCard}" |wc -l)
	folderCardName=$(echo ${archive} |sed 's/.o8c//')
	echo "---> Unzip ${archive} to ${destDir}/${folderCardName}"
	
	mkdir -p ${destDir}/${folderCardName}

	cpt=1
	while read card ; do
		basenameCard="$(basename ${card})"
		cleanNameCard="${folderCardName}_${cpt}.jpg"
		unzip -q -j ${destArchives}/${archive} "${card}" -d "${destDir}/${folderCardName}/" && \
		mv "${destDir}/${folderCardName}/${basenameCard}" "${destDir}/${folderCardName}/${cleanNameCard}" ; status="$?"
		if [ "${status}" -eq 0 ]; then
			echo -e "  [${cpt}/${listCardNb}] ${basenameCard} unziped to ${destDir}/${folderCardName}/${cleanNameCard} ${colorGreen}[ DONE ]${colorNormal}"
		else
			echo -e "  [${cpt}/${listCardNb}] ${basenameCard} fail. ${colorRed}[ ERROR ]${colorNormal}"
		fi
		cpt=$((cpt+1))
	done < <(echo "${listCard}")
done < <(ls -1 "${destArchives}")
echo
echo "> OCTGN packages has been successfully extracted to ${destDir}. Enjoy !"

rm -rf ${curlOutput}
rm -rf ${destArchives}
