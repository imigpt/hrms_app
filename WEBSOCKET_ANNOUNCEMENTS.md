# WebSocket Integration for Announcements

## Overview
This implementation provides real-time announcement updates using WebSockets, allowing users to receive instant notifications when new announcements are created, updated, or deleted.

## Components

### 1. WebSocket Service (`announcement_websocket_service.dart`)

**Features:**
- **Real-time Connection**: Maintains a persistent WebSocket connection to the backend
- **Auto-reconnect**: Automatically attempts to reconnect if the connection is lost (up to 5 attempts)
- **Heartbeat**: Sends periodic ping messages to keep the connection alive
- **Message Handling**: Processes different types of messages:
  - `announcements`: Initial list of announcements
  - `new_announcement`: New announcement created
  - `updated_announcement`: Announcement modified
  - `deleted_announcement`: Announcement removed
  - `pong`: Heartbeat response

**Key Methods:**
- `connect(String token)`: Establishes WebSocket connection with authentication
- `announcementsStream`: Stream that emits updated announcement lists
- `markAsRead(String announcementId)`: Marks an announcement as read
- `disconnect()`: Closes the connection gracefully
- `dispose()`: Cleans up all resources

### 2. Dashboard Integration (`dashboard_screen.dart`)

**Implementation:**
```dart
// Initialize WebSocket service
final AnnouncementWebSocketService _wsService = AnnouncementWebSocketService();
StreamSubscription<List<Announcement>>? _announcementsSubscription;

// Connect in initState
_connectToAnnouncementsWebSocket();

// Listen to stream
_announcementsSubscription = _wsService.announcementsStream.listen(
  (announcements) {
    setState(() {
      _announcements = announcements;
    });
  }
);

// Cleanup in dispose
_announcementsSubscription?.cancel();
_wsService.dispose();
```

**Fallback Mechanism:**
If WebSocket connection fails, the app automatically falls back to REST API polling to ensure announcements are still loaded.

### 3. UI Component (`announcements_section.dart`)

**Features:**
- **Live Indicator**: Shows a red "LIVE" badge when WebSocket is connected
- **Real-time Updates**: Automatically updates the UI when new announcements arrive
- **Priority-based Styling**: Different border colors based on announcement priority:
  - High priority: Red
  - Medium priority: Orange
  - Low priority: Blue

## WebSocket Message Format

### Client → Server

**Request Announcements:**
```json
{
  "type": "get_announcements",
  "timestamp": "2026-02-17T10:30:00.000Z"
}
```

**Mark as Read:**
```json
{
  "type": "mark_read",
  "announcementId": "announcement_id_here",
  "timestamp": "2026-02-17T10:30:00.000Z"
}
```

**Heartbeat:**
```json
{
  "type": "ping"
}
```

### Server → Client

**Announcements List:**
```json
{
  "type": "announcements",
  "data": [
    {
      "_id": "...",
      "title": "Announcement Title",
      "content": "Announcement content",
      "priority": "high",
      "createdAt": "2026-02-17T10:30:00.000Z",
      ...
    }
  ]
}
```

**New Announcement:**
```json
{
  "type": "new_announcement",
  "data": {
    "_id": "...",
    "title": "New Announcement",
    ...
  }
}
```

**Updated Announcement:**
```json
{
  "type": "updated_announcement",
  "data": {
    "_id": "...",
    "title": "Updated Title",
    ...
  }
}
```

**Deleted Announcement:**
```json
{
  "type": "deleted_announcement",
  "id": "announcement_id_here"
}
```

**Heartbeat Response:**
```json
{
  "type": "pong"
}
```

## Setup Instructions

### 1. Install Dependencies
```bash
flutter pub get
```

The `web_socket_channel` package is required (already added to `pubspec.yaml`).

### 2. Backend Requirements

Your backend WebSocket server should:
- Accept connections at: `wss://hrms-backend-807r.onrender.com`
- Support authentication via query parameter: `?token=<auth_token>`
- Implement the message types listed above
- Send periodic heartbeat responses to keep connection alive

### 3. Configuration

Update the WebSocket URL in `announcement_websocket_service.dart` if needed:
```dart
static const String wsUrl = 'wss://your-backend-url.com';
```

## Usage Example

```dart
// In your widget
final wsService = AnnouncementWebSocketService();

// Connect
await wsService.connect(authToken);

// Listen to announcements
wsService.announcementsStream.listen((announcements) {
  print('Received ${announcements.length} announcements');
  // Update UI
});

// Mark announcement as read
wsService.markAsRead('announcement_id');

// Cleanup
await wsService.dispose();
```

## Testing

To test the WebSocket connection:

1. Run the app: `flutter run`
2. Login to the dashboard
3. Check console logs for:
   - `Connecting to WebSocket: wss://...`
   - `WebSocket connected successfully`
   - `Received X announcements`
4. Create a new announcement from admin panel
5. Verify it appears instantly in the app

## Troubleshooting

### Connection Fails
- Check if backend WebSocket server is running
- Verify the WebSocket URL is correct
- Ensure authentication token is valid
- Check firewall/network settings

### No Real-time Updates
- Verify WebSocket connection is established (check logs)
- Ensure backend is broadcasting announcement events
- Check if message format matches expected structure

### App Crashes on Dispose
- Ensure `dispose()` is called properly
- Check all subscriptions are cancelled
- Verify no memory leaks from unclosed streams

## Performance Considerations

- WebSocket connection is lightweight and maintains minimal overhead
- Heartbeat interval: 30 seconds (configurable)
- Auto-reconnect attempts: 5 times with 3-second delay
- Stream uses broadcast controller for multiple listeners
- Cached announcements reduce redundant processing

## Security

- Authentication token is passed during connection
- Secure WebSocket (WSS) protocol is used
- Token should be refreshed if expired
- Connection auto-closes on logout

## Future Enhancements

Potential improvements:
- [x] Add notification badges for unread announcements ✅
- [ ] Implement sound/vibration for high-priority announcements
- [ ] Add offline queue for failed mark-as-read requests
- [ ] Support filtering announcements via WebSocket
- [ ] Add connection health monitoring dashboard
- [ ] Implement message compression for large payloads

## Notification Badge Feature

### Implementation

The app now displays real-time notification badges showing the count of unread announcements:

**Mobile AppBar:**
- Shows bell icon with red badge in top-right corner
- Badge displays count of unread announcements
- Badge disappears when all announcements are read
- Tapping navigates to full announcements screen

**Desktop View:**
- Shows bell icon with badge next to dashboard title
- Same behavior as mobile version

**Visual Indicators:**
- Red badge with white text showing unread count
- Unread announcements highlighted in announcement list
- Red dot indicator next to unread announcement titles
- Bold text for unread announcements

### How It Works

1. **Unread Calculation:**
   - Checks if user's ID is in announcement's `readBy` array
   - Counts announcements where user ID is NOT present
   - Updates count in real-time via WebSocket

2. **Mark as Read:**
   - When user taps an announcement card, it's marked as read
   - Sends WebSocket message to backend
   - Optimistically updates local state
   - Badge count decreases immediately

3. **Real-time Updates:**
   - WebSocket pushes new announcements
   - Badge count increases for new unread items
   - Works seamlessly with existing announcement features

### Code Example

```dart
// In dashboard
int _unreadAnnouncementsCount = 0;

// Calculate unread count
int _calculateUnreadCount(List<Announcement> announcements) {
  if (widget.user == null) return 0;
  
  final userId = widget.user!.id;
  return announcements.where((announcement) {
    return !announcement.readBy.contains(userId);
  }).length;
}

// Mark as read
void _markAnnouncementAsRead(String announcementId) {
  _wsService.markAsRead(announcementId);
  // Update local state optimistically
}

// Display badge
Badge(
  label: Text(_unreadAnnouncementsCount.toString()),
  backgroundColor: Colors.red,
  child: Icon(Icons.notifications_outlined),
)
```
