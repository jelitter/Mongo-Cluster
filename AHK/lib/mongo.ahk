createNodeFolders() {
    try {
        for k, v in cluster.shards {
            nodeFolder := cluster.folder "\" k
            if (FileExist(nodeFolder) != "D") {
                FileCreateDir, % nodeFolder
            }
            for n in cluster.shards[k] {
                FileCreateDir, % nodeFolder "\" cluster.shards[k][n].name
            }
        }
    } catch e {
        msgbox % "▪ Error writting file: " e.getMessage() "`nSetup cancelled."
        return
    }

    setupbat := % cluster.folder "\setup.bat"
    FileDelete, % setupbat
    
    setupShards(setupbat)
    setupConfigServer(setupbat)
    connectShards(setupbat)
    setupSharding(setupbat)

    setupKillBat()
    setupImportBat()

    while !FileExist(setupbat) {
        sleep, 100
    }

    run % cluster.folder
    MsgBox, 64, % config.appTitle, % cluster.nshards " cluster folders created successfully"
    return
}

killMongos() {
    run %comspec% /c @taskkill /F /IM mongod.exe > nul 2> nul,, Hide
    run %comspec% /c @taskkill /F /IM mongos.exe >> nul 2> nul,, Hide
    run %comspec% /c @taskkill /F /IM mongo.exe >> nul 2> nul,, Hide
    return
}

setupShards(setupbat) {
    for k, v in cluster.shards {
        if (k !="config") {
            command .= "`n@REM ====== SHARD: " toUpper(k) " ======`n`n"
            for n in cluster.shards[k] {
                shard := k
                name := cluster.shards[k][n].name
                path := k "\" cluster.shards[k][n].name
                port := cluster.shards[k][n].port
                command .= "@start /b mongod --shardsvr --bind_ip " cluster.hostname " --replSet " shard " --dbpath "  path " --port " port " --logpath " shard "\" name ".log`n"
            }
            command .= "@ECHO Started Shard " toUpper(k) " with " cluster.shards[k].Length() " nodes.`n"
        } 
    }

    command .= "@ECHO.`n"
    command .= "@ECHO WAITING FOR MONGOD's... `n"
    command .= "@PAUSE`n"
    command .= "@ECHO.`n"
    command .= "@ECHO Adding shards to replica set...`n"

    for k, v in cluster.shards {
        if (k !="config") {
            for n in cluster.shards[k] {
                port1 := cluster.shards[k][1].port
                port  := cluster.shards[k][n].port

                if (n = 1) {
                    command .= mongoEval(port1, "rs.initiate({_id:'" k "',version:1,members:[{_id:0,host:'" cluster.hostname ":" port1 "'}]})", "Initiating Primary node for " toUpper(k) "...") "`n"
                } else {
                    ; No more than 7 voting members allowed
                    if (n <= 7) {
                        command .= mongoEval(port1, "rs.add({ host: '" cluster.hostname ":" port "'})", "Adding (voting) node " n " to " toUpper(k) "...") "`n"
                    } else {
                        command .= mongoEval(port1, "rs.add({ host: '" cluster.hostname ":" port "', priority: 0, votes: 0 })", "Adding (non-voting) node " n " to " toUpper(k) "...") "`n"
                    }
                }
            }
        }
    }

    FileAppend, % command, % setupbat
    return
}

setupConfigServer(setupbat) {

    shard     := "config"
    path1     := shard "\" cluster.shards["config"][1].name
    path2     := shard "\" cluster.shards["config"][2].name
    path3     := shard "\" cluster.shards["config"][3].name
    cfg_name1 := cluster.shards["config"][1].name
    cfg_name2 := cluster.shards["config"][2].name
    cfg_name3 := cluster.shards["config"][3].name
    cfg_port1 := cluster.shards["config"][1].port
    cfg_port2 := cluster.shards["config"][2].port
    cfg_port3 := cluster.shards["config"][3].port

    ; Setup Config Servers
    command := "`n@REM ====== Config Servers ======`n`n"
    command .= "`n`n@ECHO.`n"
    command .= "@ECHO Starting Config Servers at ports " cfg_port1 ", " cfg_port2 ", " cfg_port3 " ...`n"
    command .= "@start /b mongod --configsvr --replSet config --dbpath " path1 " --port " cfg_port1 " --logpath " "config\" cfg_name1 ".log`n"
    command .= "@start /b mongod --configsvr --replSet config --dbpath " path2 " --port " cfg_port2 " --logpath " "config\" cfg_name2 ".log`n"
    command .= "@start /b mongod --configsvr --replSet config --dbpath " path3 " --port " cfg_port3 " --logpath " "config\" cfg_name3 ".log`n`n"
    
    command .= "`n`n@ECHO.`n"
    command .= "@ECHO WAITING FOR CONFIG SEVERS... `n"
    command .= "@ECHO Make sure you can connect to Mongod at port " cluster.configPort " before continuing...`n"
    command .= "@PAUSE`n`n`n"

    command .= mongoEval(cfg_port1, "rs.initiate({_id:'config',version:1,members:[{_id:0,host:'" cluster.hostname ":" cfg_port1 "'}]})")
    command .= mongoEval(cfg_port1, "rs.add('" cluster.hostname ":" cfg_port2 "')") 
    command .= mongoEval(cfg_port1, "rs.add('" cluster.hostname ":" cfg_port3 "')") 


    ; Setup Routers
    command .= "`n@REM ====== Routers ======`n`n"
    command .= "`n`n@ECHO.`n"
    command .= "@ECHO Starting Routers at ports " cluster.routerPort ", " cluster.routerPort+1 ", " cluster.routerPort+2 " ...`n"
    command .= "@start /b mongos --bind_ip " cluster.hostname " --configdb config/" cluster.hostname ":" cfg_port1 "," cluster.hostname ":" cfg_port2 "," cluster.hostname ":" cfg_port3 " --port " cluster.routerPort    " --logpath mongos1.log`n"
    command .= "@start /b mongos --bind_ip " cluster.hostname " --configdb config/" cluster.hostname ":" cfg_port1 "," cluster.hostname ":" cfg_port2 "," cluster.hostname ":" cfg_port3 " --port " cluster.routerPort +1 " --logpath mongos2.log`n"
    command .= "@start /b mongos --bind_ip " cluster.hostname " --configdb config/" cluster.hostname ":" cfg_port1 "," cluster.hostname ":" cfg_port2 "," cluster.hostname ":" cfg_port3 " --port " cluster.routerPort +2 " --logpath mongos3.log`n`n"
    
    command .= "`n`n@ECHO.`n"
    command .= "@ECHO WAITING FOR ROUTERS... `n"
    command .= "@ECHO Make sure you can connect to Mongod at port " cluster.routerPort " before continuing...`n"
    command .= "@PAUSE`n"

    FileAppend, % command, % setupbat  
    return
}

setupKillBat() {
    command := "@taskkill /F /IM mongod.exe`n"
    command .= "@taskkill /F /IM mongos.exe`n"
    command .= "@taskkill /F /IM mongo.exe`n"
    FileAppend, % command, % cluster.folder "\killmongos.bat"
    return
}

connectShards(setupbat) {
    command := "`n@REM ====== Adding Shards ======`n`n"
    for k, v in cluster.shards {
        if (k !="config") {
            shard := k
            port1 := cluster.shards[k][1].port
            port2 := cluster.shards[k][2].port

            command .= mongoEval(cluster.routerPort, "sh.addShard('" shard "/" cluster.hostname ":" port1 "')") 
            command .= mongoEval(cluster.routerPort, "sh.addShard('" shard "/" cluster.hostname ":" port2 "')") 
        } 
    }
    FileAppend, % command, % setupbat
    return
}

setupImportBat() {
    batFile := cluster.folder "\import.bat"
    jsonFile := A_ScriptDir "\data\restaurants.json"
    command := "mongoimport /port:50000 /c restaurants " jsonFile
    FileDelete, % batFile
    FileAppend, % command, % batFile
    return
}   

setupSharding(setupbat) {

    command .= mongoEval(cluster.routerPort, "sh.enableSharding('test')", "Enabling Sharding...") "`n" 
    command .= mongoEval(cluster.routerPort, "sh.shardCollection('test.restaurants', { cuisine: 1, borough: 1 })", "Adding Shard Key { cuisine, borough }...") "`n"
    command .= mongoEval(cluster.routerPort, "sh.enableBalancing('test.restaurants')", "Enabling Balancer...") "`n"
    command .= mongoEval(cluster.routerPort, "sh.startBalancer()", "Starting Balancer...") "`n"
    command .= mongoEval(cluster.routerPort, "db.settings.save( { _id:'chunksize', value: 1 } )", "Setting chunk size to 1 MB ...", 1) "`n"
    command .= mongoEval(cluster.routerPort, "sh.status('test.restaurants')")
    command .= "`n`n@ECHO.`n"
    command .= "@ECHO Cluster Setup complete. Run 'import.bat' to import JSON data.`n"
    FileAppend, % command , % setupbat
    return
}

mongoEval(port, command, msg="", config=0) {
    dbstring := ""
    if (config = 1) {
        dbstring := " config "
    }
    if (msg != "") {
        return % "@ECHO.`n@ECHO " msg "`n@mongo " dbstring " --port " port " --quiet --eval ""printjson(" command ");""`n"

    } else {
        return % "@mongo " dbstring " --port " port " --quiet --eval ""printjson(" command ");""`n"
    }
}

; mongo config --port 50000 --quiet --eval "db.settings.save( { _id:'chunksize', value: 1 } )"
