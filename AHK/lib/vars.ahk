global MAX_NODES := 53
     , MIN_NODES := 3 

; UI settings
global config := { "appIcon"   : A_ScriptDir "\assets\icon.png"
                 , "appBg"     : A_ScriptDir "\assets\bg.png"
                 , "appTitle"  : "MongoDB Cluster"
                 , "appWidth"  : 1000
                 , "appHeight" : 800
                 , "fldHeight" : 30
                 , "fldWidth"  : 60
                 , "lblWidth"  : 180 
                 , "sufix" : "R00156019" }

; Cluster Settings
global cluster := { "shards"        : []
                  , "nshards"       : 0
                  , "configServers" : 3 
                  , "firstport"     : 30000 
                  , "config"        : ""
                  , "configPort"    : 26050 
                  , "routerPort"    : 50000
                  , "folder" : "" }

