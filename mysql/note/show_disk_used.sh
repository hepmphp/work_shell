#1.mysql查看数据库占用空间
du -h  /data/mysql/wiki/
25M	/data/mysql/wiki/

#2.查看数据库大小
/usr/local/mysql/bin/mysql -u root -pxxx -e 'SELECT table_schema "Database Name", sum( data_length + index_length ) / 1024 / 1024 "Database Size in MB" FROM information_schema.TABLES GROUP BY table_schema';

+--------------------+---------------------+
| Database Name      | Database Size in MB |
+--------------------+---------------------+
| deploy             |          0.07812500 |
| ecshop             |          2.95854759 |
| information_schema |          0.15625000 |
| mysql              |          0.32466888 |
| new_web            |        433.84150028 |
| performance_schema |          0.00000000 |
| spread             |          0.21875000 |
| sys                |                NULL |
| wiki               |          7.42736435 |
+--------------------+---------------------+

#3.查看MySQL表大小
/usr/local/mysql/bin/mysql -u root -pxxx -e '
SELECT table_name AS "Tables",round(((data_length + index_length) / 1024 / 1024), 2) "Size in MB"
FROM information_schema.TABLES
WHERE table_schema = "new_web"
ORDER BY (data_length + index_length) DESC; ';

+-----------------------------------+------------+
| Tables                            | Size in MB |
+-----------------------------------+------------+
| pre_forum_post                    |     342.66 |
| pre_forum_thread                  |      80.33 |
| pre_forum_newthread               |       2.47 |
| pre_common_district               |       1.95 |
| pre_forum_threadhot               |       1.89 |
| pre_forum_sofa                    |       1.81 |
| pre_common_member_action_log      |       0.77 |
| pre_forum_rsscache                |       0.43 |
| pre_forum_statlog                 |       0.38 |
| pre_common_syscache               |       0.36 |
| pre_common_block_style            |       0.08 |

#4 找出前10的表大小
/usr/local/mysql/bin/mysql -u root -pxxx -e "
SELECT CONCAT(table_schema, '.', table_name),
CONCAT(ROUND(table_rows / 1000000, 2), 'M') rows,
CONCAT(ROUND(data_length / ( 1024 * 1024 * 1024 ), 2), 'G') DATA,
CONCAT(ROUND(index_length / ( 1024 * 1024 * 1024 ), 2), 'G') idx,
CONCAT(ROUND(( data_length + index_length ) / ( 1024 * 1024 * 1024 ), 2), 'G') total_size,
ROUND(index_length / data_length, 2) idxfrac
FROM information_schema.TABLES
ORDER BY data_length + index_length DESC LIMIT 10"

+---------------------------------------+-------+-------+-------+------------+---------+
| CONCAT(table_schema, '.', table_name) | rows  | DATA  | idx   | total_size | idxfrac |
+---------------------------------------+-------+-------+-------+------------+---------+
| new_web.pre_forum_post                | 0.06M | 0.33G | 0.01G | 0.33G      |    0.02 |
| new_web.pre_forum_thread              | 0.06M | 0.07G | 0.01G | 0.08G      |    0.09 |
| new_web.pre_forum_newthread           | 0.00M | 0.00G | 0.00G | 0.00G      |    2.72 |
| ecshop.ecs_stats                      | 0.02M | 0.00G | 0.00G | 0.00G      |    0.11 |
| new_web.pre_common_district           | 0.05M | 0.00G | 0.00G | 0.00G      |    0.84 |
| new_web.pre_forum_threadhot           | 0.05M | 0.00G | 0.00G | 0.00G      |    2.89 |
| new_web.pre_forum_sofa                | 0.06M | 0.00G | 0.00G | 0.00G      |    3.23 |
| wiki.aws_user_action_history_data     | 0.00M | 0.00G | 0.00G | 0.00G      |    0.00 |
| new_web.pre_common_member_action_log  | 0.00M | 0.00G | 0.00G | 0.00G      |    2.02 |
| new_web.pre_forum_rsscache            | 0.00M | 0.00G | 0.00G | 0.00G      |    0.03 |
+---------------------------------------+-------+-------+-------+------------+---------+


