# External App Notifications Guide

**Version**: 1.0  
**Last Updated**: March 5, 2026

## Overview

The HRMS Flutter app has been enhanced to receive and handle notifications from external systems/apps in addition to internal HRMS notifications. This guide explains how the app processes notifications from any source.

---

## Supported Notification Types

The app recognizes and routes the following notification types from external sources:

### 1. **Chat Notifications**
- Type: `chat`
- Payload: `{ type: 'chat', roomId: 'room_id' }`
- Routes to: **Chat Screen**

### 2. **Announcement Notifications**
- Type: `announcement`
- Payload: `{ type: 'announcement', referenceId: 'announcement_id' }`
- Routes to: **Announcements Screen**

### 3. **Task Notifications**
- Types: `task`, `task_assigned`, `task_updated`, `task_completed`, `task_comment`
- Payload: `{ type: 'task_*', referenceId: 'task_id' }`
- Routes to: **Tasks Screen**

### 4. **Leave Notifications**
- Types: `leave`, `leave_request`, `leave_approved`, `leave_rejected`
- Payload: `{ type: 'leave_*', referenceId: 'leave_id' }`
- Routes to: **Leave Management Screen**

### 5. **Expense Notifications**
- Types: `expense`, `expense_approved`, `expense_rejected`
- Payload: `{ type: 'expense_*', referenceId: 'expense_id' }`
- Routes to: **Expenses Screen**

### 6. **Payroll Notifications**
- Types: `payroll`, `payroll_generated`
- Payload: `{ type: 'payroll_*', referenceId: 'payroll_id' }`
- Routes to: **Payroll Screen**

### 7. **Approval Notifications**
- Types: `approval`, `approval_required`
- Payload: `{ type: 'approval_*', referenceId: 'approval_id' }`
- Routes to: **Notifications Screen** (default)

### 8. **General Notifications**
- Type: Any unrecognized type or `general`
- Routes to: **Notifications Screen** (default fallback)

---

## FCM Payload Format

External apps should send notifications in the following format:

### Firebase Cloud Messaging (FCM) Payload

```json
{
  "notification": {
    "title": "New Chat Message",
    "body": "You have a new message from John"
  },
  "data": {
    "type": "chat",
    "referenceId": "room_123",
    "roomName": "Team Chat"
  }
}
```

### Payload Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `notification.title` | string | Yes | Notification title |
| `notification.body` | string | Yes | Notification body/message |
| `data.type` | string | Yes | Notification type (see Supported Types above) |
| `data.referenceId` | string | No | ID of the resource (task, leave, etc.) for navigation |
| `data.roomName` | string | No (chat only) | Chat room name for display |
| `data.message` | string | No | Alternative body field |

---

## How the App Receives Notifications

### 1. **Foreground (App Open)**
- When the app is open, Firebase triggers `FirebaseMessaging.onMessage`
- The app parses the notification and displays it with a local notification
- User can tap to navigate based on the `type`

### 2. **Background (App in Background)**
- When the app is backgrounded, Firebase sends a system notification
- If user taps the system notification, Firebase triggers `FirebaseMessaging.onMessageOpenedApp`
- The app navigates based on the notification type

### 3. **Terminated (App Closed)**
- When the app is fully closed, Firebase stores the notification
- When app opens, Firebase triggers `FirebaseMessaging.instance.getInitialMessage()`
- The app navigates based on the stored notification type after ~1 second delay

---

## FCM Token Management

### Saving the Token

The app automatically:
1. Initializes Firebase on startup
2. Requests notification permissions (iOS/Android 13+)
3. Retrieves the FCM token
4. **After user login**, saves the token to backend via:
   ```
   POST /api/notifications/save-token
   ```

### Token Refresh

When Firebase refreshes the token (typically every few months):
- The app logs the new token
- The new token is automatically sent to backend on next notification service interaction

---

## Notification Flow Diagram

```
External System / Backend
       ↓ (Firebase Cloud Messaging)
Device Receives Notification
       ├─→ Foreground: FirebaseMessaging.onMessage
       │   └─→ Show Local Notification
       │       └─→ User Taps → Navigate
       │
       ├─→ Background: System Tray Receives
       │   └─→ User Taps System Notification
       │       └─→ FirebaseMessaging.onMessageOpenedApp
       │           └─→ Navigate Based on Type
       │
       └─→ Terminated: Firebase Stores
           └─→ App Starts
               └─→ FirebaseMessaging.getInitialMessage()
                   └─→ Wait 1s for Navigator Setup
                       └─→ Navigate Based on Type
```

---

## Example External Notifications

### Example 1: Task Assignment (from external HR system)

```json
{
  "notification": {
    "title": "New Task",
    "body": "Complete project documentation"
  },
  "data": {
    "type": "task_assigned",
    "referenceId": "task_456",
    "priority": "high"
  }
}
```

**Result**: User gets notification → Taps → Opens Tasks Screen

### Example 2: Leave Approval (from another app)

```json
{
  "notification": {
    "title": "Leave Approved",
    "body": "Your leave request has been approved"
  },
  "data": {
    "type": "leave_approved",
    "referenceId": "leave_789",
    "startDate": "2026-03-10",
    "endDate": "2026-03-15"
  }
}
```

**Result**: User gets notification → Taps → Opens Leave Management

### Example 3: Chat Message (from external chat system)

```json
{
  "notification": {
    "title": "John",
    "body": "Hey, how's the project going?"
  },
  "data": {
    "type": "chat",
    "referenceId": "chat_room_111",
    "roomName": "Project Team"
  }
}
```

**Result**: User gets notification → Taps → Opens Chat Screen & navigates to room

---

## Logging & Debugging

The app includes detailed logging for notification events:

### Console Logs

```
🔧 Setting up FCM handlers for notifications...
📱 FCM foreground message received
   Title: New Chat Message
   Body: You have a message
   Data: {type: chat, referenceId: room_123}

✅ FCM handlers setup complete

📲 Handling notification tap: type=chat, ref=room_123
→ Navigating to Chat
```

### To Debug:
1. Run app in debug mode: `flutter run`
2. Check the console output for notification logs
3. Verify `type` and `referenceId` are correct
4. Ensure notification permissions are granted

---

## Integration Checklist (for External Systems)

If you're integrating with an external system to send notifications:

- [ ] Firebase project created with Cloud Messaging enabled
- [ ] Service account credentials provided to backend
- [ ] External system calls backend `POST /api/notifications/send`
- [ ] Notification payload includes required fields (`title`, `body`, `type`)
- [ ] Notification includes `referenceId` for proper navigation
- [ ] Tested with Firebase Console first (manual send)
- [ ] Tested end-to-end with actual payload
- [ ] Verified navigation works on all states (foreground/background/terminated)

---

## Troubleshooting

### Notification Not Received?
1. ✅ Verify FCM token is saved in backend
2. ✅ Check notification permissions are granted on device
3. ✅ Verify payload has `notification` + `data` fields
4. ✅ Check backend logs for sending errors
5. ✅ Test with Firebase Console first

### Notification Shows But Navigation Doesn't Work?
1. ✅ Check if `type` field matches supported types above
2. ✅ Verify `referenceId` is provided (if needed)
3. ✅ Check console logs for navigation errors
4. ✅ Ensure user is logged in when tapping notification

### Token Not Syncing?
1. ✅ Verify user is logged in
2. ✅ Check `POST /api/notifications/save-token` success in backend
3. ✅ Ensure notification permissions granted
4. ✅ Check app `lib/services/api_notification_service.dart` logs

---

## Files Modified

- `lib/services/notification_service.dart` - Enhanced FCM handling
- `lib/services/api_notification_service.dart` - Improved token logging
- `lib/main.dart` - Expanded notification tap handler
- `EXTERNAL_NOTIFICATIONS_GUIDE.md` - This documentation

---

## Next Steps

1. **Test** with your external system
2. **Monitor** console logs for any issues
3. **Verify** all notification types are working
4. **Document** any custom notification types you add

For backend integration, refer to: `HRMS-Backend/NOTIFICATION_INTEGRATION_FOR_OUTSIDE_APP.md`
