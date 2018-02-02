#!/bin/bash
#Program
#use cp to backup mysql data everyday!
#History
#Path

bak_dir=/data/backup/mysql/daily/ #backup dir  
bin_dir=/data/mysql/ #binlog dir
log_file=/data/backup/dailybackup.log #back log file
bin_file=/data/mysql/bin.index  #binlog index
/usr/local/mysql/bin/mysql -u root -pHe -e  "flush logs"

if [ ! -d "$bak_dir" ]; then
   mkdir $bak_dir	
fi

echo `date +"%Y-%m-%d %H:%M:%S"` daily backup begin >> $log_file
counter=`wc -l $bin_file|awk '{print $1}'`
next_num=0
for file in `cat $bin_file`
do
    base=`basename $file`  #basename用于截取mysql-bin.00000*文件名，去掉./mysql-bin.000005前面的./
    next_num=`expr $next_num + 1`
    if [ $next_num -eq $counter ]; then
        echo $base skip! >> $log_file
    else
        dest=$bak_dir$base

        if(test -e $dest) 
 	then
            echo `date +"%Y-%m-%d %H:%M:%S"` $base exist! >> $log_file
        else
            cp $bin_dir$base $bak_dir
            echo `date +"%Y-%m-%d %H:%M:%S"` $base copying >> $log_file
        fi
    fi
done
echo `date +"%Y-%m-%d %H:%M:%S"` daily backup success! >> $log_file
