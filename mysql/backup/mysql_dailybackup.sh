#!/bin/bash
#Program
#use cp to backup mysql data everyday!
#History
#Path

bak_dir=/data/backup/daily
bin_dir=/data/mysql/data
log_file=/data/backup/daily.log
bin_file=/data/mysql/bin.index
/use/local/mysql/bin/mysqladmin -uroot -p123456 flush logs

counter=`wc -l $bin_file|awk '{print $1}'`
next_num=0
for file in `cat $bin_file`
do
    base=`basename $file`  #basename用于截取mysql-bin.00000*文件名，去掉./mysql-bin.000005前面的./
    next_num=`expr $next_num+1`
    if [ $next_num -eq $counter]
        echo $base skip! >> $log_file
    then
        dest=$bak_dir/$base
        if(test -e $dest)
            echo $base exist! >> $log_file
        then
            cp $bin_dir/$base $bak_dir
            echo $base copying >> $log_file
        fi
    fi
done
echo `date +"%Y-%m-%d %H:%M:%S" daily backup success!` >> $log_file
