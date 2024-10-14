#!/bin/bash
#卸载系统自带的Mysql
/bin/rpm -e $(/bin/rpm -qa | grep mysql|xargs) --nodeps
/bin/rm -f /etc/my.cnf
  
#安装编译代码需要的包
yum -y install bison gcc gcc-c++  autoconf automake zlib* libxml* ncurses-devel libtool-ltdl-devel* make cmake

#编译安装mysql5.6
/usr/sbin/groupadd mysql
/usr/sbin/useradd -g mysql mysql -M -s /sbin/nologin -d /dev/null  -u2002
  
cd /usr/local/src
wget -c http://ftp.ntu.edu.tw/MySQL/Downloads/MySQL-5.7/mysql-5.7.20.tar.gz
/bin/tar -zxvf mysql-5.7.20.tar.gz
cd mysql-5.7.20/
/usr/bin/cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/data/mysql/data -DSYSCONFDIR=/etc/ -DDOWNLOAD_BOOST=1 -DWITH_BOOST=/usr/local/boost
make && make install
  
#修改/usr/local/mysql权限
mkdir -p /data/mysql/data
/bin/chown -R mysql:mysql /usr/local/mysql
/bin/chown -R mysql:mysql /data/mysql/data
  
#执行初始化配置脚本，创建系统自带的数据库和表  
mysqld --initialize --user=mysql --basedir=/usr/local/mysql/ --datadir=/data/mysql/data

mkdir -p /data/mysql/data/redolog/   && /bin/chown -R mysql:mysql /data/mysql/data
#配置my.cnf
cat > /etc/my.cnf << EOF
[client]
user=mysql
password=123456
port = 3306
socket = /usr/local/mysql/var/mysql.sock
[mysqld]
########basic settings########
server-id = 11               #服务器id
port = 3306                  #端口
socket = /usr/local/mysql/var/mysql.sock
user = mysql                 #用户
bind_address = 0.0.0.0       #监听的地址
autocommit = 1               #设置autocommit=0，则用户将一直处于某个事务中，直到执行一条commit提交或rollback语句才会结束当前事务重新开始一个新的事务。set autocommit=0的好处是在频繁开启事务的场景下，减少一次begin的交互。
character_set_server=utf8mb4 #采用utf8mb4编码的好处是：存储与获取数据的时候，不用再考虑表情字符的编码与解码问题。
skip_name_resolve = 1        #禁止DNS解析
max_connections = 800        #设置最大连接（用户）数   
max_connect_errors = 1000    #是一个MySQL中与安全有关的计数器值，它负责阻止过多尝试失败的客户端以防止暴力破解密码的情况   
basedir = /usr/local/mysql/  #mysql目录
datadir = /data/mysql/data   #mysql数据存放路径
pid-file = /data/mysql/data/mysql.pid
transaction_isolation = READ-COMMITTED #设定默认的事务隔离级别.可用的级别如下:1.READ UNCOMMITTED-读未提交2.READ COMMITTE-读已提交3.REPEATABLE READ -可重复读4.SERIALIZABLE -串行
explicit_defaults_for_timestamp = 1 #timestamp数据类型
join_buffer_size = 512M   #连表缓存大小
tmp_table_size = 256M     #临时表大小
tmpdir = /tmp
max_allowed_packet = 16777216 #允许的数据包大小 会影响大数据写入或者更新失败 
sql_mode = "STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER" #取消严格模式
interactive_timeout = 1800      #服务器关闭交互式连接前等待活动的秒数
wait_timeout = 1800             #超时时间
read_buffer_size = 512M     #为需要全表扫描的MYISAM数据表线程指定缓存
read_rnd_buffer_size = 512M #该变量可以被任何存储引擎使用，当从一个已经排序的键值表中读取行时，会先从该缓冲区中获取而不再从磁盘上获取
sort_buffer_size = 512M     #sort buffer是系统中对数据进行排序的时候用到的Buffer
########log settings########
log_error = error.log                 #mysql错误日志           
slow_query_log = 1                    #是否启用慢查询日志，1为启用，0为禁用   
slow_query_log_file = slow.log        #指定慢查询日志文件的路径和名字，可使用绝对路径指定；默认值是'主机名_slow.log'，位于datadir目录  
log_queries_not_using_indexes = 1     #如果运行的SQL语句没有使用索引，则MySQL数据库同样会将这条SQL语句记录到慢查询日志文件  
#log_slow_admin_statements = 1         #记录执行缓慢的管理SQL，如alter table,analyze table, check table, create index, drop index, optimize table, repair table等。    
#log_slow_slave_statements = 1         #记录从库上执行的慢查询语句  
log_throttle_queries_not_using_indexes = 10 #设定每分钟记录到日志的未使用索引的语句数目，超过这个数目后只记录语句数量和花费的总时间
expire_logs_days = 90                       #控制binlog日志文件保留时间
long_query_time = 1                         #记录超过1秒的SQL执行语句
min_examined_row_limit = 100                #查询检查返回少于该参数指定行的SQL不被记录到慢查询日志
########replication settings########
master_info_repository = TABLE            #可以利用如下SQL查询主从同步的信息 select * from mysql.slave_master_info;
relay_log_info_repository = TABLE         #select * from mysql.slave_relay_log_info; 
log_bin = bin.log                         #生成的bin-log的文件名
sync_binlog = 1                           #mysql同步把二进制日志和事务日志这两个文件刷新到两个不同的位置
gtid_mode = on                            #开启GTID
enforce_gtid_consistency = 1              #开启GTID
log_slave_updates                         #开启GTID  
binlog_format = row                       #binlog日志格式  
relay_log = relay.log                     #定义relay_log的位置和名称，如果值为空，则默认位置在数据文件的目录，文件名为host_name-relay-bin.nnnnnn
relay_log_recovery = 1                    #当slave从库宕机后，假如relay-log损坏了，导致一部分中继日志没有处理，则自动放弃所有未执行的relay-log，并且重新从master上获取日志，这样就保证了relay-log的完整性。默认情况下该功能是关闭的，将relay_log_recovery的值设置为 1时，可在slave从库上开启该功能，建议开启。 
binlog_gtid_simple_recovery = 1           #默认开启简化的GTID 恢复  
slave_skip_errors = ddl_exist_errors      #此参数主要用于从库，在主从复制时，一些没必要的错误可以忽略，不影响复制  
########innodb settings########
innodb_page_size = 16384                 #这个参数在一开始初始化时就要加入my.cnf里，如果已经创建了表，再修改，启动MySQL会报错。最好为16384
innodb_buffer_pool_size = 500M          #数据缓冲区buffer pool大小，建议使用物理内存的 75%
innodb_buffer_pool_instances = 8        #当buffer_pool的值较大的时候为1，较小的设置为8
innodb_buffer_pool_load_at_startup = 1  #运行时load缓冲池，快速预热缓冲池，将buffer pool的内容（文件页的索引）dump到文件中，然后快速load到buffer pool中。避免了数据库的预热过程，提高了应用访问的性能
innodb_buffer_pool_dump_at_shutdown = 1 #运行时dump缓冲池
innodb_lru_scan_depth = 2000            #在innodb中处理用户查询后，其结果在内存空间的缓冲池已经发生变化，但是还未记录到磁盘。这种页面称为脏页，将脏页记录到磁盘的过程称为刷脏
innodb_lock_wait_timeout = 5            #事务等待获取资源等待的最长时间，超过这个时间还未分配到资源则会返回应用失败，默认50s
innodb_io_capacity = 4000
innodb_io_capacity_max = 8000
innodb_flush_method = O_DIRECT          #不经过系统缓存直接存入磁盘
#innodb_file_format = Barracuda
#innodb_file_format_max = Barracuda
innodb_log_group_home_dir = /data/mysql/data/redolog/ #日志组所在的路径，默认为data的home目录
innodb_undo_directory = /data/mysql/data/undolog/
innodb_undo_logs = 128                                #undo日志回滚段 默认为128
innodb_undo_tablespaces = 0                           #用于设定创建的undo表空间的个数
innodb_flush_neighbors = 1                            #默认值为 1. 在SSD存储上应设置为0(禁用) ,因为使用顺序IO没有任何性能收益. 在使用RAID的某些硬件上也应该禁用此设置,因为逻辑上连续的块在物理磁盘上并不能保证也是连续的.
innodb_log_file_size = 512M                             #默认值为 48M. 有很高写入吞吐量的系统需要增加该值以允许后台检查点活动在更长的时间周期内平滑写入,得以改进性能. 将此值设置为4G以下是很安全的. 过去的实践表明,日志文件太大的缺点是增加了崩溃时所需的修复时间,但这在5.5和5.6中已得到重大改进.
innodb_log_buffer_size = 128M                     # 默认值为 128M. 这是最主要的优化选项,因为它指定 InnoDB 使用多少内存来加载数据和索引(data+indexes). 针对专用MySQL服务器,建议指定为物理内存的 50-80%这个范围. 例如,拥有64GB物理内存的机器,缓存池应该设置为50GB左右. 
                                                  #如果将该值设置得更大可能会存在风险,比如没有足够的空闲内存留给操作系统和依赖文件系统缓存的某些MySQL子系统(subsystem),包括二进制日志(binary logs),InnoDB事务日志(transaction logs)等.
innodb_purge_threads = 4                              #控制是否使用独立purge线程
innodb_large_prefix = 1                               #默认启用“允许索引键的前缀长度超过767个字节的动态和压缩tables.requires innodb_file_format innodb_file_per_table=
innodb_thread_concurrency = 64                        #并发线程数的限制值
innodb_print_all_deadlocks = 1                        #死锁相关的信息都会打印输出到error log
innodb_strict_mode = 1
innodb_sort_buffer_size = 512M                    #这个参数主要作用是缓存innodb表的索引，数据，插入数据时的缓冲 专用mysql服务器设置的大小： 操作系统内存的70%-80%最佳。
########semi sync replication settings########
#半同步复制
#plugin_dir=/usr/local/mysql/lib/plugin
#plugin_load = "rpl_semi_sync_master=semisync_master.so;rpl_semi_sync_slave=semisync_slave.so"
#loose_rpl_semi_sync_master_enabled = 1
#loose_rpl_semi_sync_slave_enabled = 1
#loose_rpl_semi_sync_master_timeout = 5000

[mysqld-5.7]
innodb_buffer_pool_dump_pct = 40   #表示转储每个bp instance LRU上最热的page的百分比。通过设置该参数可以减少转储的page数。
innodb_page_cleaners = 4           #并行刷脏
innodb_undo_log_truncate = 1       #参数设置为1，即开启在线回收（收缩）undo log日志文件，支持动态设置。
innodb_max_undo_log_size = 2G      #控制最大undo tablespace文件的大小，超过这个阀值时才会去尝试truncate. truncate后的大小默认为10M
innodb_purge_rseg_truncate_frequency = 128
binlog_gtid_simple_recovery=1       #这个参数控制了当mysql启动或重启时，mysql在搜寻GTIDs时是如何迭代使用binlog文件的。
log_timestamps=system               #主要是控制 error log、slow_log、genera log，等等记录日志的显示时间参数，但不会影响 general log 和 slow log 写到表 (mysql.general_log, mysql.slow_log) 中的显示时间
#transaction_write_set_extraction=MURMUR32  #该参数基于MySQL5.7 Group Replication组复制的，没有使用不要设置
show_compatibility_56=on

[mysqldump]
quick
max_allowed_packet = 16M
EOF
 

#启动mysql服务
cd /usr/local/mysql
/bin/mkdir var
/bin/chown -R mysql.mysql var
cp support-files/mysql.server /etc/init.d/mysqld
/sbin/chkconfig mysqld on
service mysqld start
  
#设置环境变量
echo "export PATH=$PATH:/usr/local/mysql/bin" >> /etc/profile
source /etc/profile

#启动完成 密码在 /data/mysql/data/error.log A temporary password is generated for root@localhost: i/oHCvrCc9vp   
#cat  /data/mysql/data/error.log|grep 'temporary password' |awk -F: '{print $4}' 查看密码
#设置mysql登陆密码,初始密码为123456

#/bin/mkdir -p /var/lib/mysql
#ln -s /usr/local/mysql/var/mysql.sock /var/lib/mysql/mysql.sock
#mysql -h localhost -u root -p
#mysql -e "SET PASSWORD = PASSWORD('123456');"
#mysql -p123456 -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'password' WITH GRANT OPTION;"
#mysql -p123456 -e "FLUSH PRIVILEGES;"

#安装过程报错 内存不足导致 先停止其它服务 释放内存
#c++: Internal error: Killed (program cc1plus)
#Please submit a full bug report.
#See <http://bugzilla.redhat.com/bugzilla> for instructions.
#make[2]: *** [sql/CMakeFiles/sql.dir/item_geofunc.cc.o] Error 1
#make[1]: *** [sql/CMakeFiles/sql.dir/all] Error 2
#make: *** [all] Error 2
# mkdir -p /usr/local/boost && wget http://www.sourceforge.net/projects/boost/files/boost/1.59.0/boost_1_59_0.tar.gz
# -DWITH_BOOST=/usr/local/boost