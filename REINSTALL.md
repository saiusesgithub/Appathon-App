# ⚠️ CRITICAL: You MUST Reinstall the App

## Why Scanning Shows "0 Devices"

Android only reads the app manifest **when you first install** the app. We added Bluetooth permissions to the manifest, but your currently installed app doesn't have them.

## How to Fix (Choose ONE method)

### Method 1: Complete Uninstall + Reinstall (RECOMMENDED)
```powershell
# 1. Uninstall the old app completely
adb uninstall com.example.shadowmesh

# 2. Build fresh APK
flutter build apk --release

# 3. Install the new APK
adb install build\app\outputs\flutter-apk\app-release.apk
```

### Method 2: Use the Kill Switch in Settings
1. Open ShadowMesh app
2. Go to Settings tab
3. Scroll to "Danger Zone"
4. Tap "Activate Kill Switch"
5. Confirm (this wipes data and opens uninstall screen)
6. After uninstalling, reinstall the new APK

### Method 3: Manual Uninstall
1. Long-press the ShadowMesh app icon
2. Tap "App info"
3. Tap "Uninstall"
4. Install the new APK: `adb install build\app\outputs\flutter-apk\app-release.apk`

## After Reinstalling

1. Open the app
2. Go to "Files" tab
3. Tap "Join (scan)"
4. **You will now see permission dialogs for:**
   - Nearby devices
   - Location (while using app)
5. Grant both permissions
6. Scanning will now discover devices!

## Verify Permissions Were Added

After install, you can check:
```powershell
adb shell dumpsys package com.example.shadowmesh | Select-String "permission"
```

You should see:
- android.permission.BLUETOOTH_SCAN
- android.permission.BLUETOOTH_CONNECT
- android.permission.ACCESS_FINE_LOCATION

## Still Not Working?

If after reinstalling you still see "Bluetooth permissions required":
1. Tap "Join (scan)" again
2. Tap "Check Permissions" button
3. The snackbar will show exact permission statuses
4. If any show "denied", tap "Open Settings" and enable manually
