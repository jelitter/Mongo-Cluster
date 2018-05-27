#Persistent
#SingleInstance, force
#NoEnv
SetBatchLines -1
ListLines Off
SetControlDelay, 0
SetWinDelay, 0
SetKeyDelay, 0
SetMouseDelay, 0
#Include lib\vars.ahk

updateControlPositions()
createGUI()
Return

#Include lib\ui.ahk
#Include lib\util.ahk
#Include lib\mongo.ahk
#Include lib\JSON.ahk
