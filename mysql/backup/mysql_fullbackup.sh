#!/bin/bash
#1）增量备份在周一到周六凌晨3点，会复制mysql-bin.00000*到指定目录；
#2）全量备份则使用mysqldump将所有的数据库导出，每周日凌晨3点执行，并会删除上周留下的mysq-bin.00000*，然后对mysql的备份操作会保留在bak.log文件中。
#Program
#use mysqldump to fully backup mysql data per week!
#History
#Path
#db account
username=root
password=He
db_names="test  wiki" #备份多个数据库
ip=localhost

#db dir
bak_dir=/data/backup/mysql/
log_file=/data/backup/mysql/mysql_fullbackup.log
date=`date +%Y%m%d`


cd $bak_dir
dump_file=$date.sql
gz_dump_file=$date.sql.tgz
for dbname in $db_names
do
     :
    begin=`date +'%Y-%m-%d %H:%M:%S'`
    db_bak_dir=$bak_dir$dbname 
    if [ ! -d "$db_bak_dir" ]; then
      mkdir "$db_bak_dir"
    fi
    #-B：指定数据库
    #-F：刷新日志
    #-R：备份存储过程等
    #-x：锁表
    #--set-gtid-purged 关闭gtid功能
    #--master-data：在备份语句里添加CHANGE MASTER语句以及binlog文件及位置点信息
    /usr/bin/mysqldump -u$username -p$password -h$ip -B -F -R -x --set-gtid-purged=OFF  --master-data=2 $dbname|gzip >$db_bak_dir/$(date +%F).sql.gz

    end=`date +'%Y-%m-%d %H:%M:%S'`

    if [ "$?" == "0" ] 
    then
        echo "$dbname begin"$begin "end:"$end mysqldump success >> $log_file
    else
        echo "$dbname begin"$begin "end:"$end mysqldump fail >> $log_file
        exit 0
    fi
done
