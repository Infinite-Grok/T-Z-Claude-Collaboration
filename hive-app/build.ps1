# Hive Status App - PowerShell Build Script
$ErrorActionPreference = "Stop"

# Configuration  
$SDK = "$env:LOCALAPPDATA\Android\Sdk"
$BUILD_TOOLS = "$SDK\build-tools\36.0.0"
$PLATFORM = "$SDK\platforms\android-35"
$ANDROID_JAR = "$PLATFORM\android.jar"

$APP_DIR = "$env:USERPROFILE\claude-sync\hive-app"
$SRC = "$APP_DIR\app\src\main"
$OUT = "$APP_DIR\build"

Write-Host "=== HIVE STATUS APP BUILD ===" -ForegroundColor Cyan

# Clean and create dirs
Remove-Item $OUT -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path "$OUT\classes","$OUT\dex" -Force | Out-Null

# Step 1: Compile Java
Write-Host "[1/4] Compiling Java..." -ForegroundColor Yellow
$javaFile = "$SRC\java\com\hive\status\MainActivity.java"
& javac -source 11 -target 11 -cp "$ANDROID_JAR" -d "$OUT\classes" $javaFile

# Step 2: Create DEX
Write-Host "[2/4] Creating DEX..." -ForegroundColor Yellow
$classFile = "$OUT\classes\com\hive\status\MainActivity.class"
& "$BUILD_TOOLS\d8.bat" --output "$OUT\dex" --min-api 24 $classFile

# Step 3: Create APK with aapt
Write-Host "[3/4] Packaging APK..." -ForegroundColor Yellow
& "$BUILD_TOOLS\aapt.exe" package -f -M "$SRC\AndroidManifest.xml" -I "$ANDROID_JAR" -F "$OUT\hive-status-unsigned.apk"

# Add DEX to APK
Push-Location "$OUT\dex"
& "$BUILD_TOOLS\aapt.exe" add "..\hive-status-unsigned.apk" classes.dex
Pop-Location

# Step 4: Sign APK
Write-Host "[4/4] Signing APK..." -ForegroundColor Yellow

# Align
& "$BUILD_TOOLS\zipalign.exe" -f 4 "$OUT\hive-status-unsigned.apk" "$OUT\hive-status-aligned.apk"

# Sign with debug key
& "$BUILD_TOOLS\apksigner.bat" sign --ks "$env:USERPROFILE\.android\debug.keystore" --ks-pass pass:android --out "$OUT\hive-status.apk" "$OUT\hive-status-aligned.apk"

Write-Host ""
Write-Host "=== BUILD COMPLETE ===" -ForegroundColor Green
Write-Host "APK: $OUT\hive-status.apk"
Get-Item "$OUT\hive-status.apk" | Select-Object Name, Length, LastWriteTime
