; Calibration Script - Moves cursor to target and holds
; Run this to see where the cursor lands, then tell me to adjust
#Requires AutoHotkey v2.0

; Target coordinates - adjust these
targetX := 600
targetY := 990

; Activate VS Code first
WinActivate("ahk_exe Code.exe")
WinWaitActive("ahk_exe Code.exe", , 3)
Sleep 200

; Move cursor to target (no click)
MouseMove targetX, targetY

; Show tooltip at cursor position
ToolTip "Cursor at: " . targetX . ", " . targetY . "`nPress Escape to close"

; Wait for Escape key to exit
Escape::ExitApp
