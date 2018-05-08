createGUI() {
    global
    Menu, Tray, Tip, % config.appTitle "`nisaac.sanchez@mycit.ie"

    Gui, +LastFound +Owner +OwnDialogs +E0x40000 +Resize +MinSize600x600 ; +MaxSize800x1000 
    Gui, Color, 0xD1E9CD
    Gui, Margin, 10 10

    Gui, add, Picture,      % BgOptions " vBg", % config.appBg
    Gui, add, Picture,      % IconOptions " w100 h-1 vIcon BackgroundTrans", % config.appIcon
    
    Gui, font, Q5 s12 bold, Century Gothic
    Gui, add, Text,     % "x10 y10 ReadOnly BackgroundTrans", % config.appTitle " Setup"    

    Gui, font, Q5 s10 norm, Consolas
    Gui, add, Text, % lblFirstPortOptions  " vlblFirstPort ReadOnly BackgroundTrans", % "First Port for a Shard"
    Gui, add, Edit, % FirstPortOptions  " vFirstPort gGetFields BackgroundTrans", 30000
   
    Gui, font, Q5 s11 bold, Century Gothic
    Gui, add, Text, % lblShardNamesTitleOptions " vlblShardNamesTitle Multi BackgroundTrans", % "Shard_Name, number_of nodes (1 per line)`nEx: Cork, 9  (max " MAX_NODES " nodes per shard)"
    Gui, font, Q5 s12 norm, Century Gothic
    Gui, add, Edit, % ShardNamesOptions " vShardNames gGetFields", % readConfig()
    Gui, font, Q5 s10 norm, Consolas
    Gui, add, Edit, % ReportOptions " vReport ReadOnly", % generateReport()
    
    Gui, font, Q5 s12, Century Gothic
    Gui, add, Text,   % FolderDisplayOptions      " vFolderDisplay BackgroundTrans", % cluster.folder
    Gui, add, Button, % ButtonSelectFolderOptions " vButtonSelectFolder gSelectFolder ",  % "Browse"
    Gui, add, Button, % ButtonReloadOptions       " vButtonReload",        % "Reload"
    Gui, add, Button, % ButtonLaunchOptions       " vButtonLaunch",        % "Launch"
    Gui, add, Button, % ButtonSetupOptions        " vButtonSetup gButtonSetup Default", % "Setup"
    Gui, show, AutoSize, % config.appTitle " - Isaac Sanchez"
    getFields()
    Return
}


GuiSize:
{
    config.appWidth := A_GuiWidth, config.appHeight := A_GuiHeight
    updateControlPositions()
    Return
}

updateControlPositions() {
    global
    IconOptions   := "x" config.appWidth-90 " y10 BackgroundTrans"
    BgOptions := "x0 y0 w" config.appWidth+10 " h" config.appHeight+10 " BackgroundTrans"

    
    ButtonSelectFolderOptions  := "x10  y" config.appHeight-40  " w80 h30"
    FolderDisplayOptions       := "0x200 x100  y" config.appHeight-40  " w" config.appWidth-340 " h30 "
    ButtonSetupOptions         := "x" config.appWidth- 90 "  y" config.appHeight-40  " w80 h30"
    ButtonLaunchOptions        := "x" config.appWidth-180 "  y" config.appHeight-40  " w80 h30"
    ButtonReloadOptions        := "x" config.appWidth-270 "  y" config.appHeight-40  " w80 h30"

    y := 60
    lblFirstPortOptions := "0x200 x10 y" y " w" config.lblWidth " h" config.fldHeight
    FirstPortOptions := "Limit5 Number 0x200 x" config.lblWidth + 10 " y" y " w" config.fldWidth "  h" config.fldHeight " center"

    y += config.fldHeight + 30
    lblShardNamesTitleOptions := "x10 y" y 

    y += config.fldHeight + 30
    ShardNamesOptions := "0x200 x10 y" y " w" config.appWidth//2 -20 -100 "  h" config.appHeight -y -50
    ReportOptions := "0x200 x" config.appWidth//2 + 10 -100 " y" y " w" config.appWidth//2 -20 +100 "  h" config.appHeight -y -50
    

    GuiControl, Move, lblFirstPort,        % lblFirstPortOptions
    GuiControl, Move, FirstPort,           % FirstPortOptions
    GuiControl, Move, lblShardNamesTitle,  % lblShardNamesTitleOptions
    GuiControl, Move, ShardNames,          % ShardNamesOptions
    GuiControl, Move, Report,              % ReportOptions
    GuiControl, MoveDraw, Bg,              % BgOptions
    GuiControl, MoveDraw, Icon,            % IconOptions
    
    GuiControl, Move, ButtonSelectFolder,  % ButtonSelectFolderOptions
    GuiControl, Move, FolderDisplay,       % FolderDisplayOptions
    GuiControl, Move, ButtonSetup,         % ButtonSetupOptions
    GuiControl, Move, ButtonLaunch,        % ButtonLaunchOptions
    GuiControl, Move, ButtonReload,        % ButtonReloadOptions
    Return
}

ButtonReload() {
    reload
    return
}


getFields() {
    global
    Gui Submit, NoHide
    cluster.firstPort := firstPort
    cluster.config := clean(ShardNames)
    GuiControl,, Report, % generateReport()
    return
}

ButtonSetup() {
    valid := isValidSetup(cluster)
    if (valid) {
        killMongos()
        createNodeFolders()
    }
    ; MsgBox, % "Cluster:`n`nValid: " valid "`n`n" JSON.dump(cluster, "  ")
    return
}

selectFolder() {
    FileSelectFolder, folder, , % A_ScriptDir, % "Select root folder for Cluster `n(a ""cluster"" folder will be created in it)"
    if !ErrorLevel {
        folder := RegExReplace(folder, "\\$")
        newFolder := folder "\cluster"

        if InStr(FileExist(newFolder), "D") {
            MsgBox, 52, % config.appTitle, % newFolder "`n`nFolder already exists`nOverwrite?`n`n(Warning: all contet will be deleted)"
            IfMsgBox, Yes
            {
                FileRemoveDir, % newFolder, 1
                FileCreateDir, % newFolder
                MsgBox, 64, % config.appTitle, % newFolder "`n`ncreated"
            }
        } else {
            MsgBox, 68, % config.appTitle, % newFolder "`n`nCreate folder?"
            IfMsgBox, Yes
            {
                FileCreateDir, % newFolder
                MsgBox, 64, % config.appTitle, % newFolder "`n`ncreated"
            }
        }

        cluster.folder := newFolder
        GuiControl,, FolderDisplay, % cluster.folder
    }
    return
}

isValidSetup(cluster) {
    valid := ( cluster.nshards > 1
        and cluster.totalNodes > 3
        and cluster.firstport > 1024 
        and cluster.folder != ""
        and FileExist(cluster.folder) = "D" )
    return valid
}

generateReport() {
    cfg := clean(cluster.config)
    shards := StrSplit(cfg, "`n")
    finalShards := []
    finalShards["config"] := 3

    for s in shards {
        str := Trim(shards[s])
        if RegExMatch(str, "(\S*)\,\s*?(\d+)", match) {
            finalShards[match1] := match2
        }
    }
    cluster.nshards := 0
    cluster.totalNodes := 0
    index := 0
  
    for k, v in finalShards {
        if (k = "config") {
            port := cluster.configPort 
        } else {
            index++
            port := cluster.firstPort + (index -1) * 200 
        }
        
        nnodes := min(v, MAX_NODES)
        cluster.totalNodes += nnodes
        cluster.nshards++

        finalShards[k] := []
        loop, % nnodes
        {
            finalShards[k].push({ "name" : toLower(k) "_" (A_Index - 1) "_" config.sufix, "port" : port++ })
        }
    }

    cluster.shards     := finalShards
    return % cluster.nshards " shards, " cluster.totalNodes " nodes`n`n" JSON.dump(cluster, "  ")
}




GuiEscape:
GuiClose:
    ExitApp


