; Auto-Sync Trigger for VS Code Claude Extension
; AutoHotkey v2 Script

#Requires AutoHotkey v2.0
#SingleInstance Force

; Configuration
VSCodeClass := "ahk_exe Code.exe"
InputDelay := 150

TriggerSync() {
    logFile := A_ScriptDir . "\auto-sync-trigger.log"
    FileAppend(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . " - Starting sync trigger`n", logFile)

    ; Check if VS Code is running
    if !WinExist(VSCodeClass) {
        FileAppend(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . " - ERROR: VS Code not found`n", logFile)
        return
    }

    ; Activate VS Code
    WinActivate(VSCodeClass)
    if !WinWaitActive(VSCodeClass, , 3) {
        FileAppend(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . " - ERROR: Could not activate VS Code`n", logFile)
        return
    }
    Sleep InputDelay

    ; Calibrated coordinates from original working commit
    clickX := 600
    clickY := 990

    Click clickX, clickY
    Sleep InputDelay

    ; Clear any existing input and type /sync
    Send "^a"
    Sleep 100
    Send "{BackSpace}"
    Sleep InputDelay

    Send "/sync"
    Sleep InputDelay

    Send "{Enter}"
    Sleep InputDelay

    ; Logging disabled to prevent file lock errors
    ; FileAppend(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . " - Sync command sent (clicked at " . clickX . "," . clickY . ")`n", logFile)
}

TriggerSync()
ExitApp
