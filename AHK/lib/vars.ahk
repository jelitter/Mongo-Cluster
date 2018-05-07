; UI settings
global config := { "appIcon"   : A_ScriptDir "\assets\icon.png"
                 , "appBg"     : A_ScriptDir "\assets\bg.png"
                 , "appTitle"  : "Mongo Cluster"
                 , "appWidth"  : 600
                 , "appHeight" : 800
                 , "fldHeight" : 30
                 , "fldWidth"  : 60
                 , "lblWidth"  : 180 }

; Cluster Settings
global cluster := { "clusters"      : 0
                  , "shards"        : 0
                  , "nodes"         : 0
                  , "configServers" : 0 
                  , "firstport"     : 0 
                  , "ports" : []
                  , "config" : ""
                  , "configPorts" : [ 26050, 26051, 26052 ] }



readConfig() {
    FileRead, res, % "config.txt"
    res := Trim(res)
    cluster.config := res
    return res
}
