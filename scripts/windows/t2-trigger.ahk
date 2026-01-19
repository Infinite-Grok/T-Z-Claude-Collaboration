; T² Trigger - Sends "check t2-to-t.md" to Claude terminal
; Part of Project Genesis infrastructure

#Requires AutoHotkey v2.0
#SingleInstance Force

VSCodeClass := "ahk_exe WindowsTerminal.exe"
InputDelay := 150

; Activate VS Code
if !WinExist(VSCodeClass) {
    FileAppend(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . " - ERROR: VS Code not found`n", A_ScriptDir . "\t2-trigger.log")
    ExitApp
}

WinActivate(VSCodeClass)
if !WinWaitActive(VSCodeClass, , 3) {
    FileAppend(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . " - ERROR: Could not activate VS Code`n", A_ScriptDir . "\t2-trigger.log")
    ExitApp
}
Sleep InputDelay

; Click input area
Click 600, 990
Sleep InputDelay

; Clear any existing text
Send "^a"
Sleep 50
Send "{Delete}"
Sleep InputDelay

; Type and send command
SendText "check t2-to-t.md"
Sleep InputDelay
Send "{Enter}"

FileAppend(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . " - T² check triggered`n", A_ScriptDir . "\t2-trigger.log")
ExitApp
