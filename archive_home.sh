#!/bin/bash
# Hugo GUTEKUNST

# DESCRIPTION
# ----------------------------------------------------------
# Backup your work directory and upload it to save it.
# you need to install "xz-utils" package to compress archive.

# GLOBAL SETTINGS
# ----------------------------------------------------------
companyTag='myCompany'
backupDir="/home/${USER}/Save/"
workDir="/home/${USER}"
DirToBackup='Bureau/ Documents/ .ssh/ .gnupg/ .bashrc .ansible.cfg .conkyrc dpkg.list'
DirToExclude="Documents/sysadmin/*"
logPath="$HOME/backupHome.log"
ArchiveName="$(date +%Y%m%d-%H%M%S)_home_${companyTag}.xz"

# BACKUP SERVER SETTINGS
# ----------------------------------------------------------
remotePort='22'
remoteUser='root'
remoteAddress='x.x.x.x'
remotePath='/home/hugo/'

# FUNCTIONS
# ----------------------------------------------------------
logprint()
{
        format_date="[$(date "+%Y%m%d %H:%M")]"
        echo "${format_date} - $1" >> ${logPath}
}
chrono()
{
        case $1 in
        'start') start_time=`date +%s` ;;
        'total') end_time=`date +%s` ; total_time=$((end_time-start_time));;
        esac
}
upload()
{
	logprint "Uploading to ${remoteAddress}..."
	chrono start
	scp -P ${remotePort} "${backupDir}/${ArchiveName}" ${remoteUser}@${remoteAddress}:${remotePath}
	chrono total
	logprint "Uploaded to ${remoteAddress} in ${total_time} secs."
}
buildFilesToBackup() {
	dpkg -l > /tmp/dpkg.list
}

# MAIN
# ----------------------------------------------------------
logprint 'Starting backup...'
mkdir -p ${backupDir}
CurrentPath=$(pwd)

chrono start
cd $workDir
tar -Jvcf "${backupDir}/${ArchiveName}" --exclude "${DirToExclude}" ${DirToBackup}
ArchiveSize=$(du -sh "${backupDir}/${ArchiveName}" | awk '{print $1}')
chrono total && logprint "Backup done with sucess -> "${backupDir}/${ArchiveName}" - ${ArchiveSize} (${total_time} secs)."

# upload to backup server if needed
upload

cd ${CurrentPath}
