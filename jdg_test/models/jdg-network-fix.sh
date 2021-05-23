vim /etc/docker/daemon.json
{
     "bip": "10.10.10.1/24"
}
# 修改docker
grep 10.14.0.5 -rl /etc/docker | xargs sed -i "s/10.14.0.5/10.10.10.1/g"
systemctl restart docker
# 修改nginx容器
vim /FILESTORE/SYSTEM/front-nginx.yaml
network_mode: bridge
ip link delete br-0165d4c44f9c
ip link delete docker_gwbridge

docker-compose -f /FILESTORE/SYSTEM/front-nginx.yaml down
docker-compose -f /FILESTORE/SYSTEM/front-nginx.yaml up -d --force-recreate 

# 修改nginx配置
grep 10.14.0.5 -rl /FILESTORE/VOLUME/front-nginx_etc/conf.d | xargs sed -i "s/10.14.0.5/10.10.10.1/g"

# 修改APP运行配置
grep 10.14.0.5 -rl /FILESTORE/VOLUME/jdg-tw-node-farm_data/config | xargs sed -i "s/10.14.0.5/10.10.10.1/g"
grep 10.14.0.5 -rl /FILESTORE/VOLUME/jdg-tw-node-breeding_data/config | xargs sed -i "s/10.14.0.5/10.10.10.1/g"
grep 10.14.0.5 -rl /FILESTORE/VOLUME/jdg-tw-node-gateway_data/config | xargs sed -i "s/10.14.0.5/10.10.10.1/g"
grep 10.14.0.5 -rl /FILESTORE/VOLUME/jdg-tw-center-purchase_data/config | xargs sed -i "s/10.14.0.5/10.10.10.1/g"
grep 10.14.0.5 -rl /FILESTORE/VOLUME/jdg-node-power-management_data/config | xargs sed -i "s/10.14.0.5/10.10.10.1/g"

grep 172.17.0.1 -rl /FILESTORE/VOLUME/jdg-tw-node-farm_data/config | xargs sed -i "s/172.17.0.1/10.10.10.1/g"
grep 172.17.0.1 -rl /FILESTORE/VOLUME/jdg-tw-node-breeding_data/config | xargs sed -i "s/172.17.0.1/10.10.10.1/g"
grep 172.17.0.1 -rl /FILESTORE/VOLUME/jdg-tw-node-gateway_data/config | xargs sed -i "s/172.17.0.1/10.10.10.1/g"
grep 172.17.0.1 -rl /FILESTORE/VOLUME/jdg-tw-center-purchase_data/config | xargs sed -i "s/172.17.0.1/10.10.10.1/g"
grep 172.17.0.1 -rl /FILESTORE/VOLUME/jdg-node-power-management_data/config | xargs sed -i "s/172.17.0.1/10.10.10.1/g"

systemctl restart docker
./restart-all.sh
docker system prune
docker network prune
docker start front-nginx
docker-compose -f jdg-db.yaml down
docker-compose -f jdg-db.yaml up --force-recreate -d 

################################
# 修改redis-DB容器
# 修改docker
grep 10.10.0.5 -rl /etc/docker | xargs sed -i "s/10.10.0.5/10.10.10.1/g"

systemctl restart docker
./restart-all.sh

vim /FILESTORE/SYSTEM/jdg-db.yaml
network_mode: bridge
docker-compose -f /FILESTORE/SYSTEM/front-nginx.yaml down
docker-compose -f /FILESTORE/SYSTEM/front-nginx.yaml up -d --force-recreate 

####### NODE IP CONIFG ##########
！！！！！！！！！！！！！！！！！！！


####### 升级DOCKER引擎 ###########
[root@yangzptapp3-prd69 ~]# docker version
Client: Docker Engine - Community
 Version:           19.03.8
 API version:       1.39 (downgraded from 1.40)
 Go version:        go1.12.17
 Git commit:        afacb8b
 Built:             Wed Mar 11 01:27:04 2020
 OS/Arch:           linux/amd64
 Experimental:      false

Server: Docker Engine - Community
 Engine:
  Version:          18.09.0
  API version:      1.39 (minimum version 1.12)
  Go version:       go1.10.4
  Git commit:       4d60db4
  Built:            Wed Nov  7 00:19:08 2018
  OS/Arch:          linux/amd64
  Experimental:     false
[root@yangzptapp3-prd69 ~]

[root@jdg-iot-dev ~]# docker version


=================================DDDDDDDDDDDDDDDDDBBBBBBBBBBBBBBBBBBBBBBBB+=============
docker volume rm -f jdg-db_volume
docker volume rm -f share-redis_volume

mkdir -p /FILESTORE/VOLUME/share-redis
mkdir -p /FILESTORE/VOLUME/jdg-db
docker volume create --name share-redis_volume -o type=none -o device=/FILESTORE/VOLUME/share-redis -o o=bind
docker volume create --name jdg-db_volume -o type=none -o device=/FILESTORE/VOLUME/jdg-db -o o=bind
docker-compose -f /FILESTORE/SYSTEM/jdg-db.yaml down
docker-compose -f /FILESTORE/SYSTEM/jdg-db.yaml up --force-recreate -d 
docker exec -it jdg-db pg_basebackup -F p --progress -D /var/lib/postgresql/data/newdata -h 172.21.1.11 -p 6030 -U replica
replica:replica
jadedragon:eeb84b8951862bb35f6cfa96eea96610
archive_command = '/bin/true'

#===================== 修复数据库日志 ===============================
/usr/lib/postgresql/9.6/bin/pg_ctl stop -m fast
/usr/lib/postgresql/9.6/bin/pg_resetxlog -o 72115017 -x 273891330 -f /var/lib/postgresql/data
/usr/lib/postgresql/9.6/bin/pg_resetxlog -f /var/lib/postgresql/data
#==================================================================
LOG:  database system was shut down at 2021-05-20 03:25:48 UTC
FATAL:  could not access status of transaction 273891330
DETAIL:  Could not open file "pg_clog/0105": No such file or directory.
LOG:  startup process (PID 25) exited with exit code 1
LOG:  aborting startup due to startup process failure
LOG:  database system is shut down
#==================================================================
dd if=/dev/zero of=/var/lib/postgresql/data/pg_clog/0105 bs=256k count=1



这种情况多数情况下是在执行事务时， 数据库被强行关闭导致的， 修复的方法是：
使用 pg_resetxlog DATADIR 来解决；
使用命令 docker-compose down 来停止正在运行的数据库容器实例， 也可以使用 docker stop 和 docker rm 命令。
覆盖 entrypoint 来的形式启动一个临时的容器
覆盖默认的 entrypoint 启动， 进入可交互的命令行窗口：
  docker run -it --rm --entrypoint /bin/bash -v jdg-db_volume:/var/lib/postgresql/data  postgres:9.6.9
注意镜像的版本必须和原来的一致

pg_resetxlog /var/lib/postgresql/data

[root@yangzptdb1-test jdg_log]# docker exec -it jdg-db bash
root@8929b8f67210:/# pg_con
pg_config       pg_conftool     pg_controldata
root@8929b8f67210:/# pg_controldata



# REP================
cp /usr/share/postgresql/9.6/recovery.conf.sample /var/lib/postgresql/data/
vim recovery.conf
standby_mode = on
primary_conninfo = 'host=172.21.1.11 port=6030 application_name=slave_db user=replica password=replica'
recovery_target_timeline = 'latest'


vim postgresql.conf

wal_level = hot_standby
max_connections = 1000              #一般查多于写的应用从库的最大连接数要比较大
hot_standby = on                    #在备份的同时允许查询，默认值
max_standby_streaming_delay = 30s   #可选，流复制最⼤大延迟
wal_receiver_status_interval = 10s  #可选，从向主报告状态的最⼤大间隔时间
hot_standby_feedback = on           #可选，查询冲突时向主反馈

========REP TEST ##########
drop database dashboard
drop database bak_0501

# REPLICA JDG
listen_addresses = '*'
###################主配置####################
#archive_mode = on
#archive_command = '/bin/true'      #通行归档
#archive_command = 'test ! -f /var/lib/postgresql/data/jdg_archive/%f && cp %p /var/lib/postgresql/data/jdg_archive/%f'
#wal_level = replica
#max_wal_senders = 32
#wal_keep_segments = 256
#wal_sender_timeout = 60s

# LOG JDG
logging_collector = on
log_directory = 'jdg_log'
log_min_duration_statement = 5000
shared_preload_libraries = 'pg_stat_statements'
###################从配置######################
wal_level = hot_standby
max_connections = 1800              #一般查多于写的应用从库的最大连接数要比较大
hot_standby = on                    #在备份的同时允许查询，默认值
max_standby_streaming_delay = 30s   #可选，流复制最⼤大延迟
wal_receiver_status_interval = 10s  #可选，从向主报告状态的最⼤大间隔时间
hot_standby_feedback = on           #可选，查询冲突时向主反馈

##################RECOVERY####################
[root@yangzptdb2-test ~]# vim /FILESTORE/VOLUME/jdg-db/recovery.conf
standby_mode = on
primary_conninfo = 'host=172.21.1.11 port=6030 application_name=s2 user=replica password=replica'
recovery_target_timeline = 'latest'

select * from pg_stat_replication;
select pg_xlog_location_diff(pg_current_xlog_location(), replay_location) from pg_stat_replication;
############强制同步多副本，不同步时，事务等待#####
synchronous_standby_names = '3 (s2, s3, s4)'  # ??? 有待验证性能与一致性要求之间的平衡
synchronous_commit = 'remote_apply' # 金融级别

yum install https://www.pgpool.net/yum/rpms/4.2/redhat/rhel-7-x86_64/pgpool-II-release-4.2-1.noarch.rpm
yum install pgpool-II-pg96
yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum install -y postgresql96-server
yum install postgresql96-contrib

/usr/pgsql-9.6/bin/postgresql96-setup initdb
systemctl enable postgresql-9.6
systemctl start postgresql-9.6
/usr/pgsql-9.6/bin/pgbench -V


############PGPOOL.conf#####
vim /etc/pgpool-II/pgpool.conf

listen_addresses = '*'
backend_hostname0 = '172.21.1.11' # Host name or IP address to connect to for backend 0
backend_port0 = 6030 # Port number for backend 0
backend_weight0 = 1 # Weight for backend 0 (only in load balancing mode)
#backend_data_directory0 = '/data' # Data directory for backend 0
backend_flag0 = 'ALLOW_TO_FAILOVER' # Controls various backend behavior
# ALLOW_TO_FAILOVER or DISALLOW_TO_FAILOVER
backend_hostname1 = '172.21.1.12'
backend_port1 = 6030
backend_weight1 = 1
#backend_data_directory1 = '/data1'
backend_flag1 = 'ALLOW_TO_FAILOVER'

backend_hostname2 = '172.21.1.13'
backend_port2 = 6030
backend_weight2 = 1
#backend_data_directory1 = '/data1'
backend_flag2 = 'ALLOW_TO_FAILOVER'

backend_hostname3 = '172.21.1.14'
backend_port3 = 6030
backend_weight3 = 1
#backend_data_directory1 = '/data1'
backend_flag3 = 'ALLOW_TO_FAILOVER'

vim /etc/pgpool-II/pcp.conf

6. 设置pcp.conf, 如果当前系统⽤用户为root，则⽤用户名为root
pg_md5 jadedragon # 代表pcp管理理⼯工具⽤用户root的密码为jadedragon
echo 'pgpool:'`pg_md5 jadedragon` >> /etc/pgpool-II/pcp.conf
在pcp.conf下增加下⾯面⾏行行
pg_root:eeb84b8951862bb35f6cfa96eea96610
使⽤用pcp管理理⼯工具，pcp主要有以下命令
pcp_common_options -- common options used in PCP commands
pcp_node_count -- displays the total number of database nodes
pcp_node_info -- displays the information on the given node ID
pcp_health_check_stats -- displays health checks statistics data on given node ID
pcp_watchdog_info -- displays the watchdog status of the Pgpool-II
pcp_proc_count -- displays the list of Pgpool-II children process IDs
pcp_proc_info -- displays the information on the given Pgpool-II child process ID
pcp_pool_status -- displays the parameter values as defined in pgpool.conf
pcp_detach_node -- detaches the given node from Pgpool-II. Existing connections to Pgpool-II are forced to be
disconnected.
pcp_attach_node -- attaches the given node to Pgpool-II.
pcp_promote_node -- promotes the given node as new main to Pgpool-II
pcp_stop_pgpool -- terminates the Pgpool-II process
pcp_reload_config -- reload pgpool-II config file
pcp_recovery_node -- attaches the given backend node with recovery


pcp_node_info -U root -h 127.0.0.1 -p 9898 0 # 查看节点0信息
6. 设置pool_hba.conf
<. 设置pool_password(增加postgres和jadedragon, ⽤用于pgpool连接后端数据库的⽤用户验证)
在主库执⾏行行以下SQL，获取⽤用户对应的密码的md<格式
select rolname,rolpassword from pg_authid;
alter role postgres with password 'postgres';
增加⾄至pool_passwd 格式为
postgres:md53175bce1d3201d16594cebf9d7eb3f9d
jadedragon:md52a2b5157143da65e174af3d3ed038cbb
>. 启动pgpool
pgpool
?. 连接pgpool
psql -h 127.0.0.1 -p 9999 -U postgres
@. 查看pgpool常⽤用状态
show pool_nodes;
show pool_status;
show pool_pools;
show pool_processes;
三、PGPOOL 参数性能调优
#. 关注num_init_children以及max_pool参数
四、使⽤用pgbench压⼒力力测试。观察性能损耗
#. pgbench安装



[all servers]# su - postgres
[all servers]$ echo 'localhost:9898:pgpool:jadedragon' > ~/.pcppass
[all servers]$ chmod 600 ~/.pcppass
   

log_destination = 'stderr'
logging_collector = on
log_directory = '/var/log/pgpool_log'
log_filename = 'pgpool-%Y-%m-%d_%H%M%S.log'
log_truncate_on_rotation = on
log_rotation_age = 1d
log_rotation_size = 10MB

[all servers]# mkdir /var/log/pgpool_log/
[all servers]# chown postgres:postgres /var/log/pgpool_log/


Before starting Pgpool-II, please start PostgreSQL servers first.
Also, when stopping PostgreSQL, it is necessary to stop Pgpool-II first.
select rolname,rolpassword from pg_authid;

[server1]# psql -U postgres -p 5432
#postgres=# SET password_encryption = 'scram-sha-256';
postgres=# CREATE ROLE pgpool WITH LOGIN;
postgres=# \password pgpool
postgres=# \password postgres

psql -h 127.0.0.1 -p 9999 -U postgres -c "show pool_pools;"
psql -h 127.0.0.1 -p 9999 -U postgres -c "show pool_nodes;"
psql -h 127.0.0.1 -p 9999 -U postgres -c "show pool_status;"
psql -h 127.0.0.1 -p 9999 -U postgres -c "show pool_processes;"


psql -h 127.0.0.1 -p 9999 -U postgres -c "create database pgbench;"
psql -h 127.0.0.1 -p 9999 -U postgres -d pgbench -c "create table test_read(id int, info text);" 
psql -h 127.0.0.1 -p 9999 -U postgres -d pgbench -c "insert into test_read select generate_series(1, 1000000), md5(random():: text);"
psql -h 127.0.0.1 -p 9999 -U postgres -c "select * from pg_stat_replication;"

vim test_read.sql
\set id random(1,1000000)
select * from test_read where id=:id;


/usr/pgsql-9.6/bin/pgbench -M prepared -s 100 -n -r -P 1 -f ./test_read.sql -c 1000 -j 64 -T 60 -h 127.0.0.1 -p 9999 -U postgres pgbench
/usr/pgsql-9.6/bin/pgbench -M prepared -s 100 -n -r -P 1 -f ./test_read.sql -c 64 -j 64 -T 60 -h 172.21.1.11 -p 6030 -U postgres pgbench
/usr/pgsql-9.6/bin/pgbench -M prepared -s 100 -n -r -P 1 -f ./test_read.sql -c 64 -j 64 -T 60 -h 172.21.1.12 -p 6030 -U postgres pgbench

#读写
#初始化数据库及数据表
/usr/pgsql-9.6/bin/pgbench -h 127.0.0.1 -p 9999 -U postgres -s 10 -i pgbench

/usr/pgsql-9.6/bin/pgbench -s 100 -c 90 -j 64 -P 1 -T 60 -h 127.0.0.1 -p 9999 -U postgres pgbench
/usr/pgsql-9.6/bin/pgbench -s 10 -c 90 -j 64 -P 1 -T 60 -h 127.0.0.1 -p 9999 -U postgres pgbench

/usr/pgsql-9.6/bin/pgbench -c 90 -j 64 -P 1 -T 60 -h 172.21.1.11 -p 6030 -U postgres pgbench

#群
[root@yangzptdb4-test ~]# /usr/pgsql-9.6/bin/pgbench -M prepared -n -r -P 1 -f ./test_read.sql -c        64 -j 64 -T 60 -h 127.0.0.1 -p 9999 -U postgres pgbench
progress: 60.1 s, 469.8 tps, lat 68.044 ms stddev 18.352
transaction type: ./test_read.sql
scaling factor: 1
query mode: prepared
number of clients: 64
number of threads: 64
duration: 60 s
number of transactions actually processed: 28254
latency average = 68.050 ms
latency stddev = 18.355 ms
tps = 469.551831 (including connections establishing)
tps = 937.036008 (excluding connections establishing)
script statistics:
 - statement latencies in milliseconds:
         0.002  \set id random(1,1000000)
        68.069  select * from test_read where id=:id;
#主
[root@yangzptdb4-test ~]# /usr/pgsql-9.6/bin/pgbench -M prepared -n -r -P 1 -f ./test_read.sql -c        64 -j 64 -T 60 -h 172.21.1.11 -p 6030 -U postgres pgbench
transaction type: ./test_read.sql
scaling factor: 1
query mode: prepared
number of clients: 64
number of threads: 64
duration: 60 s
number of transactions actually processed: 9366
latency average = 410.321 ms
latency stddev = 149.350 ms
tps = 155.602864 (including connections establishing)
tps = 155.737541 (excluding connections establishing)
script statistics:
 - statement latencies in milliseconds:
         0.002  \set id random(1,1000000)
       410.205  select * from test_read where id=:id;
#从
transaction type: ./test_read.sql
scaling factor: 1
query mode: prepared
number of clients: 64
number of threads: 64
duration: 60 s
number of transactions actually processed: 9566
latency average = 401.856 ms
latency stddev = 133.731 ms
tps = 158.873608 (including connections establishing)
tps = 158.995250 (excluding connections establishing)
script statistics:
 - statement latencies in milliseconds:
         0.002  \set id random(1,1000000)
       401.964  select * from test_read where id=:id;
[root@yangzptdb4-test ~]#

# 读写 群
[root@yangzptdb4-test ~]# /usr/pgsql-9.6/bin/pgbench -c 90 -j 64 -P 1 -T 60 -h 127.0.0.1 -p 9999 -U postgres pgbench
starting vacuum...end.
progress: 60.0 s, 1149.0 tps, lat 6.960 ms stddev 6.755
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 10
query mode: simple
number of clients: 90
number of threads: 64
duration: 60 s
number of transactions actually processed: 69011
latency average = 6.964 ms
latency stddev = 6.759 ms
tps = 1148.907032 (including connections establishing)
tps = 3128.639146 (excluding connections establishing)

# 读写 主
[root@yangzptdb4-test ~]# /usr/pgsql-9.6/bin/pgbench -c 90 -j 64 -P 1 -T 60 -h 172.21.1.11 -p 6030 -U postgres pgbench
Password:
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 10
query mode: simple
number of clients: 90
number of threads: 64
duration: 60 s
number of transactions actually processed: 130351
latency average = 41.434 ms
latency stddev = 53.832 ms
tps = 2169.672299 (including connections establishing)
tps = 2170.076535 (excluding connections establishing)

 listen_backlog_multiplier* num_init_children can be queued.
netstat -s
	535 times the listen queue of a socket overflowed
# sysctl net.core.somaxconn
	net.core.somaxconn = 2048
	# sysctl -w net.core.somaxconn=2048
You could add following to /etc/sysctl.conf instead.

net.core.somaxconn = 1024
In summary, max_pool, num_init_children, max_connections, superuser_reserved_connections must satisfy the following formula:
max_pool*num_init_children <= (max_connections - superuser_reserved_connections) (no query canceling needed)
max_pool*num_init_children*2 <= (max_connections - superuser_reserved_connections) (query canceling needed)



num_init_children：pgPool允许的最大并发数，默认32。
max_pool：连接池的数量，默认4。
pgpool需要的数据库连接数=num_init_children*max_pool；
后检查Postgresql数据库的postgresql.conf文件的max_connections=100，superuser_reserved_connections=3。
pgpool的连接参数应当满足如下公式：

num_init_children*max_pool<max_connections-superuser_reserved_connections

当需要pgpool支持更多的并发时，需要更改num_init_children参数，同时要检查下num_init_children*max_pool是否超过了max_connections-superuser_reserved_connections，如果超过了，可将max_connections改的更大。

sysctl -w net.core.somaxconn=4096

delay_threshold = 10240
log_standby_delay = 'always'

docker-compose -f /FILESTORE/SYSTEM/jdg-db.yaml up --force-recreate -d 
df -h | grep shm
docker by-default restrict size of shared memory to 64MB.
docker run -itd --shm-size=1g postgres
db:
  image: "postgres:11.3-alpine"
  shm_size: 32g
  shm_size: 4g


/usr/pgsql-9.6/bin/pgbench -c 90 -j 64 -P 1 -T 60 -h 127.0.0.1 -p 9999 -U postgres pgbench
/usr/pgsql-9.6/bin/pgbench -n -S -h 127.0.0.1 -p 9999 -c 1000 -C -S -T 300 -U postgres pgbench



transaction type: <builtin: TPC-B (sort of)>
scaling factor: 10
query mode: simple
number of clients: 90
number of threads: 64
duration: 60 s
number of transactions actually processed: 138288
latency average = 39.006 ms
latency stddev = 51.047 ms
tps = 2302.746986 (including connections establishing)
tps = 2304.020735 (excluding connections establishing)


wal_receiver_status_interval = 1s  
wal_receiver_timeout = 10s  
recovery_target_timeline = 'latest'


delay_threshold = 512000
sr_check_period = 3   
child_life_time = 300  


datestyle = 'iso, mdy'  
timezone = 'Asia/Shanghai'  
lc_messages = 'en_US.utf8'  
lc_monetary = 'en_US.utf8'  
lc_numeric = 'en_US.utf8'  
lc_time = 'en_US.utf8' 
log_timezone = 'Asia/Shanghai'  
max_worker_processes = 128  


black_function_list = 'currval,lastval,nextval,setval'  
https://www.alibabacloud.com/help/zh/doc-detail/155742.htm


/dev/vda1        99G  4.4G   90G   5% /
time pg_dumpall | bzip2 -vf > database.`date +"%Y.%m.%d"`.pgdumpall.bz2

time pg_dump -h 172.21.1.11 -p 6030 -U jadedragon -W -Z 9 -Fd jdg_db_nf -j 64 -f /FILESTORE/BACKUP/dir_nf
time pg_dump -h 172.21.1.11 -p 6030 -U jadedragon -W -Z 9 -Fd jdg_db_nb -j 64 -f /FILESTORE/BACKUP/dir_nb
time pg_dump -h 172.21.1.11 -p 6030 -U jadedragon -W -Z 9 -Fd jdg_db_gw -j 64 -f /FILESTORE/BACKUP/dir_gw
time pg_dump -h 172.21.1.11 -p 6030 -U jadedragon -W -Z 9 -Fd jdg_db_pm -j 64 -f /FILESTORE/BACKUP/dir_pm
time pg_dump -h 172.21.1.11 -p 6030 -U jadedragon -W -Z 9 -Fd jdg_db_nps -j 64 -f /FILESTORE/BACKUP/dir_nps
eeb84b8951862bb35f6cfa96eea96610

nps:1
gw:10
pm:28
nb:120
nf:82
