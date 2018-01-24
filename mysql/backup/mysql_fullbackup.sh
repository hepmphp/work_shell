#/bin/bash
#1）增量备份在周一到周六凌晨3点，会复制mysql-bin.00000*到指定目录；
#2）全量备份则使用mysqldump将所有的数据库导出，每周日凌晨3点执行，并会删除上周留下的mysq-bin.00000*，然后对mysql的备份操作会保留在bak.log文件中。
#Program
#use mysqldump to fully backup mysql data per week!
#History
#Path
bak_dir=/data/backup
log_file=/data/backup/bak.log
date=`date +%Y%m%d`
begin=`date +%Y-%m-%d %H:%M:%S`
cd $bak_dir
dump_file=$date.sql
gz_dump_file=$date.sql.tgz
