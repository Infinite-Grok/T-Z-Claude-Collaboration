; Auto-Sync Trigger for VS Code Claude Extension
; AutoHotkey v2 Script
; FIXED: Preserves user's typing, sends clean sync, restores text

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

    ; Click input area
    clickX := 600
    clickY := 990
    Click clickX, clickY
    Sleep InputDelay

    ; Step 1: Save user's clipboard
    savedClipboard := ClipboardAll()

    ; Step 2: Select all and CUT user's text
    A_Clipboard := ""
    Send "^a"
    Sleep 200
    Send "^x"
    Sleep 300
    ClipWait(1, 0)  ; Wait up to 1 sec for clipboard
    userText := A_Clipboard

    ; Step 3: Clear input (in case cut failed)
    Send "{End}"
    Sleep 50
    Send "^+{Home}"
    Sleep 50
    Send "{Delete}"
    Sleep InputDelay

    ; Step 4: Type and send sync command
    SendText "check to-t.md"
    Sleep InputDelay
    Send "{Enter}"
    Sleep 500  ; Wait for send

    ; Step 5: Restore user's text (if any)
    if (userText != "" && userText != "check to-t.md") {
        Sleep 300
        SendText userText
        FileAppend(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . " - Restored " . StrLen(userText) . " chars`n", logFile)
    }

    ; Step 6: Restore original clipboard
    A_Clipboard := savedClipboard

    FileAppend(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . " - Sync sent`n", logFile)
}

TriggerSync()
ExitApp
