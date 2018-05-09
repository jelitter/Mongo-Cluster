mkdir cluster

cd cluster

mkdir cork

mkdir dublin

cd cork

mkdir cork0
mkdir cork1
mkdir cork2

start /b mongod --shardsvr --replSet cork --dbpath cork0 --port 40000 --logpath cork0.log
start /b mongod --shardsvr --replSet cork --dbpath cork1 --port 40001 --logpath cork1.log  
start /b mongod --shardsvr --replSet cork --dbpath cork2 --port 40002 --logpath cork2.log 
pause

cd ..
cd dublin

mkdir dublin0
mkdir dublin1
mkdir dublin2

start /b mongod --shardsvr --replSet dublin --dbpath dublin0 --port 30000 --logpath dublin0.log
start /b mongod --shardsvr --replSet dublin --dbpath dublin1 --port 30001 --logpath dublin1.log  
start /b mongod --shardsvr --replSet dublin --dbpath dublin2 --port 30002 --logpath dublin2.log
mongo --port 30000 --eval 'rs.initiate()'

cd ..
mkdir configServers
cd configServers
mkdir config0
mkdir config1
mkdir config2

start /b mongod --configsvr --replSet configServers --dbpath config0 --port 50000 --logpath config0.log
start /b mongod --configsvr --replSet configServers --dbpath config1 --port 50001 --logpath config1.log
start /b mongod --configsvr --replSet configServers --dbpath config2 --port 50002 --logpath config2.log
pause
REM mongo --shell config.js

start /b mongos --configdb configServers/COM-C136-50818:50000,COM-C136-50818:50001,COM-C136-50818:50002 --port 60000 --logpath mongos.log
start /b mongos --configdb configServers/COM-C136-50818:50000,COM-C136-50818:50001,COM-C136-50818:50002 --port 60001 --logpath mongos.log
start /b mongos --configdb configServers/COM-C136-50818:50000,COM-C136-50818:50001,COM-C136-50818:50002 --port 60002 --logpath mongos.log

pause

REM mongo --port 60000 --eval 'sh.addShard("cork/COM-C136-50818:40000,COM-C136-50818:40001")'
REM Open a seperate cmd, type in mongoimport command with --port 60000 to import the json to 
REM the cluster through mongos

REM Look at the queries and decide what the index is. The index should be composite. The 
REM index will be used as shard key

REM Log in mongos and create index for your database
REM Add your shard key.