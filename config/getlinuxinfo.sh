echo ---UHURUMON-CPU_TIME
top -b -n 1 |grep ^Cpu

echo ---UHURUMON-SYSTEM_INFO
free -m

echo ---UHURUMON-DISK_USAGE
df -h

echo ---UHURUMON-COMPONENT_INFO
if [ -d /var/vcap/jobs/dea ]; then
	echo Linux DEA

	echo ---UHURUMON-DROPLETCOUNTFOLDER
	ls -la /var/vcap/data/dea/apps/
	echo ---UHURUMON-WORKERPROCESSESIISCOUNT
	ps aux | grep dea/apps	
	echo ---UHURUMON-WORKERPROCESSESMEMORY
	ps aux | grep dea/apps
	echo ---UHURUMON-DEAPROCESSMEMORY
	ps aux | grep jobs/dea
	echo ---UHURUMON-CONFIG
	cat /var/vcap/jobs/dea/config/dea.yml
	echo ---UHURUMON-DROPLETDATA
	cat /var/vcap/data/dea/db/applications.json
fi

if [ -d /var/vcap/jobs/mysql_node ]; then
	echo MySQL Node
	
	echo ---UHURUMON-DATABASESONDRIVE
	ls /var/vcap/store/mysql/ -la
	echo ---UHURUMON-SERVERMEMORY
	ps aux | grep libexec/mysqld
	echo ---UHURUMON-NODEPROCESSMEMORY
	ps aux | grep bin/mysql_node
	echo ---UHURUMON-CONFIG
	cat /var/vcap/jobs/mysql_node/config/mysql_node.yml
	echo ---UHURUMON-SERVICEDB
	/var/vcap/packages/sqlite/bin/sqlite3 /var/vcap/store/mysql_node.db "select name,plan,quota_exceeded from vcap_services_mysql_node_provisioned_services"
	
fi
 
if [ -d /var/vcap/jobs/postgresql_node ]; then
	echo PostgreSQL Node

	echo ---UHURUMON-DATABASESONDRIVE
	ls -la /var/vcap/store/postgresql/base/
	echo ---UHURUMON-SERVERMEMORY
	ps aux | grep 'postgres:\|5.1/bin/postgres'
	echo ---UHURUMON-NODEPROCESSMEMORY
	ps aux | grep bin/postgresql_node
	echo ---UHURUMON-CONFIG
	cat /var/vcap/jobs/postgresql_node/config/postgresql_node.yml
	echo ---UHURUMON-SERVICEDB
	/var/vcap/packages/sqlite/bin/sqlite3 /var/vcap/store/postgresql_node.db "select name,plan,quota_exceeded from vcap_services_postgresql_node_provisionedservices"
fi
 
if [ -d /var/vcap/jobs/mongodb_node ]; then
	echo MongoDB Node
	
	echo ---UHURUMON-DATABASESONDRIVE
	ls -la /var/vcap/store/mongodb/
	echo ---UHURUMON-SERVERMEMORY
	ps aux | grep "bin/mongod -f"
	echo ---UHURUMON-NODEPROCESSMEMORY
	echo ---UHURUMON-CONFIG
	cat /var/vcap/jobs/mongodb_node/config/mongodb_node.yml
	echo ---UHURUMON-SERVICEDB
	/var/vcap/packages/sqlite/bin/sqlite3 /var/vcap/store/mongodb_node.db "select name,plan,quota_exceeded from vcap_services_mongodb_node_provisioned_services"
	
fi
 
if [ -d /var/vcap/jobs/redis_node ]; then
	echo Redis Node
	
	echo ---UHURUMON-DATABASESONDRIVE
	ls -la /var/vcap/store/redis/instances/
	echo ---UHURUMON-SERVERMEMORY
	ps aux | grep redis-server
	echo ---UHURUMON-NODEPROCESSMEMORY
	ps aux | grep redis_node
	echo ---UHURUMON-CONFIG
	cat /var/vcap/jobs/redis_node/config/redis_node.yml
	echo ---UHURUMON-SERVICEDB
	/var/vcap/packages/sqlite/bin/sqlite3 /var/vcap/store/redis_node.db "select name,plan,quota_exceeded from vcap_services_redis_node_provisioned_services"

fi
 
if [ -d /var/vcap/jobs/rabbit_node ]; then
	echo RabbitMQ Node
	
	echo ---UHURUMON-DATABASESONDRIVE
	ls -la /var/vcap/store/rabbit/instances/
	echo ---UHURUMON-SERVERMEMORY
	ps aux | grep /var/vcap/store/rabbit/instances/
	echo ---UHURUMON-NODEPROCESSMEMORY
	ps aux | grep rabbit_node
	echo ---UHURUMON-CONFIG
	cat /var/vcap/jobs/rabbit_node/config/rabbit_node.yml
	echo ---UHURUMON-SERVICEDB
	/var/vcap/packages/sqlite/bin/sqlite3 /var/vcap/store/rabbit_node.db "select name,plan,quota_exceeded from vcap_services_rabbit_node_provisioned_services"

fi
 
if [ -d /var/vcap/jobs/cloud_controller ]; then
	echo Cloud Controller
	

fi
 
if [ -d /var/vcap/jobs/stager ]; then
	echo Stager
fi
 
if [ -d /var/vcap/jobs/ccdb_postgres ]; then
	echo Cloud Controller Database
fi
 
if [ -d /var/vcap/jobs/collector ]; then
	echo Collector
fi
 
if [ -d /var/vcap/jobs/dashboard ]; then
	echo Dashboard
fi
 
if [ -d /var/vcap/jobs/debian_nfs_server ]; then
	echo Network File System
fi
 
if [ -d /var/vcap/jobs/opentsdb ]; then
	echo Open TSTB
fi
 
if [ -d /var/vcap/jobs/nats ]; then
	echo NATS Server
fi
 
if [ -d /var/vcap/jobs/router ]; then
	echo Router
fi
 
if [ -d /var/vcap/jobs/syslog_aggregator ]; then
	echo Syslog Aggregator
fi
 
if [ -d /var/vcap/jobs/vcap_redis ]; then
	echo VCAP Redis
fi
 
if [ -d /var/vcap/jobs/mysql_gateway ]; then
	echo MySQL Gateway
fi
 
if [ -d /var/vcap/jobs/postgresql_gateway ]; then
	echo PostgreSQL Gateway
fi
 
if [ -d /var/vcap/jobs/mongodb_gateway ]; then
	echo MongoDB Gateway
fi
 
if [ -d /var/vcap/jobs/redis_gateway ]; then
	echo Redis Gateway
fi
 
if [ -d /var/vcap/jobs/rabbit_gateway ]; then
	echo RabbitMQ Gateway
fi
 
if [ -d /var/vcap/jobs/sqlserver_gateway ]; then
	echo SqlServer Gateway
fi
 
if [ -d /var/vcap/jobs/uhurufs_gateway ]; then
	echo UhuruFS Gateway
fi
 