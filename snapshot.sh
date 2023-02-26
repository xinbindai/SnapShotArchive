#!/bin/bash

if [[ -z $4 ]];then
  echo "
This is a bash script that can space-efficient backup folder with snapshot

Usage:   
         snapshot.sh <source-path> <dest-path> <max-count> <hourly|daily|weekly|monthly|yearly> [rsync-include-exclude-path]

Example: 
         snapshot.sh root@www.myweb.org:/home/ /backup/myweb/home/ 31 daily   '--exclude=/tmp/ --exclude=/etc/'

         snapshot.sh root@www.myweb.org:/ /backup/myweb/ 15 bidaily '--include /home --include /var --include /etc --include /root --exclude /\* --exclude /var/log'
         * the above case will only backup home,var,etc and root folder and exclude all of others

Author: Xinbin Dai

Last modification date: Mar/6/2012.
"

  exit 1
fi

#-----------------------initializing-------------------------------------------
sourcepath=`echo -n $1|sed -r 's/\/+$//'`
destpath=`echo -n $2|sed -r 's/\/+$//'`
maxcount=$3
prefix=$4

if [[ $destpath =~ "@" ]];then
  echo "Destination side (${destpath}) is supposed to be local drive";
  exit 1
fi

if [[ -z `echo $maxcount|egrep '^[0-9]+$'` || $maxcount -le 3 ]];then
  echo "max-count should be integer and larger than or equal to 3"
  exit 1
fi

if [[ ! -e $destpath ]];then
  mkdir -p $destpath  
  if [[ $? -ne 0 ]];then 
     echo "Failed to create ${destpath}, abort!"
     exit 1
  fi
fi

destpathprefix=${destpath}/${prefix}


#---------------------if no .lock file, do circling of backup folders-----------------------
if [[ ! -e ${destpathprefix}.lock && ! -f  ${destpathprefix}.0 ]];then
 
  rm -rf ${destpathprefix}.$((maxcount-1)) 
  if [[ $? -ne 0 ]];then 
     echo "Failed to remove ${destpathprefix}.$((maxcount-1)), abort!"
     exit 1
  fi
  
  for ((i=$((maxcount-1)); i>0; i--));do 
     if [[ -e ${destpathprefix}.$((i-1)) && -d ${destpathprefix}.$((i-1)) && ! -e ${destpathprefix}.$i ]];then
        mv ${destpathprefix}.$((i-1)) ${destpathprefix}.$i
     elif [[ -e ${destpathprefix}.$((i-1)) && ! -d ${destpathprefix}.$((i-1)) ]];then
        echo "Warning: ${destpathprefix}.$((i-1)) is not folder, delete it!"
        rm -rf ${destpathprefix}.$((i-1))
     elif [[ -e ${destpathprefix}.$i ]];then
        echo "Error: ${destpathprefix}.$i exists, exit!"
        exit 1
     fi
  done

else
  if [[ -f ${destpathprefix}.0  ]];then rm -rf ${destpathprefix}.0;fi
  echo "Found .lock file or freak ${destpathprefix}.0 folder, the backup operation might be failed last time. Resuming......"
fi


#-----------------Prepare command line-----------------------------------------------
if [[ -e ${destpathprefix}.1 ]];then linkdest="--link-dest=${destpathprefix}.1";else linkdest="";fi
cmd="rsync -aHzv --delete $5 ${linkdest} ${sourcepath}/  ${destpathprefix}.0/"
echo "Run the following command:"
echo $cmd

#-----------------Call Rsync To Backup Your Data-------------------------------------
touch ${destpathprefix}.lock
bash -c "$cmd"  ||  bash -c "$cmd" || bash -c "$cmd"
retcode=$?
touch ${destpathprefix}.0
if [[ $retcode -ne 0 ]];then
  touch ${destpathprefix}.lock
  echo "rsync failed, script abort and will resume transfer when it is called with the same command again."
  exit 1
fi
rm -f ${destpathprefix}.lock


