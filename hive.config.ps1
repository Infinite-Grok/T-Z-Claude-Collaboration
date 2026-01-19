# Hive Configuration for Windows (T Node)
# Edit this file to customize settings

$HiveConfig = @{
    # Z Node connection
    Z_IP = "100.113.114.74"
    Z_PORT = "8085"
    Z_USER = "hive"
    Z_PASS = "hivesync2026"
    
    # Watcher settings
    POLL_INTERVAL = 2      # seconds
    COOLDOWN = 90          # seconds between syncs
    
    # Paths
    BASE_DIR = "$env:USERPROFILE\claude-sync"
    LOG_FILE = "$env:USERPROFILE\claude-sync\watcher.log"
    
    # Features
    TEXT_RESTORE = $false  # Restore user text after sync (experimental)
    DOUBLE_ENTER = $true   # Send Enter twice for reliability
}

# Export for use in other scripts
Export-ModuleMember -Variable HiveConfig
