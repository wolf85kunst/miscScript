#!/bin/bash
# Hugo GUTEKUNST

# DESCRIPTION
# ----------------------------------------------------------
# Backup your work directory and upload it to a backup server
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
logprint() {
        format_date="[$(date "+%Y%m%d %H:%M")]"
        echo "${format_date} - $1" >> ${logPath}
}
chrono() {
        case $1 in
        'start') start_time=`date +%s` ;;
        'total') end_time=`date +%s` ; total_time=$((end_time-start_time));;
        esac
}
upload() {
	scp -P ${remotePort} "${backupDir}/${ArchiveName}" ${remoteUser}@${remoteAddress}:${remotePath}
}
buildFilesToBackup() {
	dpkg -l > /tmp/dpkg.list
}

# MAIN
# ----------------------------------------------------------
logprint 'Starting backup...'
chrono start
mkdir -p ${backupDir}
buildFilesToBackup
CurrentPath=$(pwd)

# Create archive
cd $workDir
tar -Jvcf "${backupDir}/${ArchiveName}" --exclude "${DirToExclude}" ${DirToBackup}
ArchiveSize=$(du -sh "${backupDir}/${ArchiveName}" | awk '{print $1}')
chrono total
logprint "Backup done with sucess -> "${backupDir}/${ArchiveName}" - ${ArchiveSize} (${total_time} secs)."

# Upload archive to backup server
logprint "Uploading to ${remoteAddress}..."
chrono start
upload
chrono total
logprint "Uploaded to ${remoteAddress} in ${total_time} secs."

# Return to current dir
cd ${CurrentPath}
