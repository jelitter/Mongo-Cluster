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
            for n in cluster.shards[k] {
                shard := k
                name := cluster.shards[k][n].name
                path := k "\" cluster.shards[k][n].name
                port := cluster.shards[k][n].port
                command := "start /b mongod --shardsvr --replSet " shard " --dbpath "  path " --port " port " --logpath " shard "\" name ".log`n"
                FileAppend, % command, % setupbat
            }
            FileAppend, % "`n", % setupbat
        } 
    }

    FileAppend, % "`n", % setupbat
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

    command := "start /b mongod --configsvr --replSet config --dbpath " path1 " --port " cfg_port1 " --logpath " "config\" cfg_name1 ".log`n"
    command .= "start /b mongod --configsvr --replSet config --dbpath " path2 " --port " cfg_port2 " --logpath " "config\" cfg_name2 ".log`n"
    command .= "start /b mongod --configsvr --replSet config --dbpath " path3 " --port " cfg_port3 " --logpath " "config\" cfg_name3 ".log`n`n"
    
    command .= "start /b mongo --port " cfg_port1 " --eval 'rs.initiate()'`n"
    command .= "start /b mongo --port " cfg_port1 " --eval 'rs.add(""localhost:" cfg_port2 """)'`n"
    command .= "start /b mongo --port " cfg_port1 " --eval 'rs.add(""localhost:" cfg_port3 """)'`n`n"

    ; Setup Routers
    command .= "start /b mongos --configdb config/localhost:" cfg_port1 ",localhost:" cfg_port2 ",localhost:" cfg_port3 " --port " cluster.routerPort " --logpath mongos1.log`n"
    command .= "start /b mongos --configdb config/localhost:" cfg_port1 ",localhost:" cfg_port2 ",localhost:" cfg_port3 " --port " cluster.routerPort +1 " --logpath mongos2.log`n"
    command .= "start /b mongos --configdb config/localhost:" cfg_port1 ",localhost:" cfg_port2 ",localhost:" cfg_port3 " --port " cluster.routerPort +2 " --logpath mongos3.log`n`n"


    FileAppend, % command, % setupbat
    
    ; start /b mongos --configdb configServers/localhost:50000,localhost:50001,localhost:50002 --port 60000 --logpath mongos.log
    ; start /b mongos --configdb configServers/localhost:50000,localhost:50001,localhost:50002 --port 60001 --logpath mongos.log
    ; start /b mongos --configdb configServers/localhost:50000,localhost:50001,localhost:50002 --port 60002 --logpath mongos.log
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

    for k, v in cluster.shards {
        if (k !="config") {
            shard := k
            port1 := cluster.shards[k][1].port
            port2 := cluster.shards[k][2].port
            command := "start /b mongo --port " cluster.routerPort " --eval 'sh.addShard(""" shard "/localhost:" port1 ",localhost:" port2 """)'`n"
            FileAppend, % command, % setupbat
        } 
    }

    FileAppend, % "mongo --port " cluster.routerPort " --eval 'sh.status()'`n`n", % setupbat
    return
}

launchCluster() {
    ; TO DO
    ; @mongo --port 60000 --eval 'sh.addShard("cork/localhost:40000,cork/localhost:40001")'
    return
}
