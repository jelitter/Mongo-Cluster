#!/bin/bash

pkill mongod
pkill mongos

rm -rf cluster
sleep 4
mkdir cluster
cd cluster 
mkdir cork
mkdir dublin
cd cork
mkdir cork0
mkdir cork1
mkdir cork2

mongod --shardsvr --replSet cork --dbpath cork0 --port 40000 --logpath cork0.log --fork
mongod --shardsvr --replSet cork --dbpath cork1 --port 40001 --logpath cork1.log --fork
mongod --shardsvr --replSet cork --dbpath cork2 --port 40002 --logpath cork2.log --fork

mongo --port 40000 --eval 'rs.initiate()'
mongo --port 40000 --eval 'rs.add("localhost:40001")'
mongo --port 40000 --eval 'rs.addArb("localhost:40002")'

cd ..
cd dublin
mkdir dublin0
mkdir dublin1
mkdir dublin2
mongod --shardsvr --replSet dublin --dbpath dublin0 --port 50000 --logpath dublin0.log --fork
mongod --shardsvr --replSet dublin --dbpath dublin1 --port 50001 --logpath dublin1.log --fork
mongod --shardsvr --replSet dublin --dbpath dublin2 --port 50002 --logpath dublin2.log --fork

mongo --port 50000 --eval 'rs.initiate()'
mongo --port 50000 --eval 'rs.add("localhost:50001")'
mongo --port 50000 --eval 'rs.addArb("localhost:50002")'

cd ..
mkdir configurationServers
cd configurationServers
mkdir config0
mkdir config1
mkdir config2
mongod --configsvr --replSet configurationServers --dbpath config0 --port 60000 --logpath config0.log --fork
mongod --configsvr --replSet configurationServers --dbpath config1 --port 60001 --logpath config1.log --fork
mongod --configsvr --replSet configurationServers --dbpath config2 --port 60002 --logpath config2.log --fork

mongo --port 60000 --eval 'rs.initiate()'
mongo --port 60000 --eval 'rs.add("localhost:60001")'
mongo --port 60000 --eval 'rs.add("localhost:60002")'

mongos --configdb configurationServers/localhost:60000,localhost:60001,localhost:60002 --port 40004 --logpath mongos.log --fork
mongos --configdb configurationServers/localhost:60000,localhost:60001,localhost:60002 --port 40005 --logpath mongos.log --fork
mongos --configdb configurationServers/localhost:60000,localhost:60001,localhost:60002 --port 40006 --logpath mongos.log --fork

mongo --port 40004 --eval 'sh.addShard("cork/localhost:40000,localhost:40001")'
mongo --port 40004 --eval 'sh.addShard("dublin/localhost:50000,localhost:50001")'

mongo --port 40004 --eval 'sh.status()'

#suppose your shard key is student id, suppose the shard key in the first chunk in shard A is range from 0 to 200 will be in shard A
#Suppose the shard key in the first chunk in shard B is range from 201 to 300 will be in shard B
#shard key	shard		chunk
######################################
#0-200		A		1
#201-300	B		1
#!------------------------------------------------------------------------------------------------!
#mongoimport command with port of mongos to import the JSON file to the cluster through mongos
#dbs.show
#!------------------------------------------------------------------------------------------------!
mongoimport --db restaurantdb --collection restaurants --drop --file restaurants_dataset.json --port 40004
#where does shard key come from
