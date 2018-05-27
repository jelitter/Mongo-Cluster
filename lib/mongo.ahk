;
; Isaac Sanchez, 2018
; https://github.com/jelitter/Mongo-Cluster
;

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
    setupRemoveBat()

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
            command .= echo("Started Shard " toUpper(k) " with " cluster.shards[k].Length() " nodes.", "green")
        } 
    }

    command .= echo("WAITING FOR MONGOD's...", "yellow")
    command .= "@PAUSE`n"

    command .= echo("Adding shards to replica set...")

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
    command := "`n`n@REM ====== Config Servers ======`n`n"
    command .= echo("Starting Config Servers at ports " cfg_port1 ", " cfg_port2 ", " cfg_port3 " ...", "green")
    command .= "@start /b mongod --configsvr --replSet config --dbpath " path1 " --port " cfg_port1 " --logpath " "config\" cfg_name1 ".log`n"
    command .= "@start /b mongod --configsvr --replSet config --dbpath " path2 " --port " cfg_port2 " --logpath " "config\" cfg_name2 ".log`n"
    command .= "@start /b mongod --configsvr --replSet config --dbpath " path3 " --port " cfg_port3 " --logpath " "config\" cfg_name3 ".log`n`n"
    
    command .= echo("WAITING FOR CONFIG SEVERS...`n Make sure you can connect to Mongod at port " cluster.configPort " before continuing... ", "yellow")
    command .= "`n@PAUSE`n`n`n"

    command .= mongoEval(cfg_port1, "rs.initiate({_id:'config',version:1,members:[{_id:0,host:'" cluster.hostname ":" cfg_port1 "'}]})")
    command .= mongoEval(cfg_port1, "rs.add('" cluster.hostname ":" cfg_port2 "')") 
    command .= mongoEval(cfg_port1, "rs.add('" cluster.hostname ":" cfg_port3 "')") 


    ; Setup Routers
    command .= "`n`n@REM ====== Routers ======`n`n"
    command .= echo("Starting Routers at ports " cluster.routerPort ", " cluster.routerPort+1 ", " cluster.routerPort+2 " ...", "green")
    command .= "@start /b mongos --bind_ip " cluster.hostname " --configdb config/" cluster.hostname ":" cfg_port1 "," cluster.hostname ":" cfg_port2 "," cluster.hostname ":" cfg_port3 " --port " cluster.routerPort    " --logpath mongos1.log`n"
    command .= "@start /b mongos --bind_ip " cluster.hostname " --configdb config/" cluster.hostname ":" cfg_port1 "," cluster.hostname ":" cfg_port2 "," cluster.hostname ":" cfg_port3 " --port " cluster.routerPort +1 " --logpath mongos2.log`n"
    command .= "@start /b mongos --bind_ip " cluster.hostname " --configdb config/" cluster.hostname ":" cfg_port1 "," cluster.hostname ":" cfg_port2 "," cluster.hostname ":" cfg_port3 " --port " cluster.routerPort +2 " --logpath mongos3.log`n`n"
    
    command .= "`n`n@ECHO.`n"
    command .= echo("WAITING FOR ROUTERS... `n Make sure you can connect to Mongod at port " cluster.routerPort " before continuing...", "yellow")
    command .= "@PAUSE`n"

    FileAppend, % command, % setupbat  
    return
}

setupKillBat() {
    command := "@taskkill /F /IM mongod.exe`n"
    command .= "@taskkill /F /IM mongos.exe`n"
    command .= "@taskkill /F /IM mongo.exe`n"
    command .= "@cd .."
    command .= echo("All Mongod, Mongos and Mongo killed.", "green")
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
    command := echo("Importing Restaurant DB from JSON file... ") 
    command .= "mongoimport --db restaurantdb /port:50000 /c restaurants " jsonFile
    command .= echo("`n Data has been imported `n", "green")  
    command .= echo("`n When you want to remove the cluster, run 'remove.bat'. `n", "yellow")

    FileDelete, % batFile
    FileAppend, % command, % batFile
    return
}   

setupRemoveBat() {
    
    ;  1. Remove secondary nodes
    ;  Connect to main node
    ;  rs.remove(”hostname:port number”)
    ; 
    ;  2. Remove Shard:
    ;  mongo admin --port 50000 --eval "db.adminCommand( { removeShard: 'limerick' } )"
    ; 
    ;  3. Wait for draining... (check with same command)
    ; 
    ;  4. Move DB to primary node:
    ;  mongo admin --port 50000 --eval "db.runCommand( { movePrimary: 'restaurantdb', to: 'cork' } )"
    ; 
    ;  5. Drop collection ?
    ; 
    ;  6. Remove primary nodes 
    ;  use local
    ;  db.system.replset.find() 
    ;  var mainServer = db.system.replset.find() 
    ;  db.system.replset.remove(mainServer)
    ; 
    ;  7. Shutdown Servers
    ;  mongo admin --port 50000 --eval "db.shutdownServer({timeoutSecs: 60});"


    batFile := cluster.folder "\remove.bat"
    command := echo("Removing Replica Set...")

    for k, v in cluster.shards {
        if (k !="config") {
            for n in cluster.shards[k] {
                port1 := cluster.shards[k][1].port
                port  := cluster.shards[k][n].port

                if (n != 1) {
                    command .= mongoEval(port1, "rs.remove('" cluster.hostname ":" port "')", "Removing secondary node " n " from " toUpper(k)) "`n"
                }
            }
        }
    }

    command .= echo("All secondary nodes from all shards were removed.", "green")

    for k, v in cluster.shards {
        if (k !="config") {           
            command .= mongoEval(cluster.routerPort
                , "db.adminCommand( { removeShard: '" k "' } )"
                , "Removing Shard " toUpper(k) " - WARNING: Wait for draining to complete before continuing`n It may take several minutes.`n Check with: db.adminCommand( { removeShard: '" k "' } ) "
                , "admin")
            command .= "`n@ECHO.`n@PAUSE`n"

            command .= mongoEval(port1
                ; , " (function remove() { var mainNode = db.system.replset.find(); db.system.replset.remove(mainNode)})(); "
                , "{var mainNode = db.system.replset.find(); db.system.replset.remove(mainNode)}"
                , "Removing main node from " toUpper(k)
                , "local") "`n`n"
            command .= "`n@ECHO.`n@PAUSE`n`n"
        }
    }

    command .= mongoEval(cluster.routerPort
        , "db.shutdownServer({timeoutSecs: 60})"
        , "Shutting down server..."
        , "admin") "`n`n"
    command .= echo("Server has been shut down.", "green")
    FileAppend, % command, % batFile
    return
}


setupSharding(setupbat) {
    command .= mongoEval(cluster.routerPort, "sh.enableSharding('restaurantdb')", "Enabling Sharding...") "`n" 
    command .= mongoEval(cluster.routerPort, "sh.shardCollection('restaurantdb.restaurants', { cuisine: 1, borough: 1 })", "Adding Shard Key { cuisine, borough }...") "`n"
    command .= mongoEval(cluster.routerPort, "db.settings.save( { _id:'chunksize', value: 1 } )", "Setting chunk size to 1 MB ...", "config") "`n"
    command .= mongoEval(cluster.routerPort, "sh.enableBalancing('restaurantdb.restaurants')", "Enabling Balancer...") "`n"
    command .= mongoEval(cluster.routerPort, "sh.startBalancer()", "Starting Balancer...") "`n"
    command .= mongoEval(cluster.routerPort, "sh.status('restaurantdb.restaurants')")
    command .= "`n`n@ECHO.`n"
    command .= echo(" Cluster Setup complete. Run 'import.bat' to import JSON data.", "green")
    FileAppend, % command , % setupbat
    return
}

mongoEval(port, command, msg="", db="") {

    colour := InStr(msg, "WARNING") ? "yellow" : "blue"

    if (msg != "") {
        return % "@ECHO.`n" echo(msg, colour) "`nmongo " db " --port " port " --quiet --eval ""printjson(" command ");""`n"

    } else {
        return % "mongo " db " --port " port " --quiet --eval ""printjson(" command ");""`n"
    }
}

echo(message, colour="blue") {

    if (substr(A_OSVersion, 1, 2) = "10") {
        ; Console colours only supported from Windows 10 on
        escapecodes  := { "blue" : "46m", "green" : "102m", "yellow" : "103m" }
        colourPrefix := "["
        colourSufix  := " [0m"  
    }

    message := StrReplace(message, "`n", "`n@ECHO ")

    return % "`n@ECHO.`n"
    . "@ECHO " config.line "`n" 
    . "@ECHO " colourPrefix escapecodes[colour] " " message colourSufix  
    . "`n@ECHO " config.line "`n" 
}