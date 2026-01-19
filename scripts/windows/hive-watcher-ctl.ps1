# Hive Watcher Control
param(
    [Parameter(Position=0)]
    [ValidateSet("start", "stop", "restart", "status")]
    [string]$Action = "status"
)

$TaskName = "HiveWatcher"

switch ($Action) {
    "start" {
        Start-ScheduledTask -TaskName $TaskName
        Write-Host "Watcher started"
    }
    "stop" {
        Stop-ScheduledTask -TaskName $TaskName
        Write-Host "Watcher stopped"
    }
    "restart" {
        Stop-ScheduledTask -TaskName $TaskName
        Start-Sleep -Seconds 1
        Start-ScheduledTask -TaskName $TaskName
        Write-Host "Watcher restarted"
    }
    "status" {
        $task = Get-ScheduledTask -TaskName $TaskName -EA SilentlyContinue
        if ($task) {
            Write-Host "Watcher: $($task.State)"
        } else {
            Write-Host "Watcher: NOT INSTALLED"
        }
    }
}
