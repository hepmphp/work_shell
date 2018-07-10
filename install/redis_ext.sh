#/bin/bash
cd /usr/local/src/
sed -i '/redis.so/d' /usr/local/php/etc/php.ini
zend_ext_dir=/usr/local/php/lib/php/extensions/no-debug-non-zts-20151012/
zend_ext="${zend_ext_dir}redis.so"
if [ -s "${zend_ext}" ]; then
    rm -f "${zend_ext}"
fi 
wget http://pecl.php.net/get/redis-4.0.0RC1.tgz
tar -zxvf redis-4.0.0RC1.tgz 
cd redis-4.0.0RC1
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config
make && make install
#echo  'extension_dir = "/usr/local/php5.6.36/lib/php/extensions/no-debug-zts-20131226/"' >>/usr/local/php5.6.36/etc/php.ini
echo  'extension = "redis.so"' >>/usr/local/php/etc/php.ini
systemctl restart php-fpm.service 
 