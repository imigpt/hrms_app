// lib/services/notification_socket_service.dart
// Real-time Socket.IO service for HR notifications
// Provides real-time unread count updates and new notification events
// Separate from chat socket for independent lifecycle management

import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:hrms_app/services/api_notification_service.dart';
import 'package:hrms_app/config/api_config.dart';

// ─── Event data classes ───────────────────────────────────────────────────────

class NotificationCountEvent {
  final int unreadCount;
  NotificationCountEvent({required this.unreadCount});
}

class NewNotificationEvent {
  final NotificationItem notification;
  NewNotificationEvent({required this.notification});
}

// ─── Service ─────────────────────────────────────────────────────────────────

class NotificationSocketService {
  static final NotificationSocketService _instance =
      NotificationSocketService._internal();
  factory NotificationSocketService() => _instance;
  NotificationSocketService._internal();

  /// Get socket URL from ApiConfig (removes /api suffix)
  static String get _socketUrl {
    final baseUrl = ApiConfig.baseUrl;
    // Remove /api suffix: https://example.com/api → https://example.com
    return baseUrl.replaceAll(RegExp(r'/+api\s*$'), '');
  }

  io.Socket? _socket;
  bool _isConnected = false;
  String? _authToken;

  // Stream controllers
  final _countCtrl =
      StreamController<NotificationCountEvent>.broadcast();
  final _newNotificationCtrl =
      StreamController<NewNotificationEvent>.broadcast();
  final _connectionCtrl = StreamController<bool>.broadcast();

  // Public streams
  Stream<NotificationCountEvent> get onCountUpdated => _countCtrl.stream;
  Stream<NewNotificationEvent> get onNewNotification =>
      _newNotificationCtrl.stream;
  Stream<bool> get onConnectionChanged => _connectionCtrl.stream;

  bool get isConnected => _isConnected;

  /// Connect to notification socket with JWT token
  Future<void> connect(String authToken) async {
    if (_isConnected) return;

    _authToken = authToken;

    try {
      _socket = io.io(
        _socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setQuery({'token': authToken})
            .setReconnectionDelay(2000)
            .setReconnectionDelayMax(5000)
            .setReconnectionAttempts(5)
            .build(),
      );

      if (_socket == null) return;

      // ── Connection events ──
      _socket!.onConnect((_) {
        print('✅ Notification Socket connected');
        _isConnected = true;
        _connectionCtrl.add(true);

        // Request current unread count on connect
        _requestUnreadCount();
      });

      _socket!.onDisconnect((_) {
        print('❌ Notification Socket disconnected');
        _isConnected = false;
        _connectionCtrl.add(false);
      });

      _socket!.on('connect_error', (error) {
        print('⚠️ Notification Socket error: $error');
      });

      // ── Notification events ──

      // New notification received (real-time)
      _socket!.on('new-notification', (data) {
        try {
          if (data is Map<String, dynamic>) {
            final notification = NotificationItem.fromJson(
              data['notification'] as Map<String, dynamic>? ?? {},
            );
            _newNotificationCtrl.add(NewNotificationEvent(
              notification: notification,
            ));
            print('📬 New notification: ${notification.title}');
          }
        } catch (e) {
          print('Error parsing new notification: $e');
        }
      });

      // Unread count updated (real-time)
      _socket!.on('notification-count', (data) {
        try {
          if (data is Map<String, dynamic>) {
            final count = (data['unreadCount'] as num?)?.toInt() ?? 0;
            _countCtrl.add(NotificationCountEvent(unreadCount: count));
            print('📊 Notification count updated: $count');
          }
        } catch (e) {
          print('Error parsing notification count: $e');
        }
      });
    } catch (e) {
      print('❌ Failed to connect notification socket: $e');
      _isConnected = false;
      _connectionCtrl.add(false);
    }
  }

  /// Request current unread count from server
  void _requestUnreadCount() {
    if (!_isConnected || _socket == null) return;
    try {
      _socket!.emit('get-notification-count');
    } catch (e) {
      print('Error requesting unread count: $e');
    }
  }

  /// Mark a notification as read via socket (faster than HTTP)
  void markAsRead(String notificationId) {
    if (!_isConnected || _socket == null) return;
    try {
      _socket!.emit('mark-notification-read', {'notificationId': notificationId});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read via socket
  void markAllAsRead() {
    if (!_isConnected || _socket == null) return;
    try {
      _socket!.emit('mark-all-notifications-read');
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  /// Disconnect socket and clean up
  void disconnect() {
    if (_socket == null) return;
    try {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
      print('🔌 Notification socket disconnected');
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  /// Clean up all resources
  void dispose() {
    disconnect();
    _countCtrl.close();
    _newNotificationCtrl.close();
    _connectionCtrl.close();
  }
}
