createNodeFolders() {
    for k, v in cluster.shards {
        nodeFolder := cluster.folder "\" k
        ; msgbox % "Creating folder:`n" nodeFolder
        if (FileExist(nodeFolder) != "D") {
            FileCreateDir, % nodeFolder
        }
        for n in cluster.shards[k] {
            fileContent := cluster.shards[k][n].name " : " cluster.shards[k][n].port "`n"
            ; fileName    := nodeFolder "\" cluster.shards[k][n].name ".txt"
            FileCreateDir, % nodeFolder "\" cluster.shards[k][n].name
            ; FileDelete, % fileName
            ; FileAppend, % fileContent, % fileName
            if ErrorLevel {
                msgbox % "▪ Error writting file: " A_LastError "`nSetup cancelled."
                return
            }
        }
    }

    setupbat := % cluster.folder "\setup.bat"
    FileDelete, % setupbat
    
    setupShards(setupbat)
    setupConfigServer(setupbat)
    connectShards(setupbat)

    setupKillBat()
    run % cluster.folder
    MsgBox, 64, % config.appTitle, % cluster.nshards " cluster folders created successfully"
    return
}

killMongos() {
    folder := cluster.folder
    FileDelete, % cluster.folder "\output.txt"
    run %comspec% /c @taskkill /F /IM mongod.exe > %folder%\output.txt 2>> %folder%\output.txt,, Hide
    if ErrorLevel
        FileAppend, % "Error killing mongod services`n", % cluster.folder "\output.txt"

    run %comspec% /c @taskkill /F /IM mongos.exe >> %folder%\output.txt 2>> %folder%\output.txt,, Hide
    if ErrorLevel
            FileAppend, % "Error killing mongos services`n", % cluster.folder "\output.txt"

    run %comspec% /c @taskkill /F /IM mongo.exe >> %folder%\output.txt 2>> %folder%\output.txt,, Hide
    if ErrorLevel
            FileAppend, % "Error killing mongo client`n", % cluster.folder "\output.txt"
    return
}

setupShards(setupbat) {
    for k, v in cluster.shards {
        if (k !="config") {
            command .= "`n@REM ====== Shard: " toUpper(k) " ======`n`n"
            for n in cluster.shards[k] {
                shard := k
                name := cluster.shards[k][n].name
                path := k "\" cluster.shards[k][n].name
                port := cluster.shards[k][n].port
                command .= "@start /b mongod --shardsvr --replSet " shard " --dbpath "  path " --port " port " --logpath " shard "\" name ".log`n"
            }
            command .= "`n`n@ECHO WAITING FOR " toUpper(k) " SHARDS... `n"
            command .= "@PAUSE`n"
            command .= "`n"

            for n in cluster.shards[k] {
                port1 := cluster.shards[k][1].port
                port  := cluster.shards[k][n].port

                if (n = 1) {
                    command .= mongoEval(port1, "rs.initiate()", "Initiating primary node for " k "...")
                    ; command .= "@mongo --port " port1 " --eval ""rs.initiate()""`n"  
                } else {

                    command .= mongoEval(port1, "rs.add('localhost:" port "')", "Adding node " n " to " k "...") 
                    ; command .= "@mongo --port " port1 " --eval ""rs.add('localhost:" port "')""`n"
                }
            }
            command .= "`n"
        } 
    }
    command .= "`n"
    FileAppend, % command, % setupbat
    return
}

setupConfigServer(setupbat) {

    shard := "config"
    cfg_name1 := cluster.shards["config"][1].name
    cfg_name2 := cluster.shards["config"][2].name
    cfg_name3 := cluster.shards["config"][3].name
    path1 := shard "\" cluster.shards["config"][1].name
    path2 := shard "\" cluster.shards["config"][2].name
    path3 := shard "\" cluster.shards["config"][3].name
    cfg_port1 := cluster.shards["config"][1].port
    cfg_port2 := cluster.shards["config"][2].port
    cfg_port3 := cluster.shards["config"][3].port

    command := "`n@REM ====== Config Servers ======`n`n"
    command .= "@start /b mongod --configsvr --replSet config --dbpath " path1 " --port " cfg_port1 " --logpath " "config\" cfg_name1 ".log`n"
    command .= "@start /b mongod --configsvr --replSet config --dbpath " path2 " --port " cfg_port2 " --logpath " "config\" cfg_name2 ".log`n"
    command .= "@start /b mongod --configsvr --replSet config --dbpath " path3 " --port " cfg_port3 " --logpath " "config\" cfg_name3 ".log`n`n"
    
    command .= "`n`n@ECHO WAITING FOR CONFIG SEVERS... `n"
    command .= "@PAUSE`n`n`n"

    command .= mongoEval(cfg_port1, "rs.initiate()")
    command .= mongoEval(cfg_port1, "rs.add('localhost:" cfg_port2 "')") 
    command .= mongoEval(cfg_port1, "rs.add('localhost:" cfg_port3 "')") 

    ; Setup Routers
    command .= "`n@REM ====== Routers ======`n`n"
    command .= "@start /b mongos --configdb config/localhost:" cfg_port1 ",localhost:" cfg_port2 ",localhost:" cfg_port3 " --port " cluster.routerPort    " --logpath mongos1.log`n"
    command .= "@start /b mongos --configdb config/localhost:" cfg_port1 ",localhost:" cfg_port2 ",localhost:" cfg_port3 " --port " cluster.routerPort +1 " --logpath mongos2.log`n"
    command .= "@start /b mongos --configdb config/localhost:" cfg_port1 ",localhost:" cfg_port2 ",localhost:" cfg_port3 " --port " cluster.routerPort +2 " --logpath mongos3.log`n`n"
    

    command .= "`n`n@ECHO WAITING FOR ROUTERS... `n"
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

            command .= mongoEval(cluster.routerPort, "sh.addShard('" shard "/localhost:" port1 "')") 
            command .= mongoEval(cluster.routerPort, "sh.addShard('" shard "/localhost:" port2 "')") 
            ; command .= "@mongo --port " cluster.routerPort " --eval ""sh.addShard('" shard "/localhost:" port1 "')""`n"
            ; command .= "@mongo --port " cluster.routerPort " --eval ""sh.addShard('" shard "/localhost:" port2 "')""`n"
        } 
    }

    command .= mongoEval(cluster.routerPort, "sh.status()")"`n"
    ; command .= "`n@mongo --port " cluster.routerPort " --eval ""sh.status()""`n`n"
    FileAppend, % command, % setupbat
    return
}

launchCluster() {
    ; TO DO
    ; @@mongo --port 60000 --eval 'sh.addShard("cork/localhost:40000,cork/localhost:40001")'
    return
}


mongoEval(port, command, msg="") {
    if (msg != "") {
        return % "@ECHO " msg "`n@mongo --port " port " --quiet --eval ""printjson(" command ");""`n"

    } else {
        return % "@mongo --port " port " --quiet --eval ""printjson(" command ");""`n"
    }
}