# Hive CLI - All commands in one
param(
    [Parameter(Position=0)]
    [string]$Command,
    [Parameter(Position=1, ValueFromRemainingArguments)]
    [string[]]$Args
)

$ScriptDir = "$env:USERPROFILE\claude-sync\scripts\windows"

switch ($Command) {
    "status"   { & "$ScriptDir\hive-status.ps1" }
    "health"   { & "$ScriptDir\hive-health.ps1" }
    "test"     { & "$ScriptDir\hive-test.ps1" }
    "ping"     { & "$ScriptDir\hive-ping.ps1" }
    "history"  { & "$ScriptDir\hive-history.ps1" @Args }
    "backup"   { & "$ScriptDir\hive-backup.ps1" }
    "update"   { & "$ScriptDir\hive-update.ps1" }
    "diag"     { & "$ScriptDir\hive-diag.ps1" }
    "logs"     { Get-Content "$env:USERPROFILE\claude-sync\watcher.log" -Tail 30 }
    "version"  { & "$ScriptDir\hive-version.ps1" @Args }
    "watcher"  { & "$ScriptDir\hive-watcher-ctl.ps1" @Args }
    default {
        Write-Host "Hive CLI - Usage: hive <command>" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Commands:"
        Write-Host "  status    Quick status check"
        Write-Host "  health    Full health check"
        Write-Host "  test      Connection test"
        Write-Host "  ping      Send ping to Z"
        Write-Host "  history   View message history"
        Write-Host "  backup    Create backup"
        Write-Host "  update    Update scripts"
        Write-Host "  diag      Generate diagnostics"
        Write-Host "  logs      View watcher log"
        Write-Host "  version   Version management"
        Write-Host "  watcher   Watcher control (start/stop/restart)"
    }
}
