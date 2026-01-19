#!/bin/bash
# Hive Status App - Command-Line Build Script
# Builds APK without Gradle using Android SDK tools

set -e

# Configuration
SDK="/mnt/c/Users/pkoaw/AppData/Local/Android/Sdk"
BUILD_TOOLS="$SDK/build-tools/36.0.0"
PLATFORM="$SDK/platforms/android-35"
ANDROID_JAR="$PLATFORM/android.jar"

APP_DIR="/mnt/c/Users/pkoaw/claude-sync/hive-app"
SRC="$APP_DIR/app/src/main"
OUT="$APP_DIR/build"
PACKAGE="com.hive.status"

echo "=== HIVE STATUS APP BUILD ==="

# Clean
rm -rf "$OUT"
mkdir -p "$OUT"/{gen,classes,dex,apk}

echo "[1/6] Compiling resources..."
"$BUILD_TOOLS/aapt2.exe" compile \
    --dir "$SRC/res" \
    -o "$OUT/compiled_res.zip" 2>/dev/null || echo "No resources to compile"

echo "[2/6] Linking resources..."
"$BUILD_TOOLS/aapt2.exe" link \
    --proto-format \
    -o "$OUT/base.apk" \
    -I "$ANDROID_JAR" \
    --manifest "$SRC/AndroidManifest.xml" \
    --min-sdk-version 24 \
    --target-sdk-version 35 \
    --version-code 2 \
    --version-name "2.0" \
    -R "$OUT/compiled_res.zip" 2>/dev/null || \
"$BUILD_TOOLS/aapt2.exe" link \
    -o "$OUT/base.apk" \
    -I "$ANDROID_JAR" \
    --manifest "$SRC/AndroidManifest.xml" \
    --min-sdk-version 24 \
    --target-sdk-version 35

echo "[3/6] Compiling Java..."
mkdir -p "$OUT/classes"
javac -source 11 -target 11 \
    -cp "$ANDROID_JAR" \
    -d "$OUT/classes" \
    "$SRC/java/com/hive/status/MainActivity.java"

echo "[4/6] Creating DEX..."
"$BUILD_TOOLS/d8.bat" \
    --output "$OUT/dex" \
    --min-api 24 \
    "$OUT/classes/com/hive/status/MainActivity.class"

echo "[5/6] Packaging APK..."
# Create final APK structure
cp "$OUT/base.apk" "$OUT/hive-status-unsigned.apk"
cd "$OUT/dex" && zip -u "../hive-status-unsigned.apk" classes.dex 2>/dev/null || true
cd "$APP_DIR"

echo "[6/6] Signing APK..."
# Create debug keystore if not exists
KEYSTORE="$OUT/debug.keystore"
if [ ! -f "$KEYSTORE" ]; then
    keytool -genkeypair -v \
        -keystore "$KEYSTORE" \
        -alias debug \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -storepass android \
        -keypass android \
        -dname "CN=Debug, O=Hive, C=US" 2>/dev/null
fi

# Align
"$BUILD_TOOLS/zipalign.exe" -f 4 \
    "$OUT/hive-status-unsigned.apk" \
    "$OUT/hive-status-aligned.apk"

# Sign
"$BUILD_TOOLS/apksigner.bat" sign \
    --ks "$KEYSTORE" \
    --ks-pass pass:android \
    --out "$OUT/hive-status.apk" \
    "$OUT/hive-status-aligned.apk"

echo ""
echo "=== BUILD COMPLETE ==="
echo "APK: $OUT/hive-status.apk"
ls -la "$OUT/hive-status.apk"
