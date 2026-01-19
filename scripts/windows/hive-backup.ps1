# Hive Backup Script
$BackupDir = "$env:USERPROFILE\claude-sync\backups"
$SyncDir = "$env:USERPROFILE\claude-sync"
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupFile = "$BackupDir\hive-backup-$ts.zip"

if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir | Out-Null }

Write-Host "Creating backup: $BackupFile" -ForegroundColor Cyan

# Items to backup
$items = @("to-t.md", "to-z.md", "memory", "handoff", "docs", "hive.config.ps1", "VERSION")
$tempDir = "$env:TEMP\hive-backup-$ts"
New-Item -ItemType Directory -Path $tempDir | Out-Null

foreach ($item in $items) {
    $src = "$SyncDir\$item"
    if (Test-Path $src) {
        Copy-Item $src "$tempDir\$item" -Recurse -Force
    }
}

Compress-Archive -Path "$tempDir\*" -DestinationPath $BackupFile -Force
Remove-Item $tempDir -Recurse -Force

Write-Host "Backup complete: $BackupFile" -ForegroundColor Green

# Keep only last 5 backups
Get-ChildItem "$BackupDir\hive-backup-*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -Skip 5 | Remove-Item -Force
