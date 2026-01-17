; Auto-Sync Trigger for VS Code Claude Extension
; AutoHotkey v2 Script
;
; Uses click coordinates to focus Claude input
; (Ctrl+Esc conflicts with Windows Sync Center)

#Requires AutoHotkey v2.0

; Configuration
VSCodeClass := "ahk_exe Code.exe"
InputDelay := 150

; Claude input coordinates - ADJUST THESE based on your screen layout
; These target the input box at the bottom of VS Code Claude panel
ClaudeInputX := 700   ; X coordinate (center-ish of Claude input)
ClaudeInputY := 715   ; Y coordinate (near bottom where input is)

TriggerSync() {
    logFile := A_ScriptDir . "\auto-sync-trigger.log"
    FileAppend(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . " - Starting sync trigger`n", logFile)

    ; Check if VS Code is running
    if !WinExist(VSCodeClass) {
        FileAppend(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . " - ERROR: VS Code not found`n", logFile)
        return
    }

    ; Get VS Code window position to calculate relative click position
    WinGetPos(&winX, &winY, &winW, &winH, VSCodeClass)

    ; Activate VS Code
    WinActivate(VSCodeClass)
    if !WinWaitActive(VSCodeClass, , 3) {
        FileAppend(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . " - ERROR: Could not activate VS Code`n", logFile)
        return
    }
    Sleep InputDelay

    ; Click on the Claude input area (bottom of the panel)
    ; Calibrated coordinates (600, 990)
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

    FileAppend(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . " - Sync command sent (clicked at " . clickX . "," . clickY . ")`n", logFile)
}

TriggerSync()
ExitApp
