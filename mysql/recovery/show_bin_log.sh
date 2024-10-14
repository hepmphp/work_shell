#1.查看binlog里头的sql
mysqlbinlog /data/mysql/bin.000009  -v

mysqlbinlog /data/mysql/bin.000009  -v --base64-output=decode-rows

#2.mysql备份

#-B：指定数据库
#-F：刷新日志
#-R：备份存储过程等
#-x：锁表
#--set-gtid-purged 关闭gtid功能
#--master-data：在备份语句里添加CHANGE MASTER语句以及binlog文件及位置点信息
/usr/bin/mysqldump -uroot -pHe -B -F -R -x --set-gtid-purged=OFF  --master-data=2 test|gzip >/data/backup/test_$(date +%F).sql.gz


/usr/local/mysql/bin/mysql -u root -pHe -e "show master status";
/usr/local/mysql/bin/mysql -u root -pHe -e  "show binlog events in 'mysql-bin.000003'";

#3.根据binlog恢复
#恢复思路 筛选过滤要恢复的区间 重新导入执行
mysqlbinlog bin.000003 --start-position=1029 --stop-position=1592 --skip-gtids=true|/usr/local/mysql/bin/mysql -u root -pHe -v

错误记录:

#rest master
错误 ERROR 1840 (HY000) at line 24: @@GLOBAL.GTID_PURGED can only be set when @@GLOBAL.GTID_EXECUTED is empty.
解决 编辑sql注释掉这行@@GLOBAL.GTID_PURGED

/usr/local/mysql/bin/mysql -u root -pHe199033028 -v </data/backup/test_2018-01-24.sql

#从开启GTID功能的库同步数据到未开启GTID功能库时，注意事项！
从开启GTID的库中导出数据到未开启GTID的库中，需要注意，在导出的文件中去掉相应的gtid内容，否则导入时会报错如下：
#ERROR 1839 (HY000) at line 24 in file: '/root/db_hdf_bqjfl_xxxx_xx_xx.sql': @@GLOBAL.GTID_PURGED can only be set when @@GLOBAL.GTID_MODE = ON.
1、mysqldump导出数据时候需要加参数 --set-gtid-purged=OFF
 ERROR 1781 (HY000): @@SESSION.GTID_NEXT cannot be set to UUID:NUMBER when @@GLOBAL.GTID_MODE = OFF.
2.导出的增量日志需要去掉GTID
sed -i 's/SET @@SESSION.GTID_NEXT/#SET @@SESSION.GTID_NEXT/g' mysql-bin.000547_binlog.sql



