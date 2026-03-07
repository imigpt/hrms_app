# Flutter Notification System: Quick Update Guide

**Objective:** Ensure push notifications display reliably in ALL app states  
**Time:** 30-45 minutes  
**Difficulty:** Easy to Medium

---

## 🎯 Quick Start: Test Notifications

### **Before Making Changes: Verify Current State**

```bash
# 1. Build and run the app
flutter run -v

# 2. Open the app fully (foreground)
# 3. Go to backend and send a test notification
# Expected: Notification appears in-app immediately

# 4. Press home button (app goes to background)
# 5. Send another test notification
# Expected: Notification appears in system tray

# 6. Swipe app from recents (app closes completely)
# 7. Send another test notification
# 8. Tap the notification
# Expected: App opens and navigates to correct screen
```

---

## 📝 Changes To Make

### **Change 1: Enhance Background Handler Logging** ✅ EASY

**File:** `lib/services/notification_service.dart`  
**Lines:** 13-51

**Current Code:**
```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // IMPORTANT: Use print() not debugPrint() — debugPrint won't show in background!
  print('═══════════════════════════════════════════════════════════');
  print('🔥 FCM BACKGROUND/TERMINATED MESSAGE RECEIVED 🔥');
  print('═══════════════════════════════════════════════════════════');
  
  final title = message.notification?.title ?? '';
  final body = message.notification?.body ?? '';
  final type = message.data['type'] ?? 'general';
  final referenceId = message.data['referenceId'] ?? '';
  
  print('[NOTIFICATION] Title: $title');
  print('[NOTIFICATION] Body: $body');
  print('[DATA] Type: $type');
  print('[DATA] ReferenceId: $referenceId');

  // Handle different notification types
  if (type == 'chat' || type.toString().contains('chat')) {
    print('💬 CHAT NOTIFICATION DETECTED');
    print('   From: ${message.data['senderName'] ?? 'Unknown'}');
    print('   Room: ${message.data['roomName'] ?? 'Unknown'}');
  } else if (type == 'announcement') {
    print('📢 ANNOUNCEMENT NOTIFICATION DETECTED');
  } else if (type.toString().contains('leave')) {
    print('📋 LEAVE NOTIFICATION DETECTED');
  } else if (type.toString().contains('task')) {
    print('✓ TASK NOTIFICATION DETECTED');
  } else if (type == 'general' || type == 'hrms') {
    print('📱 GENERAL NOTIFICATION DETECTED');
  } else {
    print('❓ UNKNOWN NOTIFICATION TYPE: $type (from external app?)');
  }

  print('═══════════════════════════════════════════════════════════');
  print('✅ Notification will be displayed in notification tray');
  print('═══════════════════════════════════════════════════════════');

  // Firebase automatically shows notification in tray when app is closed.
  // Android system will use the default_notification_channel_id & icon from AndroidManifest.xml
  // No additional code needed here — FCM handles it natively.
}
```

**Status:** ✅ **ALREADY EXCELLENT** — No changes needed!

---

### **Change 2: Add iOS APNS Token Logging** ✅ EASY

**File:** `lib/services/notification_service.dart`  
**Method:** `setupFcmHandlers()`  
**Location:** Around line 480 in the foreground handler

**Current Code:**
```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
  try {
    print('═════════════════════════════════════════════════════════════════');
    print('🔔 FCM FOREGROUND MESSAGE (App is OPEN)');
    // ... rest of code
```

**Add This After:**
```dart
    // Add iOS APNS token verification
    if (Platform.isIOS) {
      try {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null && apnsToken.isNotEmpty) {
          print('[iOS] ✅ APNS Token available (${apnsToken.length} chars)');
        } else {
          print('[iOS] ⚠️ APNS Token is NULL — silent notifications may not work');
        }
      } catch (e) {
        print('[iOS] ❌ Error checking APNS token: $e');
      }
    }

    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        '';
```

**Why:** Confirms iOS background delivery is configured

---

### **Change 3: Improve Token Refresh Logging** ✅ EASY

**File:** `lib/services/notification_service.dart`  
**Method:** `registerFcmToken()`  
**Lines:** 395-420

**Current Code:**
```dart
// Re-register whenever the token rotates.
// Cancel any previous subscription first to avoid stacking listeners
// when registerFcmToken() is called on both login and auth-check screens.
await _tokenRefreshSub?.cancel();
_tokenRefreshSub = _fcm.onTokenRefresh.listen((newToken) async {
  if (newToken.isEmpty) return;
  final device = Platform.isIOS ? 'ios' : 'android';
  debugPrint('🔄 FCM token refreshed: ${newToken.substring(0, newToken.length.clamp(0, 20))}...');
```

**Enhanced Version:**
```dart
// Re-register whenever the token rotates.
await _tokenRefreshSub?.cancel();
_tokenRefreshSub = _fcm.onTokenRefresh.listen((newToken) async {
  if (newToken.isEmpty) {
    debugPrint('⚠️ FCM onTokenRefresh fired with empty token');
    return;
  }
  final device = Platform.isIOS ? 'ios' : 'android';
  final tokenPreview = newToken.substring(0, newToken.length.clamp(0, 20));
  debugPrint('═════════════════════════════════════════════════════════════');
  debugPrint('🔄 FCM TOKEN REFRESH EVENT');
  debugPrint('   Device: $device');
  debugPrint('   Token: $tokenPreview... (${newToken.length} chars)');
  debugPrint('═════════════════════════════════════════════════════════════');

  for (int attempt = 1; attempt <= _maxTokenRetries; attempt++) {
    try {
      final saved = await ApiNotificationService.saveToken(
        authToken: authToken,
        fcmToken: newToken,
        device: device,
      );
      if (saved) {
        debugPrint('✅ Token refresh registered successfully (attempt $attempt)');
        break;
      }
    } catch (e) {
      debugPrint('❌ Token refresh registration failed (attempt $attempt): $e');
      if (attempt < _maxTokenRetries) {
        await Future.delayed(_tokenRetryDelay);
      }
    }
  }
});
```

**Why:** Better tracking of token refresh events

---

### **Change 4: Add Import for Platform Check** ✅ EASY

**File:** `lib/services/notification_service.dart`  
**Location:** Line 2

**Current:**
```dart
import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
```

**Already Has:** `import 'dart:io';` ✅ (No change needed)

---

## 🧪 Testing Checklist

### **Test 1: Foreground (App Open)**
```bash
# Prerequisites
- App running and visible
- User logged in
- Notification permission granted

# Action
# Send test notification from backend

# Expected Result
✅ Notification appears in-app
✅ Contains correct title and body
✅ Can be expanded to show full message
✅ Sound/vibration occurs (if enabled)
✅ Tapping navigates to correct screen
```

### **Test 2: Background (App Paused)**
```bash
# Prerequisites
- App running
- User logged in
- Press home button (app in background)

# Action
# Send test notification from backend

# Expected Result
✅ Notification appears in system tray
✅ Does NOT show over app (already in background)
✅ Notification has correct icon and color
✅ Tapping notification brings app to foreground
✅ User is on correct screen
```

### **Test 3: Terminated (App Closed)**
```bash
# Prerequisites
- Swipe app from recents (fully closed)
- Wait 5 seconds

# Action
# Send test notification from backend

# Expected Result
✅ Notification appears in system tray
✅ App NOT running in background
✅ Tapping notification launches app
✅ App opens to correct screen (with 1-2 second delay)
✅ Verify navigation handler was called
```

### **Test 4: Token Management**
```bash
# Prerequisites
- Logcat/Xcode console open to see logs

# Action
# 1. Login (should see token registered)
# 2. Wait a few minutes
# 3. Check for token refresh events
# 4. Logout (should see token removed)

# Expected Logs
✅ On login: "✅ FCM token registered successfully"
✅ On refresh: "🔄 FCM token refreshed"
✅ On logout: "✅ FCM token removed from backend"
```

---

## 📊 Verification Commands

### **Check Android Logs (Real Device)**
```bash
adb logcat | grep -i "fcm\|notification\|hrms"
```

### **Check Android Logs (Emulator)**
```bash
adb -e logcat | grep -i "notification"
```

### **Check iOS Logs**
```
Xcode → View → Debug Area → Console
Look for: "FCM", "APNS", "hrms"
```

---

## 🔍 Debugging Common Issues

### **Issue: Notifications don't appear in background**

**Check:**
1. Notification permission granted? → Settings → Permissions
2. Battery optimization disabled? → Settings → Battery → Exempt app
3. Do Not Disturb mode on? → Settings → Sound & vibration
4. Firebase project exists? → Check GoogleServices-Info.plist (iOS) / google-services.json (Android)

**Fix:**
```bash
# Rebuild app completely
flutter clean
flutter pub get
flutter run -v

# Send notification from backend
# Check logcat/console for errors
```

---

### **Issue: Token not saving to backend**

**Check Logs:**
```bash
# Look for:
# ✅ means success
# ❌ means failure
# ⚠️ means warning

# At login, you should see:
# "✅ FCM token registered successfully"
```

**Fix:**
1. Verify API endpoint: `/api/notifications/save-token`
2. Check backend is running
3. Verify auth token is being passed correctly
4. Check backend database has tokens being saved

**See:** [Backend Quick Reference](../HRMS-Backend/BACKEND_NOTIFICATION_SENDING_QUICK_REFERENCE.md)

---

### **Issue: App crashes when receiving notification**

**Check:**
1. Look for exception in logcat console
2. Verify notification channels created in AndroidInitializationSettings
3. Check notification payload is valid JSON

**Fix:**
```bash
# Delete app and reinstall
# app_settings → Applications → hrms_app → Clear Storage
# Reinstall app
flutter run --release
```

---

## 🚀 Deployment Checklist

Before deploying to production:

### **Android**
- [ ] `android/app/src/main/AndroidManifest.xml` has `POST_NOTIFICATIONS` permission
- [ ] Default notification channel set to `hrms_notifications`
- [ ] @mipmap/launcher_icon exists
- [ ] @color/notification_color defined
- [ ] Tested on devices with Android 13+ (API 33+)

### **iOS**
- [ ] APNS certificate configured in Firebase Console
- [ ] iOS app has `Push Notifications` capability
- [ ] `ios/Podfile` has `platform :ios` set to 11.0+
- [ ] Tested on physical iOS device (simulator won't show notifications)

### **Backend Coordination**
- [ ] Backend sending correct FCM payload
- [ ] `android.priority: 'high'` set
- [ ] `android.notification.channelId: 'hrms_notifications'` set
- [ ] `apns.payload.aps['content-available']: 1` set for iOS
- [ ] Data fields include: type, referenceId

### **Code Quality**
- [ ] No console errors in logcat/Xcode console
- [ ] Token management working (register/refresh/remove)
- [ ] All 3 app states tested
- [ ] Navigation on tap tested

---

## 📞 Support & Troubleshooting

**If notifications still not working:**

1. **Collect Diagnostic Info:**
   - App logs (logcat/Xcode console output)
   - Device OS version
   - Current Firebase token (first 20 chars visible in logs)
   - Backend notification payload

2. **Check Documentation:**
   - [Backend Implementation Guide](../HRMS-Backend/BACKEND_IMPLEMENTATION_QUICK_START.md)
   - [Backend Testing Guide](../HRMS-Backend/BACKEND_NOTIFICATION_TESTING.md)
   - [Firebase Docs](https://firebase.google.com/docs/cloud-messaging)

3. **Test Backend Directly:**
   - Use cURL or Postman to test backend endpoints
   - Verify tokens are being saved
   - Check notification payload format

---

## ⏱️ Time Estimate

| Task | Time |
|------|------|
| Make code changes | 10 min |
| Rebuild and test | 15 min |
| Test all 3 states | 15 min |
| Debugging (if needed) | 10-20 min |
| **Total** | **30-45 min** |

---

## 📝 Notes

- Changes are **optional enhancements** — system already works well
- Focus on **testing** more than code changes
- Most issues are **backend payload** related, not app code
- Logging is your best debugging tool — read console output carefully

---

**Status:** ✅ Ready to test  
**Next Step:** Run app and send test notification from backend  
**Questions?** Check [PUSH_NOTIFICATION_UPDATE_ANALYSIS.md](PUSH_NOTIFICATION_UPDATE_ANALYSIS.md)
