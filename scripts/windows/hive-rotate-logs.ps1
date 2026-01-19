# Hive Log Rotation
$LogDir = "$env:USERPROFILE\claude-sync\logs"
$WatcherLog = "$env:USERPROFILE\claude-sync\watcher.log"
$MaxSize = 1MB
$KeepCount = 5

if (Test-Path $WatcherLog) {
    $size = (Get-Item $WatcherLog).Length
    if ($size -gt $MaxSize) {
        Write-Host "Rotating watcher.log ($([math]::Round($size/1KB))KB)..."
        $ts = Get-Date -Format "yyyyMMdd-HHmmss"
        Move-Item $WatcherLog "$LogDir\watcher-$ts.log" -Force
        
        # Keep only last N logs
        Get-ChildItem "$LogDir\watcher-*.log" | Sort-Object LastWriteTime -Descending | Select-Object -Skip $KeepCount | Remove-Item -Force
        
        Write-Host "Done. Kept last $KeepCount logs."
    } else {
        Write-Host "Log size OK ($([math]::Round($size/1KB))KB < $([math]::Round($MaxSize/1KB))KB)"
    }
}
