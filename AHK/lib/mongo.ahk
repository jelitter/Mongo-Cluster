createNodeFolders() {
    for k, v in cluster.shards {
        nodeFolder := cluster.folder "\" k
        ; msgbox % "Creating folder:`n" nodeFolder
        if (FileExist(nodeFolder) != "D") {
            FileCreateDir, % nodeFolder
        }
        for n in cluster.shards[k]
        {
            fileContent := cluster.shards[k][n].name " : " cluster.shards[k][n].port "`n"
            fileName    := nodeFolder "\" cluster.shards[k][n].name ".txt"
            FileDelete, % fileName
            FileAppend, % fileContent, % fileName
            ; if !ErrorLevel
            ;     msgbox % "▪ Creating node :`n" fileName
            ; else
            ;     msgbox % "▪ Error writting file: " A_LastError
        }
    }
    run % cluster.folder
    MsgBox, 64, % config.appTitle, % cluster.nshards " cluster folders created successfully"
    return
}

killMongos() {
    run %comspec% /c @taskkill /F /IM mongod.exe,, Hide
    if ErrorLevel
        MsgBox, 48, % config.appTitle, % "Error killing mongod services: " A_LastError

    run %comspec% /c @taskkill /F /IM mongos.exe,, Hide
    if ErrorLevel
        MsgBox, 48, % config.appTitle, % "Error killing mongos services: " A_LastError
    
    return
}

setupShard() {
    ; TO DO
    start /b mongod --shardsvr --replSet cork --dbpath cork0 --port 40000 --logpath cork0.log
    start /b mongod --shardsvr --replSet cork --dbpath cork1 --port 40001 --logpath cork1.log
    start /b mongod --shardsvr --replSet cork --dbpath cork2 --port 40002 --logpath cork2.log
    return
}

setupConfigServer() {
    ; TO DO
    start /b mongos --configdb configServers/localhost:50000,localhost:50001,localhost:50002 --port 60000 --logpath mongos.log
    start /b mongos --configdb configServers/localhost:50000,localhost:50001,localhost:50002 --port 60001 --logpath mongos.log
    start /b mongos --configdb configServers/localhost:50000,localhost:50001,localhost:50002 --port 60002 --logpath mongos.log
    return
}

connectShards() {
    ; TO DO
    mongo --port 50000 rsConfig.js
    mongo --port 40000 rsCork.js
    mongo --port 30000 rsDublin.js
    return
}

launchCluster() {
    ; TO DO
    @mongo --port 60000 --eval 'sh.addShard("cork/localhost:40000,cork/localhost:40001")'
    return
}
