# Hive Windows Scripts

## Quick Commands

| Script | Purpose |
|--------|---------|
| `hive-status.ps1` | One-line status check |
| `hive-health.ps1` | Full health check |
| `hive-diag.ps1` | Generate diagnostic dump |
| `hive-update.ps1` | Update scripts from Z |
| `hive-rotate-logs.ps1` | Rotate watcher log |
| `hive-test-rally.ps1` | Test connectivity with rally |
| `hive-uninstall.ps1` | Uninstall Hive |

## Installation

```powershell
# One-liner install
irm http://100.113.114.74:8085/scripts/windows/bootstrap.ps1 -Headers @{Authorization='Basic aGl2ZTpoaXZlc3luYzIwMjY='} | iex
```

## Version
See ../VERSION file
