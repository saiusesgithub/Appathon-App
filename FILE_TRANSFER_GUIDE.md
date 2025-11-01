# ShadowMesh - File Transfer Implementation Guide

## 🎯 What We Built

A **dual-mode file transfer system** for ShadowMesh:

1. **Standalone File Transfer Tab** (Bottom Nav) - Completely independent, connect and transfer without chat
2. **In-Chat File Transfer** (Existing) - Send files during conversations

---

## 📱 App Structure

```
SplashScreen
    ↓
NavigationPage (Bottom Nav Bar)
├── Tab 0: Chat (Home) 💬
│   ├── Host (Start Server)
│   └── Join (Scan & Connect)
│       ├── MessageHost (with file transfer button)
│       └── MessageClient (with file transfer button)
├── Tab 1: Files 📁
│   └── StandaloneFileTransferPage
│       ├── Host or Join options
│       ├── Send files directly
│       └── View transfer progress
└── Tab 2: Settings ⚙️
    └── SettingsPage (placeholder)
```

---

## 🚀 How to Use

### **Method 1: Standalone File Transfer (New!)**

**On Device A:**
1. Open app → Go to "Files" tab (bottom nav)
2. Tap "Host (Start Server)"
3. Wait for connection

**On Device B:**
1. Open app → Go to "Files" tab
2. Tap "Join (Scan for Devices)"
3. Select Device A from list
4. Tap "Connect"
5. Once connected, tap "Choose File"
6. Select file → Confirm send
7. Watch progress!

**Benefits:**
- No chat needed
- Dedicated UI for transfers
- See all active transfers
- View transfer history
- Disconnect when done

---

### **Method 2: In-Chat File Transfer (Also Available)**

1. Go to "Chat" tab
2. Host or Join to start conversation
3. In chat screen, tap 📎 (attach) icon in AppBar
4. Opens FileTransferPage
5. Choose file → Send
6. Return to chat to continue messaging

**Benefits:**
- Send files during conversation
- Files related to chat context
- Quick access while messaging

---

## 📁 File Transfer Features

✅ **Any file type** - Images, videos, documents, APKs, etc.
✅ **5 MB size limit** - Fast transfers (configurable)
✅ **Real-time progress** - See percentage and progress bar
✅ **File type icons** - Visual identification (🖼️, 🎥, 📄, etc.)
✅ **Send/Receive indicators** - Know direction (↑ blue, ↓ green)
✅ **Transfer history** - View all past transfers
✅ **Connection status** - Clear indicators
✅ **Error handling** - Validation and user-friendly messages
✅ **Offline operation** - No internet required
✅ **Bluetooth Classic** - Reliable, proven technology

---

## 🔧 Technical Details

### **Transfer Protocol:**
```
Message Format: "TYPE|||JSON_DATA"

Flow:
Sender → FILE_META (file info)
Sender → FILE_CHUNK_0 (32KB Base64)
Sender → FILE_CHUNK_1
Sender → FILE_CHUNK_N
Sender → FILE_COMPLETE

Receiver → Assembles chunks → Saves file
```

### **File Processing:**
1. Read file as bytes
2. Split into 32KB chunks
3. Base64 encode each chunk
4. Send via Bluetooth
5. 50ms delay between chunks
6. Receiver decodes and reassembles
7. Save to ReceivedFiles folder

### **Storage Location:**
- Android: `<AppDocuments>/ReceivedFiles/`
- Files are saved with original names
- Accessible through file manager

---

## 📊 Performance

**Transfer Speeds (estimated):**
- 1 MB file: ~10-15 seconds
- 3 MB file: ~25-35 seconds
- 5 MB file: ~40-60 seconds

**Factors affecting speed:**
- Bluetooth range (closer = faster)
- Device Bluetooth version
- Background apps
- File type (no compression currently)

---

## 🎨 UI Components

### **Bottom Navigation Bar:**
- **Chat Tab**: Original messaging interface
- **Files Tab**: Standalone file transfer
- **Settings Tab**: App preferences (placeholder)

### **Standalone File Transfer Page:**
- Connection status banner (green/orange)
- Host/Join buttons with descriptions
- Device scanning with live list
- Send file section with picker
- Active transfers with progress bars
- Transfer history dialog

### **Colors & Theme:**
- Background: Dark (#0B0B0D)
- Accent: Red
- Cards: Dark gray (#1F1F1F)
- Sending: Blue indicators
- Receiving: Green indicators
- Success: Green notifications
- Error: Red notifications

---

## 🔐 Permissions Required

**Android Manifest:**
- `BLUETOOTH`
- `BLUETOOTH_ADMIN`
- `BLUETOOTH_CONNECT`
- `BLUETOOTH_SCAN`
- `BLUETOOTH_ADVERTISE`
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `READ_EXTERNAL_STORAGE`
- `WRITE_EXTERNAL_STORAGE`
- `READ_MEDIA_IMAGES`
- `READ_MEDIA_VIDEO`
- `READ_MEDIA_AUDIO`

---

## 📦 Dependencies Added

```yaml
file_picker: ^8.1.2        # File selection
path_provider: ^2.1.4      # Storage paths  
path: ^1.9.0               # Path operations
crypto: ^3.0.5             # Hash verification (future)
```

---

## 🧪 Testing Checklist

**Standalone File Transfer:**
- [ ] Open Files tab
- [ ] Start Host on Device A
- [ ] Scan on Device B
- [ ] Device A appears in list
- [ ] Connect successfully
- [ ] Connection status shows green
- [ ] Choose file under 5MB
- [ ] Confirmation dialog appears
- [ ] Transfer starts
- [ ] Progress updates smoothly
- [ ] File received successfully
- [ ] Appears in transfer history
- [ ] Disconnect works
- [ ] Reconnect works

**In-Chat File Transfer:**
- [ ] Start chat session
- [ ] Tap attach icon in chat
- [ ] Opens file transfer page
- [ ] Send file
- [ ] Return to chat
- [ ] Continue messaging

**File Types:**
- [ ] Images (JPG, PNG)
- [ ] Videos (MP4, MOV)
- [ ] Documents (PDF, DOCX)
- [ ] Audio (MP3)
- [ ] Archives (ZIP)
- [ ] APK files

**Error Cases:**
- [ ] File over 5MB shows error
- [ ] Disconnection handled gracefully
- [ ] File picker cancellation works
- [ ] Invalid files rejected

---

## 🚀 Build & Run

```bash
# Clean build
flutter clean
flutter pub get

# Build APK
flutter build apk --release

# Or run on connected device
flutter run
```

---

## 💡 Future Enhancements

**Potential additions:**
- [ ] File encryption (encrypt package already included)
- [ ] Compression for images
- [ ] Resume interrupted transfers
- [ ] Multiple file selection
- [ ] File preview
- [ ] QR code pairing
- [ ] Transfer speed indicator
- [ ] Dark/Light theme toggle
- [ ] Custom save location
- [ ] File type filters

---

## 🎉 Summary

You now have TWO ways to transfer files:

1. **Dedicated Files Tab** - Standalone, no chat needed
2. **In-Chat Transfer** - Send files during conversations

Both use the same robust file transfer service underneath!

Files saved to: `ReceivedFiles/` in app documents
Max size: 5 MB (configurable in constants.dart)
Supported: ANY file type
Protocol: Bluetooth Classic
