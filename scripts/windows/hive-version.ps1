# Hive Version Manager
param(
    [ValidateSet("show", "bump", "sync")]
    [string]$Action = "show"
)

$VersionFile = "$env:USERPROFILE\claude-sync\VERSION"
$ZIP = "100.113.114.74"
$AUTH = "hive:hivesync2026"
$BASE64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($AUTH))

switch ($Action) {
    "show" {
        $local = Get-Content $VersionFile -EA SilentlyContinue
        Write-Host "Local version: $local"
        try {
            $remote = (Invoke-WebRequest "http://${ZIP}:8085/VERSION" -Headers @{Authorization="Basic $BASE64"} -UseBasicParsing).Content.Trim()
            Write-Host "Remote version: $remote"
        } catch { Write-Host "Remote: unavailable" }
    }
    "bump" {
        $v = [version](Get-Content $VersionFile)
        $new = "$($v.Major).$($v.Minor).$($v.Build + 1)"
        Set-Content $VersionFile $new
        Write-Host "Version bumped to $new"
    }
    "sync" {
        $local = Get-Content $VersionFile
        Invoke-WebRequest "http://${ZIP}:8085/VERSION" -Method PUT -Body $local -Headers @{Authorization="Basic $BASE64"} -UseBasicParsing | Out-Null
        Write-Host "Version synced: $local"
    }
}
