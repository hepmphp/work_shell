#!/bin/bash

chown www:www $1;

if [ -d $1 ];then
    chmod 750 $1;
else
    chmod 750 $1;
fi

_SDKADMIN="/data/htdocs/sdkadmin"
cd ${_SDKADMIN}

for i in `cat syncfile.list`
do
    if [ "`echo "$1" |grep "${_SDKADMIN}/${i}"|wc -l`" == "1" ];then
        
        _RSYNC_FILE="$(echo "$1" |grep -E -o ${i})"
        rsync -avz --bwlimit=500 -R "./${_RSYNC_FILE}" user@ip::sdkadmin --password-file=/etc/rsync.pass

    fi
done 

echo -e `date +"%Y-%m-%d %H:%M:%S"`"\t"$1 >> /var/log/chmod.log
