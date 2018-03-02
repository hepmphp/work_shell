#/bin/bash
#
yum -y install glibc-devel.i686
cd /usr/local/src
wget http://download.redis.io/releases/redis-4.0.8.tar.gz
tar -xzvf redis-4.0.8.tar.gz
cd redis-4.0.8 
#编辑src/.make-settings里的OPT，改为OPT=-O2 -march=i686
make PREFIX=/usr/local/redis install 
#make CFLAGS="-m32 -march=native" LDFLAGS="-m32"  PREFIX=/usr/local/redis install
 
mkdir -p /usr/local/redis/etc/
cp redis.conf  /usr/local/redis/etc/redis_6379.conf
sed -i 's/daemonize no/daemonize yes/g' /usr/local/redis/etc/redis.conf
sed -i 's/^# bind 127.0.0.1/bind 127.0.0.1/g' /usr/local/redis/etc/redis.conf
 

#创建服务
sysctl -w vm.overcommit_memory=1
sysctl -w net.core.somaxconn=512
echo never > /sys/kernel/mm/transparent_hugepage/enabled
cp utils/redis_init_script /etc/init.d/redis
sed -i 's/\/usr\/local/\/usr\/local\/redis/g' /etc/init.d/redis 
sed -i 's/\/etc\/redis/\/usr\/local\/redis\/etc\/redis_/' /etc/init.d/redis

cat >/etc/systemd/system/redis.service <<EOF
[Unit]
Description=Redis on port 6379
[Service]
#Type=forking
ExecStart=/etc/init.d/redis start
ExecStop=/etc/init.d/redis stop
[Install]
WantedBy=multi-user.target
EOF

systemctl enable redis
#务必要进行reload
systemctl daemon-reload
#在centos7下可用service命令启动
service redis start
#查看服务状态
service redis status
#在低于centos7版本下用systemctl
systemctl start redis

