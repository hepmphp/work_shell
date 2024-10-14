#!/bin/bash
i=1
MAX_INSERT_ROW_COUNT=$1
while [ $i -le $MAX_INSERT_ROW_COUNT ]
do
    mysql -h localhost -uroot -p123456 -e "insert into wiki.haha(name) values (NOW());"
    d=$(date +%M-%d\ %H\:%m\:%S)
    echo "INSERT HELLO $i @@ $d"    
    i=$(($i+1))
    sleep 0.05
done
exit 0

#插入十万的数据为./jiaoben.sh 100000
#CREATE DATABASE wiki CHARACTER SET utf8 COLLATE utf8_general_ci; 
# create table if not exists haha (id int(10) PRIMARY KEY AUTO_INCREMENT,name varchar(50) NOT NULL);