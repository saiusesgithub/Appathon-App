# Bluetooth Scanning Troubleshooting Guide

## ✅ Changes Made to Fix Scanning

### 1. **Added Error Callbacks**
- Added `onError` callback for both client and host
- Logs all errors to console and shows user-friendly messages

### 2. **Improved Permission Checking**
- Scanning now explicitly checks permissions before starting
- Shows clear error if permissions not granted

### 3. **Added Debug Logging**
- All operations now print to console with emojis
- Easy to track what's happening:
  - 🔍 = Starting scan
  - ✅ = Success
  - ❌ = Error/Failure
  - 🔗 = Connecting
  - 🎯 = Host starting

### 4. **Stop Scanning Button**
- Can now stop scanning by tapping the button again
- Button changes color when scanning (orange)

### 5. **Better User Feedback**
- Shows "Make sure other device is hosting" hint
- Connection status with clear messages
- Error messages explain what to do

---

## 🔧 How to Test (Step-by-Step)

### **Setup: Two Android Devices**

**Device A (Host):**
1. Open ShadowMesh
2. Go to "Files" tab (bottom navigation)
3. Tap "Host (Start Server)"
4. Should see: "🟢 Hosting started! Waiting for connections..."
5. **IMPORTANT**: Device should now be discoverable

**Device B (Client):**
1. Open ShadowMesh
2. Go to "Files" tab
3. Tap "Join (Scan for Devices)"
4. Button should show "Stop Scanning" with spinner
5. Wait 10-15 seconds
6. Device A should appear in the list below
7. Tap "Connect" on Device A's entry
8. Should connect!

---

## 🐛 If Scanning Still Doesn't Work

### **Check 1: Bluetooth is ON**
```
Settings → Bluetooth → Enabled
```

### **Check 2: Location Permission**
On Android 12+, location is required for Bluetooth scanning!
```
Settings → Apps → ShadowMesh → Permissions
- Nearby devices: Allow
- Location: Allow (IMPORTANT!)
```

### **Check 3: Check Logcat Output**
Run this in terminal to see debug logs:
```bash
adb logcat | grep -E "🔍|✅|❌|ShadowMesh"
```

Look for:
- "🔍 Starting device scan..."
- "✅ Permissions OK, starting discovery..."
- "✅ Discovery started successfully"
- "🔍 Device found: [name] ([address])"

### **Check 4: Try Pairing First**
Sometimes helps to pair devices manually first:
```
Settings → Bluetooth → Pair new device
```
Then try scanning in ShadowMesh.

### **Check 5: Make Sure Host is Discoverable**
On host device:
```
Settings → Bluetooth → Device name → Tap to make discoverable
```
Or the app should automatically make it discoverable when hosting.

---

## 📱 Common Issues

### Issue: "No devices found"
**Causes:**
- Host device not discoverable
- Bluetooth range too far (move closer)
- Permissions not granted (especially location!)
- Bluetooth turned off

**Solutions:**
1. Host: Tap "Host" button, wait for green message
2. Client: Make sure location permission is granted
3. Move devices closer (within 10 meters)
4. Try scanning again

### Issue: "Failed to start scanning"
**Causes:**
- Bluetooth disabled
- Permissions denied
- Another app using Bluetooth

**Solutions:**
1. Check Bluetooth is enabled
2. Grant all permissions
3. Close other Bluetooth apps
4. Restart app

### Issue: "Failed to connect"
**Causes:**
- Host not running
- Host disconnected
- Bluetooth interference

**Solutions:**
1. Make sure host is still running
2. Host: Restart hosting
3. Client: Try scanning again
4. Move closer together

---

## 🔍 Debug Checklist

Run through this checklist:

**On Host Device:**
- [ ] Bluetooth is ON
- [ ] App has all permissions
- [ ] Tapped "Host (Start Server)"
- [ ] Saw green success message
- [ ] Device is visible in system Bluetooth settings

**On Client Device:**
- [ ] Bluetooth is ON
- [ ] Location permission granted (Android 12+)
- [ ] App has all permissions
- [ ] Tapped "Join (Scan for Devices)"
- [ ] Saw "Stop Scanning" button with spinner
- [ ] Waited at least 15 seconds
- [ ] Checked logcat for device found messages

**Both Devices:**
- [ ] Within 10 meters of each other
- [ ] Android version 8.0+
- [ ] No other Bluetooth apps interfering
- [ ] Battery saver mode OFF

---

## 🧪 Testing Commands

### View real-time logs:
```bash
# Terminal 1: Watch logs
adb logcat | grep -i bluetooth

# Terminal 2: Filter for ShadowMesh
adb logcat | grep "🔍\|✅\|❌"
```

### Check Bluetooth status:
```bash
adb shell dumpsys bluetooth_manager
```

### Restart Bluetooth:
```bash
adb shell svc bluetooth disable
adb shell svc bluetooth enable
```

---

## 💡 Expected Behavior

### **When Working Correctly:**

**Host logs:**
```
🎯 Starting host mode...
✅ Making device discoverable...
✅ Starting server...
✅ Host started successfully
```

**Client logs:**
```
🔍 Starting device scan...
✅ Permissions OK, starting discovery...
✅ Discovery started successfully
🔍 Device found: Samsung Galaxy (XX:XX:XX:XX:XX:XX)
✅ Discovery finished. Found 1 devices
```

**Connection logs:**
```
🔗 Attempting to connect to Samsung Galaxy...
✅ Connected successfully!
```

---

## 🚑 Emergency Fixes

If nothing works:

1. **Uninstall and reinstall app**
2. **Clear Bluetooth cache:**
   ```
   Settings → Apps → Bluetooth → Storage → Clear Cache
   ```
3. **Reset network settings:**
   ```
   Settings → System → Reset → Reset Wi-Fi, mobile & Bluetooth
   ```
4. **Try on different devices**
5. **Check if other Bluetooth apps work** (to rule out hardware issues)

---

## 📞 Getting Help

If still having issues, provide:
1. Logcat output (adb logcat)
2. Both device models and Android versions
3. Screenshot of permissions screen
4. What you see when you tap "Join"
