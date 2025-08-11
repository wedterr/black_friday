#!/bin/bash

###
# Инициализируем сервер конфигурации
###
docker compose exec -T configSrv mongosh --port 27017 --quiet <<EOF
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
)
EOF


###
# Инициализируем шарды
###
docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1:27018" },
        { _id : 1, host : "shard1-2:27021" },
        { _id : 2, host : "shard1-3:27023" }
      ]
    }
)
EOF

docker compose exec -T shard2 mongosh --port 27019 --quiet <<EOF
rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id : 0, host : "shard2:27019" },
        { _id : 1, host : "shard2-2:27022" },
        { _id : 2, host : "shard2-3:27024" }
      ]
    }
)
EOF

###
# Инициализируем роутер и наполняем его тестовыми данными
###
docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
sh.addShard( "shard1/shard1:27018,shard1-2:27021,shard1-3:27023");
sh.addShard( "shard2/shard2:27019,shard2-2:27022,shard2-3:27024");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
db.helloDoc.countDocuments() 
EOF