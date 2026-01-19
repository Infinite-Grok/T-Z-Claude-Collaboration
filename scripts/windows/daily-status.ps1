$result = & "C:\Users\pkoaw\claude-sync\scripts\windows\hive-status.ps1" 2>&1
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content "C:\Users\pkoaw\claude-sync\logs\daily-status.log" "[$ts] $result"
