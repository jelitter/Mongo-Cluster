createGUI() {
    global
    Menu, Tray, Tip, % config.appTitle "`nisaac.sanchez@mycit.ie"

    Gui, +LastFound +Owner +OwnDialogs +E0x40000 +Resize +MinSize400x600 +MaxSize800x1000 
    Gui, Color, 0xD1E9CD
    Gui, Margin, 10 10

    Gui, add, Picture,      % BgOptions " vBg", % config.appBg
    Gui, add, Picture,      % IconOptions " w100 h-1 vIcon BackgroundTrans", % config.appIcon
    
    Gui, font, Q5 s12 bold, Century Gothic
    Gui, add, Text,     % "x10 y10 ReadOnly BackgroundTrans", % "Mongo Cluster Setup"    


    Gui, font, Q5 s10 norm, Consolas
    
    ; Ports
    Gui, add, Text, % lblFirstPortOptions  " vlblFirstPort ReadOnly BackgroundTrans", % "First Port for a Shard"
    Gui, add, Edit, % fldFirstPortOptions  " vFirstPort BackgroundTrans", 30000
    

    Gui, font, Q5 s11 bold, Century Gothic
    Gui, add, Text, % lblShardNamesTitleOptions " vlblShardNamesTitle Multi BackgroundTrans", % "Shard_Name, number_of nodes (1 per line)`nEx: Cork, 9"
    Gui, font, Q5 s12 norm, Century Gothic
    Gui, add, Edit, % fldShardNamesOptions " vfldShardNames gGetFields", % readConfig()
    Gui, font, Q5 s10 norm, Consolas
    Gui, add, Edit, % fldReport " vfldReport ReadOnly", % generateReport()


    
    Gui, font, Q5 s12, Century Gothic
    Gui, add, Button, % ButtonSetupOptions  " vButtonSetup gButtonSetup Default", % "Setup"
    Gui, add, Button, % ButtonLaunchOptions " vButtonLaunch",        % "Launch"
    Gui, add, Button, % ButtonReloadOptions " vButtonReload",        % "Reload"
    Gui, show, x80 y400, % config.appTitle
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

    ButtonSetupOptions  := "x" config.appWidth-90  "  y" config.appHeight-40  " w80 h30"
    ButtonLaunchOptions := "x" config.appWidth-180 "  y" config.appHeight-40  " w80 h30"
    ButtonReloadOptions := "x" config.appWidth-270 "  y" config.appHeight-40  " w80 h30"

    y := 60
    lblFirstPortOptions := "0x200 x10 y" y " w" config.lblWidth " h" config.fldHeight
    fldFirstPortOptions := "Limit5 Number 0x200 x" config.lblWidth + 10 " y" y " w" config.fldWidth "  h" config.fldHeight " center"


    y += config.fldHeight + 30
    lblShardNamesTitleOptions := "x10 y" y 

    y += config.fldHeight + 30
    fldShardNamesOptions := "0x200 x10 y" y " w" config.appWidth//2 -20 "  h" config.appHeight -y -50
    fldReportOptions := "0x200 x" config.appWidth//2 + 10 " y" y " w" config.appWidth//2 -20 "  h" config.appHeight -y -50

    
    GuiControl, Move, lblFirstPort,              % lblFirstPortOptions
    GuiControl, Move, fldFirstPort,              % fldFirstPortOptions

    GuiControl, Move, lblShardNamesTitle,        % lblShardNamesTitleOptions
    GuiControl, Move, fldShardNames,             % fldShardNamesOptions
    GuiControl, Move, fldReport,                 % fldReportOptions

    GuiControl, MoveDraw, Bg,   % BgOptions
    GuiControl, MoveDraw, Icon,   % IconOptions
    GuiControl, Move, ButtonSetup, % ButtonSetupOptions
    GuiControl, Move, ButtonLaunch, % ButtonLaunchOptions
    GuiControl, Move, ButtonReload, % ButtonReloadOptions

    Return
}

ButtonReload() {
    reload
    return
}


getFields() {
    global
    Gui Submit, NoHide
    cluster.firstPort := FirstPort
    GuiControl,, Report, % generateReport()
    return
}

ButtonSetup() {
    ; cluster := { "clusters"      : 0
    ;               , "shards"        : 0
    ;               , "nodes"         : 0
    ;               , "configServers" : 0 
    ;               , "firstport"     : 0 }
    
    valid := isValidSetup(cluster)
    MsgBox, % "Cluster:`n`nValid: " valid "`n`n" JSON.dump(cluster, "  ")
    return
}

isValidSetup(cluster) {
    getFields()
    valid := ( cluster.clusters > 0
        and cluster.shards > 0
        and cluster.nodes > 0
        and cluster.configservers > 0
        and cluster.firstport > 1024 )

    if (valid) {
        port := cluster.firstPort
        loop, % cluster.nodes
        {
            cluster.ports.push(port)
            port++
        }
    }

    return valid
}

generateReport() {
    ; getFields()
    ; msgbox % JSON.dump(cluster, "  ")
    return % "Report:`n`n" cluster.config
}


GuiEscape:
GuiClose:
    ExitApp


