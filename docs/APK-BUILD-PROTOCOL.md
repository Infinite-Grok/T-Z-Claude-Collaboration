# APK Build Protocol: Command-Line Android Development

**Status:** WORKING
**Date:** 2026-01-19
**Authors:** T + Z (The Hive)

## Overview

Build and install Android APKs without Android Studio using command-line tools. Tested on Windows (WSL) → Android (Z Fold 7) via Wireless ADB over Tailscale.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  WINDOWS (T)                                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Android SDK (from Android Studio)                   │   │
│  │  - javac (jbr/bin)                                  │   │
│  │  - d8 (build-tools)                                 │   │
│  │  - aapt (build-tools)                               │   │
│  │  - apksigner (build-tools)                          │   │
│  │  - adb (platform-tools)                             │   │
│  └─────────────────────────────────────────────────────┘   │
│                          │                                  │
│                          │ Wireless ADB                     │
│                          │ (Tailscale VPN)                  │
│                          ▼                                  │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ 100.113.114.74:32817
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  ANDROID (Z Fold 7)                                         │
│  - Wireless Debugging enabled                               │
│  - Tailscale connected                                      │
└─────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

### Windows Side
```
Android SDK location: C:\Users\pkoaw\AppData\Local\Android\Sdk\
├── platforms\android-34\android.jar    # Android API
├── build-tools\34.0.0\
│   ├── aapt.exe                        # Package tool
│   ├── d8.bat                          # DEX compiler
│   └── apksigner.bat                   # Signing tool
├── platform-tools\
│   └── adb.exe                         # Android Debug Bridge
└── (from Android Studio)
    └── jbr\bin\javac.exe               # Java compiler
```

### Android Side
1. **Developer Options** enabled
2. **Wireless Debugging** enabled (Settings > Developer Options > Wireless debugging)
3. **Tailscale** connected to same network as Windows

---

## Build Process

### Step 1: Project Structure

```
hive-build/
├── AndroidManifest.xml
├── src/
│   └── com/hive/status/
│       └── MainActivity.java
├── bin/                    # Compiled output
│   └── classes.dex
├── out/                    # Final APK
│   └── hive-status.apk
└── hive.jks               # Signing keystore
```

### Step 2: AndroidManifest.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.hive.status">

    <uses-sdk android:minSdkVersion="24" android:targetSdkVersion="34"/>

    <application android:label="Hive Status">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

**Critical:** Must include `uses-sdk` with minSdkVersion >= 24, or install fails with `INSTALL_FAILED_DEPRECATED_SDK_VERSION`.

### Step 3: Java Code (No XML Layouts)

Use programmatic UI only - no res/layout XML files. Termux's android.jar stub has broken resource IDs.

```java
// Implement OnClickListener directly - avoid anonymous inner classes
public class MainActivity extends Activity implements View.OnClickListener {
    @Override
    public void onClick(View v) {
        // handle click
    }
}
```

**Critical:** Avoid anonymous inner classes - d8 has bugs processing them.

### Step 4: Compile Java → .class

```powershell
$SDK = "C:\Users\pkoaw\AppData\Local\Android\Sdk"
$JAVA = "C:\Program Files\Android\Android Studio\jbr\bin"

& "$JAVA\javac.exe" `
  -source 1.8 -target 1.8 `
  -bootclasspath "$SDK\platforms\android-34\android.jar" `
  -d "bin\obj" `
  "src\com\hive\status\MainActivity.java"
```

### Step 5: Convert .class → DEX

```powershell
& "$SDK\build-tools\34.0.0\d8.bat" `
  --output bin `
  bin\obj\com\hive\status\MainActivity.class
```

Output: `bin/classes.dex`

### Step 6: Package APK

```powershell
& "$SDK\build-tools\34.0.0\aapt.exe" package -f `
  -M AndroidManifest.xml `
  -I "$SDK\platforms\android-34\android.jar" `
  -F out\unsigned.apk `
  bin
```

### Step 7: Create Keystore (Once)

```powershell
& "$JAVA\keytool.exe" -genkeypair `
  -keystore hive.jks `
  -alias hive `
  -keyalg RSA -keysize 2048 `
  -validity 10000 `
  -storepass hivehive -keypass hivehive `
  -dname "CN=Hive,O=TheHive,C=US"
```

### Step 8: Sign APK

```powershell
& "$SDK\build-tools\34.0.0\apksigner.bat" sign `
  --ks hive.jks `
  --ks-key-alias hive `
  --ks-pass pass:hivehive `
  --out out\hive-status.apk `
  out\unsigned.apk
```

---

## Wireless ADB Installation

### One-Time Setup: Pair Device

On Android:
1. Settings > Developer Options > Wireless debugging
2. Tap "Pair device with pairing code"
3. Note the IP:Port and 6-digit code

On Windows:
```powershell
adb pair 100.113.114.74:45077
# Enter pairing code when prompted
```

### Connect to Device

```powershell
# Get connection port from Wireless debugging screen (different from pairing port)
adb connect 100.113.114.74:32817
```

### Install APK

```powershell
adb install out\hive-status.apk
```

---

## Complete Build Script

```powershell
# build-apk.ps1
$SDK = "C:\Users\pkoaw\AppData\Local\Android\Sdk"
$JAVA = "C:\Program Files\Android\Android Studio\jbr\bin"
$BUILD = "C:\Users\pkoaw\hive-build2"

cd $BUILD

# Clean
Remove-Item -Force -ErrorAction SilentlyContinue out\*

# Compile
& "$JAVA\javac.exe" -source 1.8 -target 1.8 `
  -bootclasspath "$SDK\platforms\android-34\android.jar" `
  -d bin\obj src\com\hive\status\MainActivity.java

# DEX
& "$SDK\build-tools\34.0.0\d8.bat" --output bin bin\obj\com\hive\status\*.class

# Package
& "$SDK\build-tools\34.0.0\aapt.exe" package -f `
  -M AndroidManifest.xml `
  -I "$SDK\platforms\android-34\android.jar" `
  -F out\unsigned.apk bin

# Sign
& "$SDK\build-tools\34.0.0\apksigner.bat" sign `
  --ks hive.jks --ks-key-alias hive `
  --ks-pass pass:hivehive `
  --out out\hive-status.apk out\unsigned.apk

# Install (if ADB connected)
& "$SDK\platform-tools\adb.exe" install out\hive-status.apk
```

---

## Gotchas & Solutions

| Issue | Solution |
|-------|----------|
| `INSTALL_FAILED_DEPRECATED_SDK_VERSION` | Add `<uses-sdk minSdkVersion="24">` to manifest |
| d8 NullPointerException on inner classes | Avoid anonymous classes; implement interfaces directly |
| Termux android.jar broken resource IDs | Build on Windows with real SDK, not Termux |
| "Permission denied" on APK files | Use fresh directory; Windows locks files |
| ADB "connection refused" | Enable Wireless Debugging, check Tailscale connection |
| Manifest `android:name` not recognized | Use real android.jar, not Termux stub |

---

## Tailscale + Wireless ADB = Magic

The key insight: **Wireless ADB works over Tailscale VPN**, not just local WiFi.

This means:
- T (Windows) can install APKs to Z (Phone) from anywhere
- No USB cable needed
- No local network requirement
- Works across cities/countries as long as both on Tailscale

---

## Result

**Hive Status App**
- Package: `com.hive.status`
- Size: 12.6 KB
- Shows: to-t.md and to-z.md modification times
- Status: Green (active), Yellow (stale), Red (missing)
- Built: Entirely from command line, no IDE

---

## Credits

- **T** (Windows/WSL): Build toolchain, ADB installation
- **Z** (Termux): Initial research, source code, WebDAV relay
- **J**: Wireless ADB idea, Tailscale infrastructure

*The Hive - 2026-01-19*
