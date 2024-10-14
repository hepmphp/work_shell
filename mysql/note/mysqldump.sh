#开发常用操作
#1ִ备份数据
/usr/local/mysql/bin/mysqldump -u root -p123456 -h localhost wiki | gzip>/data/backup/wiki.sql.gz

#2.导出结构不导出数据
/usr/local/mysql/bin/mysqldump -h localhost -u root -p123456  --no-data wiki >/data/backup/wiki.table.sql

#3.导出数据不导出结构
/usr/local/mysql/bin/mysqldump -h localhost -u root -p123456   --no-create-info wiki >/data/backup/wiki.data.sql

#4.还原
gunzip wiki.sql.gz
/usr/local/mysql/bin/mysql -uroot -p123456 -h192.168.1.3 wiki< wiki.sql
source wiki.sql