#/bin/bash
#参考https://renwole.com/archives/29
#安装扩展包并更新系统内核：
yum install epel-release -y
yum update

#安装php依赖组件（包含Nginx依赖）：
yum -y install wget vim pcre pcre-devel openssl openssl-devel libicu-devel gcc gcc-c++ autoconf libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel ncurses ncurses-devel curl curl-devel krb5-devel libidn libidn-devel openldap openldap-devel nss_ldap jemalloc-devel cmake boost-devel bison automake libevent libevent-devel gd gd-devel libtool* libmcrypt libmcrypt-devel mcrypt mhash libxslt libxslt-devel readline readline-devel gmp gmp-devel libcurl libcurl-devel openjpeg-devel

#创建用户和组，并下载php安装包解压
cd /usr/local/src
groupadd www
useradd -g www www -s /sbin/nologin
wget http://am1.php.net/distributions/php-7.2.1.tar.gz
tar zxvf php-7.2.1.tar.gz
cd php-7.2.1
#设置变量并开始源码编译：
cp -frp /usr/lib64/libldap* /usr/lib/
./configure --prefix=/usr/local/php \
--with-config-file-path=/usr/local/php/etc \
--enable-fpm \
--with-fpm-user=www \
--with-fpm-group=www \
--enable-mysqlnd \
--with-mysqli=mysqlnd \
--with-pdo-mysql=mysqlnd \
--enable-mysqlnd-compression-support \
--with-iconv-dir \
--with-freetype-dir \
--with-jpeg-dir \
--with-png-dir \
--with-zlib \
--with-libxml-dir \
--enable-xml \
--disable-rpath \
--enable-bcmath \
--enable-shmop \
--enable-sysvsem \
--enable-inline-optimization \
--with-curl \
--enable-mbregex \
--enable-mbstring \
--enable-intl \
--with-mcrypt \
--with-libmbfl \
--enable-ftp \
--with-gd \
--enable-gd-jis-conv \
--enable-gd-native-ttf \
--with-openssl \
--with-mhash \
--enable-pcntl \
--enable-sockets \
--with-xmlrpc \
--enable-zip \
--enable-soap \
--with-gettext \
--disable-fileinfo \
--enable-opcache \
--with-pear \
--enable-maintainer-zts \
--with-ldap=shared \
--without-gdbm \

#开始安装
make -j 4 && make install

#完成安装后配置php.ini文件：
cat php.ini-development|grep -v ';'|grep -v '^$'> /usr/local/php/etc/php.ini
cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf


#修改 php.ini 相关参数：
sed -i 's/expose_php = On/expose_php = Off/' /usr/local/php/etc/php.ini
sed -i 's/short_open_tag = Off/short_open_tag = ON/' /usr/local/php/etc/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 300/' /usr/local/php/etc/php.ini
sed -i 's/max_input_time = 30/max_input_time = 300/' /usr/local/php/etc/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 32M/' /usr/local/php/etc/php.ini
echo 'date.timezone = Asia/Shanghai'>> /usr/local/php/etc/php.ini
sed -i '/\[Date\]/a\date.timezone = Asia/Shanghai' /usr/local/php/etc/php.ini
#sed -i '/\[mbstring\]/a\mbstring.func_overload=2' /usr/local/php/etc/php.ini

#设置 OPcache 缓存：
sed '/\[opcache\]/a\zend_extension=/usr/local/php/lib/php/extensions/no-debug-zts-20160303/opcache.so \n opcache.memory_consumption=128\n opcache.interned_strings_buffer=8\n opcache.max_accelerated_files=4000\n opcache.revalidate_freq=60\n opcache.fast_shutdown=1\n opcache.enable_cli=1' /usr/local/php/etc/php.ini 



# cat /usr/local/php/etc/php-fpm.conf|grep -v ';'|grep -v ^$
#cat /usr/local/php/etc/php-fpm.d/www.conf|grep -v ';'|grep -v ^$
#创建php-cgi.sock存放目录
mkdir /var/run/www/
chown -R www:www /var/run/www
#配置php-fpm.conf 取下以下注释并填写完整路径：
sed -i 's/;pid/pid/' /usr/local/php/etc/php-fpm.conf
sed -i 's/;error_log/error_log/' /usr/local/php/etc/php-fpm.conf

#配置www.conf 取消以下注释并修改优化其参数：
cat >/usr/local/php/etc/php-fpm.d/www.conf <<EOF
[www]
user = www
group = www
listen = 127.0.0.1:9000
pm = dynamic
listen.backlog = -1
pm.max_children = 180
pm.start_servers = 50
pm.min_spare_servers = 50
pm.max_spare_servers = 180
request_terminate_timeout = 120
request_slowlog_timeout = 50
slowlog = var/log/slow.log
EOF



#创建system系统单元文件php-fpm启动脚本：
cat > /usr/lib/systemd/system/php-fpm.service <<EOF
[Unit]
Description=The PHP FastCGI Process Manager
After=syslog.target network.target
[Service]
Type=simple
PIDFile=/usr/local/php/var/run/php-fpm.pid
ExecStart=/usr/local/php/sbin/php-fpm --nodaemonize --fpm-config /usr/local/php/etc/php-fpm.conf  -c /usr/local/php/etc/php.ini

ExecReload=/bin/kill -USR2 $MAINPID

[Install]
WantedBy=multi-user.target
EOF


#启动php-fpm服务并加入开机自启动：
systemctl enable php-fpm.service
systemctl restart php-fpm.service 
systemctl status php-fpm
