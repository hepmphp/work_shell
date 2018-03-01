#/bin/bash
cd /usr/local/src/
sed -i '/redis.so/d' /usr/local/php/etc/php.ini
zend_ext_dir=/usr/local/php/lib/php/extensions/no-debug-non-zts-20151012/
zend_ext="${zend_ext_dir}redis.so"
if [ -s "${zend_ext}" ]; then
    rm -f "${zend_ext}"
fi 
rm -rf phpredis
git clone -b php7 https://github.com/phpredis/phpredis.git
cd phpredis

/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config
make && make install
echo  'extension = "redis.so"' >>/usr/local/php/etc/php.ini
systemctl restart php-fpm.service 
 