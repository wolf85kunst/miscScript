#!/bin/bash
#cat /tmp/sdajce.html |grep -io "<h3>[ a-z0-9':_āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ]*</h3>"

# SETTINGS
# ------------------------------------------------------------------
srcUrl='https://sda.cgbuilder.fr/pack_octgn/'
destDownload='/tmp/sdajce/'
tempDir='/tmp/sdajce.html'

colorRed="\e[31m"
colorGreen="\e[92m"
colorNormal="\e[0m"

# MAIN
# ------------------------------------------------------------------
curl -so "${tempDir}" "${srcUrl}"
packagesList=$(cat /tmp/sdajce.html |grep -io "href=\"https[a-z._:/-]*/ressources/octgn/[a-z_]*.o8c\"" |sort)
packagesNb=$(echo "${packagesList}" |wc -l)
mkdir -p ${destDownload}
#echo $packagesNb ; exit
cpt=1
while read url; do
	packageName=$(echo "${url}" |grep -o '[a-zA-Z_]*.o8c')
	url=$(echo ${url} |sed -e 's/href="//;s/"//g' )
	startTime=$(date +%s)
	wget -q ${url} -P ${destDownload} && status="$?"
	endTime=$(date +%s)
	totalTime=$((endTime-startTime))
	if [ ${status} -eq 0 ]; then
		echo -e "[${cpt}/${packagesNb}] - ${packageName} downloaded in ${totalTime} secs. [${colorGreen} Done ${colorNormal}]"
	else
		echo -e "[${cpt}/${packagesNb}] - ${packageName} [${colorRed} Failed ${colorNormal}]"
	fi
	cpt=$((cpt+1))
done < <(echo "${packagesList}")

