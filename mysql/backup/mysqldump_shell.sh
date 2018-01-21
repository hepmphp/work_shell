#备份脚本范例。优先考虑在从库部署备份脚本，先slave stop，备份结束后，再slave start
#!/bin/sh
#设置用户、密码和数据库名
username=root
password=123456
dbname=db
hostip=localhost

#指定时间日期和备份目录
backupdir=/data/mysqlbackup/$dbname`date +%Y-%m-%d_%H%M%S`.sql.gz
#LogFile=/data/mysqlbackup/backup.log
LogFile=/data/mysqlbackup/backlog/baklog`date +%Y-%m-%d_%H%M%S`.log

echo "-------------------------------------------" >> $LogFile
echo " " >> $LogFile
/usr/local/mysql/bin/mysql -u$username -p$password -h$hostip $dbname -e"SHOW MASTER STATUS;" >>$LogFile

#开始备份数据库
/usr/local/mysql/bin/mysqldump -u$username -p$password -hlocalhost $dbname -e --max_allowed_packet=10485760 --net_buffer_length=163840 | gzip>$backupdir


echo " " >> $LogFile
/usr/local/mysql/bin/mysql -u$username -p$password -h$hostip $dbname -e"SHOW MASTER STATUS;" >>$LogFile

#删除七天前备份
find /data/mysqlbackup -mtime +7 -name "*.sql.gz" -exec rm -rf {} \;

#todo自动同步到云盘或者其他服务器