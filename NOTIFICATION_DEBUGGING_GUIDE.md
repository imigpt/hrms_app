# Notification Debugging Guide

**Version**: 1.0  
**Last Updated**: March 5, 2026

## Status: Enhanced Logging Added ✅

The background notification handler now has **comprehensive logging** that will help diagnose why notifications aren't showing.

---

## How to Test Notifications

### **1. Run App with Console Logging**

```bash
cd hrms_app
flutter run -v
```

The `-v` flag shows **ALL console output** including background messages.

---

### **2. Send a Test FCM Notification**

#### **Option A: Firebase Console (Easiest)**

1. Go to: https://console.firebase.google.com
2. Select your HRMS project
3. **Cloud Messaging** → **Send your first message**
4. Fill in:
   - **Notification title**: "Test Notification"
   - **Notification body**: "Hello from Firebase!"
5. **Send test message** → Select your device
6. **Watch console output** for logs

#### **Option B: NodeJS Backend API**

```bash
curl -X POST "http://localhost:5000/api/notifications/send" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "USER_ID_HERE",
    "title": "Test",
    "body": "Test notification",
    "type": "general"
  }'
```

---

## What You'll See in Console

### **✅ Successful Background Message Reception**

```
═════════════════════════════════════════════════════════════
🔥 FCM BACKGROUND/TERMINATED MESSAGE RECEIVED 🔥
═════════════════════════════════════════════════════════════
[NOTIFICATION] Title: Test Notification
[NOTIFICATION] Body: Hello from Firebase!
[DATA] Type: general
[DATA] ReferenceId: null
[DATA] All: {type: general}
═════════════════════════════════════════════════════════════
⏳ Initializing Firebase in background isolate...
✅ Firebase initialized in background isolate
📝 Processing: type=general, title=Test Notification, body=Hello from Firebase!
⏳ Initializing local notifications plugin in background...
✅ Local notifications plugin initialized
📢 Using channel: general_channel (General Notifications)
⏳ Creating notification channel in background...
✅ Notification channel created
⏳ Showing notification...
✅ ✅ ✅ NOTIFICATION SHOWN SUCCESSFULLY! ID=1709645823 ✅ ✅ ✅
✅ Title: Test Notification
✅ Body: Hello from Firebase!
═════════════════════════════════════════════════════════════
```

### **❌ If Notification Doesn't Show**

You'll see one of these errors:

#### **Error: Firebase Init Failed**
```
❌ Firebase init error in background: [Error details]
   Stack: [Stack trace]
```
**Fix**: Check Google Firebase credentials in `android/app/google-services.json`

#### **Error: Plugin Init Failed**
```
❌ Local notifications init error: [Error details]
   Stack: [Stack trace]
```
**Fix**: Check notification permissions are granted on device

#### **Error: Showing Notification Failed**
```
❌ ❌ ❌ ERROR SHOWING NOTIFICATION! ❌ ❌ ❌
   Error: [Error details]
   Stack: [Stack trace]
```
**Fix**: Notification channel might not exist or timeout occurred

---

## Foreground (App Open) - Console Logs

When app is open and message arrives:

```
📱 FCM foreground message received
   Title: Test Notification
   Body: Hello from Firebase!
   Data: {type: general}
📱 Processing notification: [general] Test Notification
```

---

## Checklist: Why Notifications Might Not Show

### **1. Notification Permissions ❌**
```bash
# On Android device via ADB:
adb shell pm grant com.example.hrms_app android.permission.POST_NOTIFICATIONS
```

### **2. Google-Services JSON ❌**
- Verify `android/app/google-services.json` exists
- Verify it contains correct Firebase project ID
- File should be from Firebase Console > Project Settings > google-services.json

### **3. Notification Channels ❌**
The app creates channels on startup:
- `general_channel`
- `chat_channel`
- `announcements_channel`
- `leave_channel`
- `task_channel`

If these don't exist, background handler creates them. Check logs for creation success.

### **4. Battery Saver / Doze Mode ❌**
Some devices kill background processes:
```bash
# Check device battery saver:
adb shell dumpsys deviceidle get current
# Output should NOT be "deep"
```

### **5. FCM Token Not Saved ❌**
- User must be **logged in** for token to be saved
- Check backend logs: `POST /api/notifications/save-token`
- Should respond with `200 OK`

### **6. Backend Connection Issue ❌**
API URL in `api_notification_service.dart`:
```dart
static const String _base = 'https://hrms-backend-zzzc.onrender.com/api';
```

Test connectivity:
```bash
ping hrms-backend-zzzc.onrender.com
curl -X GET "https://hrms-backend-zzzc.onrender.com/health"
```

### **7. App Crashes on Background ❌**
- Check `adb logcat` for crash logs
- Look for "segmentation fault" or "native crash"
- May indicate incompatibility with device Android version

---

## Testing Steps (In Order)

### **Step 1: Verify App Setup**
```bash
flutter clean
flutter pub get
flutter run -v
```
Check logs for:
- ✅ `Firebase initialized successfully`
- ✅ `Notification permission granted: true`
- ✅ `FCM handlers configured`

### **Step 2: Send Foreground Test**
App is OPEN and running:

- Go to Firebase Console
- Send test message
- Check console for:
  - ✅ `📱 FCM foreground message received`
  - ✅ Notification appears on screen

### **Step 3: Send Background Test**
App is BACKGROUNDED (don't close, just minimize):

- Send test message via Firebase Console
- Check console for:
  - ✅ `🔥 FCM BACKGROUND/TERMINATED MESSAGE RECEIVED`
  - ✅ `✅ ✅ ✅ NOTIFICATION SHOWN SUCCESSFULLY`
- Pull down notification tray - notification should appear

### **Step 4: Send Terminated Test**
App is CLOSED/KILLED:

- Send test message via Firebase Console
- Open app fresh from launcher
- Check console for:
  - ✅ `🔥 FCM BACKGROUND/TERMINATED MESSAGE RECEIVED`
  - ✅ Notification should be in system tray
- Old notification should show in tray even after app opens

---

## Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| Notification shows in foreground but not in background | App was killed by system | Enable battery optimization whitelist |
| `Firebase init error` in logs | google-services.json missing | Download from Firebase Console |
| `Plugin init error` | Notification permissions not granted | Request permissions in app, check system settings |
| Notification appears but with generic icon | Icon resource not found | Icon must be at `android/app/src/main/res/mipmap/launcher_icon.png` |
| No logs appear at all | Background handler not registered | Restart app, restart phone |
| Error 500 from backend | Backend server crashed | Check HRMS-Backend logs |

---

## Advanced Debugging

### **View Kernel Logs (Android)**
```bash
adb logcat *:S flutter:V firebase:V
```

### **Check Notification Channels**
```bash
# List all notification channels on device
adb shell dumpsys notification_channels | grep -A 20 "general_channel"
```

### **Simulate Killed App**
```bash
# Force-stop app while running
adb shell am force-stop com.example.hrms_app

# Send notification - should show in tray when app opens
```

### **Check Firebase Token**
Add this to `main.dart` after NotificationService.initialize():
```dart
final token = await FirebaseMessaging.instance.getToken();
print('FCM TOKEN: $token');
```

---

## Next Steps

1. **Run app with logging**: `flutter run -v`
2. **Send test notification** via Firebase Console
3. **Watch console output** for success/error messages
4. **Check notification tray** for the notification
5. **Share console errors** if notification still doesn't appear

---

## Key Files Modified

- `lib/services/notification_service.dart` - Enhanced background handler with detailed logging
- `lib/main.dart` - FCM handler registration
- `android/app/src/main/AndroidManifest.xml` - FCM metadata
- `android/app/src/main/res/values/colors.xml` - Notification color

---

## Still Not Working?

**100% Guaranteed Fixes (In Order)**:

1. ✅ Restart phone
2. ✅ Uninstall app: `flutter clean && flutter run`
3. ✅ Check internet connection on device
4. ✅ Verify FCM token was saved: Check backend DB for user's fcm tokens
5. ✅ Verify `google-services.json` matches Firebase project
6. ✅ Test with a different device or emulator
7. ✅ Post console logs (sanitized) with error details

---

**Document Version**: 1.0  
**Last Updated**: March 5, 2026  
**Status**: Ready for Testing ✅
