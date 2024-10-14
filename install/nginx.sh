#/bin/bash
#安装前的准备工作
yum -y install gcc gcc-c++ autoconf automake zlib zlib-devel openssl openssl-devel pcre-devel

#新建web
#useradd -d /dev/null -s /sbin/nologin webuser -u2001

cd /usr/local/src
wget http://nginx.org/download/nginx-1.10.3.tar.gz
tar xzvf nginx-1.10.3.tar.gz
cd nginx-1.10.3
./configure --prefix=/usr/local/nginx --with-http_stub_status_module --with-debug  --with-http_ssl_module
make && make install

#设置日志切割脚本每日切割日志，配置日志切割脚本
mkdir /usr/local/nginx/var

#站点conf文件
mkdir /usr/local/nginx/conf/vhosts -p


#建立好文件存放目录,测试目录为test
mkdir -p /data/www/www.test.com/
mkdir -p /data/logs/www.test.com/

#备份并修改nginx.conf
mv /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.bak
cat > /usr/local/nginx/conf/nginx.conf << EOF
user  nobody;
worker_processes  2;

error_log  /data/logs/error.log error;
pid        var/nginx.pid;


events {
    use epoll;
    worker_connections  65535;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    log_format  main  '$http_x_forwarded_for $remote_addr $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" '
		      '"$request_time"'
		      '"$upstream_addr" "$upstream_status" "$upstream_response_time"';



    access_log  /data/logs/access.log  main;

    sendfile        on;
    tcp_nopush     off;
    tcp_nodelay    on;
    keepalive_timeout  65;

    gzip on;
    gzip_comp_level 4;
    gzip_min_length 1024;
    gzip_buffers 4 8k;
    gzip_types text/plain application/x-javascript text/css application/xml text/javasvript application/pdf image/x-ms-bmp;
    gzip_disable "MSIC [1-6]\.(?!.*SV1)";

    client_max_body_size 2m;
    client_header_timeout 30;
    client_body_timeout   30;
    client_header_buffer_size    1k;
    large_client_header_buffers  4 4k;

    send_timeout          30;

    include vhosts/*.conf;

    server {
	listen       80  default_server;
        server_name  _;
        return 500;
     }

    #开启监控
    server{
        listen 9090;
        location /nginxinfo_status{
            stub_status on;
            access_log off;
        }
    }
}
EOF

cat > /usr/local/nginx/conf/vhosts/www.test.conf <<EOF
server {
	listen       80;
	server_name www.test.com;
	access_log  /data/logs/www.test.com/access.log main;
	error_log   /data/logs/www.test.com/error.log error;

	#若有url重写规则，可在这个位置添加，结构如下
	#rewrite **** ******
	root	/data/www/www.test.com;
	location / {
		index           index.htm index.html index.php;
	}
	#禁止执行PHP的目录。
	location ~ .*(attachments|forumdata|images|customavatars)/.*\.php$ {
		deny all;
	}

	#设置图片缓存为30天，暂时注释掉
	location ~ .*\.(gif|jpg|jpeg|png|bmp|swf)$
	{
		#expires 30d;
	}

	#设置js和css缓存为12小时，暂时注释掉
	location ~ .*\.(js|css)?$
	{
		#expires 12h;
	}

    #允许执行PHP的配置。
	location  ~ [^/]\.php(/|$) {
        fastcgi_split_path_info  ^(.+?\.php)(/.*)$;
        if (!-f $document_root$fastcgi_script_name) {
                return 404;
        }
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        fastcgi_param  PATH_INFO        $fastcgi_path_info;
        fastcgi_param  PATH_TRANSLATED  $document_root$fastcgi_path_info;
        include        fastcgi_params;
    }	
}
EOF


cat > /usr/local/nginx/sbin/logcron.sh  <<EOF 
#!/bin/bash
# This script run at 00:00
# The Nginx logs path
log_dir="/data/logs"
#The definition of variables
dir_names=`ls -l /data/logs |awk '{print  $9}'`
source_path=/data

#The path for Nginx logs path by cuted
date=`date -d "yesterday" +"%Y%m%d"`

#Change logformat as combined and cut Nginx logs
#Log Cutting
for i in ${dir_names[*]}
do

	if [ -d "${log_dir}/$i" ];then
		/bin/mv ${log_dir}/$i/access.log ${log_dir}/$i/access${date}.log
		/bin/mv ${log_dir}/$i/error.log ${log_dir}/$i/error${date}.log
	fi

	#echo ${log_dir}/$i

done
#Reopen Nginx logs file
kill -USR1 \`cat  /usr/local/nginx/var/nginx.pid\`

#remind the file of log
find /data/logs/*/access*.log -mtime +60 |xargs rm -f
find /data/logs/*/error*.log -mtime +120 |xargs rm -f
EOF 


#将 logcron.sh 加入定时任务
echo "0 0 * * * /bin/bash  /usr/local/nginx/sbin/logcron.sh" >> /var/spool/cron/root

#为 logcron.sh 脚本设置可执行属性
chmod +x /usr/local/nginx/sbin/logcron.sh


#设置服务脚本,创建NGINX开机启动脚本
cat > /etc/init.d/nginx <<EOF
#! /bin/bash
#
# nginx          Start/Stop the nginx daemon.
#
# chkconfig: - 85 15
# description: nginx
# processname: nginx
# config: /usr/local/nginx/conf/nginx.conf
# pidfile: /usr/local/nginx/var/nginx.pid

# Source function library.
. /etc/init.d/functions

# Nginx Settings
NGX_PID_FILE='/usr/local/nginx/var/nginx.pid'
NGX_PROC='/usr/local/nginx/sbin/nginx'
NGX_LOCK_FILE='/var/lock/subsys/nginx'

# Progran name
prog="nginx"

start() {
        ulimit -HSn 65536
	echo -n $"Starting $prog: "
        if [ -e $NGX_LOCK_FILE ]; then
	    if [ -e $NGX_PID_FILE ] && [ -e /proc/`cat $NGX_PID_FILE` ]; then
		echo -n $"cannot start $prog: nginx is already running."
		failure $"cannot start $prog: nginx is already running."
		echo
		return 1
	    fi
	fi
	$NGX_PROC
	RETVAL=$?
	[ $RETVAL -eq 0 ] && success $"$prog start" || failure $"$prog start"
	[ $RETVAL -eq 0 ] && touch $NGX_LOCK_FILE
	echo


	return $RETVAL
}

stop() {
	echo -n $"Stopping $prog: "
        if [ ! -e $NGX_LOCK_FILE ] || [ ! -e $NGX_PID_FILE ]; then
	    echo -n $"cannot stop $prog: nginx is not running."
	    failure $"cannot stop $prog: nginx is not running."
	    echo
	    return 1
	fi
	PID=`cat $NGX_PID_FILE`
	if checkpid $PID 2>&1; then
	    # TERM first, then KILL if not dead
	    kill -TERM $PID >/dev/null 2>&1
	    usleep 100000
	    if checkpid $PID && sleep 1 && checkpid $PID && sleep 3 && checkpid $PID; then
		kill -KILL $PID >/dev/null 2>&1
		usleep 100000
	    fi
	fi
	checkpid $PID
	RETVAL=$((! $?))
	[ $RETVAL -eq 0 ] && success $"$prog shutdown" || failure $"$prog shutdown"
        [ $RETVAL -eq 0 ] && rm -f $NGX_LOCK_FILE;
	echo


	return $RETVAL
}

status() {
	status $prog
}

restart() {
  	stop
	start
}

reload() {
	echo -n $"Reloading $prog: "
	if [ ! -e $NGX_LOCK_FILE ] || [ ! -e $NGX_PID_FILE ]; then
	    echo -n $"cannot reload $prog: nginx is not running."
	    failure $"cannot reload $prog: nginx is not running."
	    echo
	    return 1
	fi
	kill -HUP `cat $NGX_PID_FILE` >/dev/null 2>&1
	RETVAL=$?
	[ $RETVAL -eq 0 ] && success $"$prog reload" || failure $"$prog reload"
	echo
	return $RETVAL
}

case "$1" in
  start)
  	start
	;;
  stop)
  	stop
	;;
  restart)
  	restart
	;;
  reload)
  	reload
	;;
  status)
  	status
	;;
  condrestart)
  	[ -f $NGX_LOCK_FILE ] && restart || :
	;;
  configtest)
	$NGX_PROC -t
	;;
  *)
	echo $"Usage: $0 {start|stop|status|reload|restart|condrestart|configtest}"
	exit 1
esac
EOF

#为 nginx.sh 脚本设置可执行属性
chmod +x /etc/init.d/nginx

#添加 Nginx 为系统服务（开机自动启动）
chkconfig --add nginx
chkconfig nginx on

service nginx start