@echo off

set STARTDIR=%cd%

cd %STARTDIR%\cluster\cork
@echo ### - Starting shards: Cork
start /b mongod --shardsvr --replSet cork --dbpath cork0 --port 40000 --logpath cork0.log
start /b mongod --shardsvr --replSet cork --dbpath cork1 --port 40001 --logpath cork1.log
start /b mongod --shardsvr --replSet cork --dbpath cork2 --port 40002 --logpath cork2.log

cd %STARTDIR%\cluster\dublin
@echo ### - Starting shards: Dublin
start /b mongod --shardsvr --replSet dublin --dbpath dublin0 --port 30000 --logpath dublin0.log
start /b mongod --shardsvr --replSet dublin --dbpath dublin1 --port 30001 --logpath dublin1.log
start /b mongod --shardsvr --replSet dublin --dbpath dublin2 --port 30002 --logpath dublin2.log

cd %STARTDIR%\cluster\configServers\
@echo ### - Starting config. servers.
start /b mongod --shardsvr --replSet configServers --dbpath config0 --port 50000 --logpath config0.log
start /b mongod --shardsvr --replSet configServers --dbpath config1 --port 50001 --logpath config1.log
start /b mongod --shardsvr --replSet configServers --dbpath config2 --port 50002 --logpath config2.log


PAUSE
cd %STARTDIR%
echo.
mongo --port 50000 rsConfig.js
mongo --port 40000 rsCork.js
mongo --port 30000 rsDublin.js


echo ### - CLUSTER running
cd %STARTDIR%\cluster\configServers

start /b mongos --configdb configServers/localhost:50000,localhost:50001,localhost:50002 --port 60000 --logpath mongos.log
start /b mongos --configdb configServers/localhost:50000,localhost:50001,localhost:50002 --port 60001 --logpath mongos.log
start /b mongos --configdb configServers/localhost:50000,localhost:50001,localhost:50002 --port 60002 --logpath mongos.log

cd %STARTDIR%
PAUSE

@mongo --port 60000 --eval 'sh.addShard("cork/localhost:40000,cork/localhost:40001")'


REM mongoimport --db restaurantdb --collection --port 60000
REM (mongos port)