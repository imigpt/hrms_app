import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:hrms_app/features/announcements/data/models/announcement_model.dart';
import 'announcement_service.dart';
import 'package:hrms_app/shared/services/communication/notification_service.dart';
import 'token_storage_service.dart';
import 'package:hrms_app/core/config/api_config.dart';

class AnnouncementWebSocketService {
  // WebSocket host based on environment
  static String get _wsHost {
    final baseUrl = ApiConfig.baseUrl;
    if (baseUrl.contains('localhost')) {
      return 'localhost:5000';
    }
    return 'hrms-backend-807r.onrender.com';
  }
  // Try common WebSocket paths — update if the backend uses a different one
  static const String _wsPath = '/ws';

  WebSocketChannel? _channel;
  StreamController<List<Announcement>>? _announcementsController;
  StreamSubscription? _channelSubscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  String? _token;
  bool _isConnected = false;
  bool _isDisposed = false;
  bool _wsUnavailable = false; // set true if server doesn't support WS
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 2; // reduced to avoid spam
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  List<Announcement> _cachedAnnouncements = [];

  // Stream for announcements
  Stream<List<Announcement>> get announcementsStream {
    _announcementsController ??=
        StreamController<List<Announcement>>.broadcast();
    return _announcementsController!.stream;
  }

  bool get isConnected => _isConnected;

  // Connect to WebSocket
  Future<void> connect(String token) async {
    if (_isDisposed) {
      print('WebSocket service is disposed, cannot connect');
      return;
    }

    // Skip if server previously rejected WS upgrade
    if (_wsUnavailable) {
      print('WebSocket not available on server — using REST API only');
      return;
    }

    _token = token;

    try {
      // Build a proper wss:// URI with explicit port 443
      final uri = Uri(
        scheme: 'wss',
        host: _wsHost,
        port: 443,
        path: _wsPath,
        queryParameters: {'token': token},
      );

      print('Connecting to WebSocket: $uri');

      _channel = WebSocketChannel.connect(uri);

      // Wait for connection with a timeout
      await _channel!.ready.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('WebSocket connection timed out'),
      );

      _isConnected = true;
      _reconnectAttempts = 0;

      print('WebSocket connected successfully');

      // Start heartbeat
      _startHeartbeat();

      // Listen to messages
      _channelSubscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      // Request initial announcements
      _sendMessage({
        'type': 'get_announcements',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('WebSocket connection error: $e');
      _isConnected = false;

      // If "not upgraded to websocket", server doesn't support WS — stop retrying
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('not upgraded') ||
          errStr.contains('was not upgraded')) {
        print(
          'Server does not support WebSocket upgrades. Falling back to REST API only.',
        );
        _wsUnavailable = true;
        return;
      }

      _scheduleReconnect();
    }
  }

  // Handle incoming messages
  void _handleMessage(dynamic message) {
    if (_isDisposed) return;

    try {
      final data = json.decode(message.toString());
      print('WebSocket message received: ${data['type']}');

      switch (data['type']) {
        case 'announcements':
          _handleAnnouncementsList(data);
          break;
        case 'new_announcement':
          _handleNewAnnouncement(data);
          break;
        case 'updated_announcement':
          _handleUpdatedAnnouncement(data);
          break;
        case 'deleted_announcement':
          _handleDeletedAnnouncement(data);
          break;
        case 'pong':
          // Heartbeat response
          print('Heartbeat received');
          break;
        default:
          print('Unknown message type: ${data['type']}');
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  // Handle announcements list
  void _handleAnnouncementsList(Map<String, dynamic> data) {
    try {
      if (data['data'] != null && data['data'] is List) {
        final announcements = (data['data'] as List)
            .map((item) => Announcement.fromJson(item))
            .toList();

        // Sort by date (newest first)
        announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _cachedAnnouncements = announcements;
        // Create a new list instance to ensure stream emits
        _announcementsController?.add(List.from(_cachedAnnouncements));

        print('Received ${announcements.length} announcements');
      }
    } catch (e) {
      print('Error parsing announcements list: $e');
    }
  }

  // Handle new announcement
  void _handleNewAnnouncement(Map<String, dynamic> data) {
    try {
      if (data['data'] != null) {
        final newAnnouncement = Announcement.fromJson(data['data']);

        // Add to the beginning of the list
        _cachedAnnouncements.insert(0, newAnnouncement);
        // Create a new list instance to ensure stream emits
        _announcementsController?.add(List.from(_cachedAnnouncements));

        print('New announcement received: ${newAnnouncement.title}');

        // Show notification for new announcement
        _showAnnouncementNotification(newAnnouncement);
      }
    } catch (e) {
      print('Error handling new announcement: $e');
    }
  }

  // Show notification for new announcement
  void _showAnnouncementNotification(Announcement announcement) {
    try {
      final notificationService = NotificationService();

      // Extract plain text from HTML if needed
      String message = announcement.content;
      if (message.contains('<')) {
        // Simple HTML tag removal
        message = message.replaceAll(RegExp(r'<[^>]*>'), '');
      }

      // Trim whitespace and limit length
      message = message.trim();
      String displayMessage = message.length > 150
          ? '${message.substring(0, 150)}...'
          : message;

      notificationService.showAnnouncementNotification(
        title: announcement.title,
        message: displayMessage,
        body: displayMessage,
        payload: {'id': announcement.id},
      );

      print('✅ Notification triggered for: ${announcement.title}');
    } catch (e) {
      print('Error showing announcement notification: $e');
    }
  }

  // Handle updated announcement
  void _handleUpdatedAnnouncement(Map<String, dynamic> data) {
    try {
      if (data['data'] != null) {
        final updatedAnnouncement = Announcement.fromJson(data['data']);

        // Find and replace the existing announcement
        final index = _cachedAnnouncements.indexWhere(
          (a) => a.id == updatedAnnouncement.id,
        );

        if (index != -1) {
          _cachedAnnouncements[index] = updatedAnnouncement;
          // Create a new list instance to ensure stream emits
          _announcementsController?.add(List.from(_cachedAnnouncements));

          print('Announcement updated: ${updatedAnnouncement.title}');
        }
      }
    } catch (e) {
      print('Error handling updated announcement: $e');
    }
  }

  // Handle deleted announcement
  void _handleDeletedAnnouncement(Map<String, dynamic> data) {
    try {
      if (data['id'] != null) {
        final deletedId = data['id'] as String;

        _cachedAnnouncements.removeWhere((a) => a.id == deletedId);
        // Create a new list instance to ensure stream emits
        _announcementsController?.add(List.from(_cachedAnnouncements));

        print('Announcement deleted: $deletedId');
      }
    } catch (e) {
      print('Error handling deleted announcement: $e');
    }
  }

  // Handle errors
  void _handleError(error) {
    final errStr = error.toString().toLowerCase();
    print('WebSocket error: $error');
    _isConnected = false;

    if (errStr.contains('not upgraded') ||
        errStr.contains('was not upgraded')) {
      print('Server does not support WebSocket. Disabling reconnect.');
      _wsUnavailable = true;
      return;
    }

    _scheduleReconnect();
  }

  // Handle disconnection
  void _handleDisconnect() {
    print('WebSocket disconnected');
    _isConnected = false;
    _stopHeartbeat();
    _scheduleReconnect();
  }

  // Schedule reconnection
  void _scheduleReconnect() {
    if (_isDisposed ||
        _wsUnavailable ||
        _reconnectAttempts >= _maxReconnectAttempts) {
      print(
        'Max reconnect attempts reached, service disposed, or WebSocket unavailable',
      );
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectAttempts++;
      print(
        'Attempting to reconnect (${_reconnectAttempts}/$_maxReconnectAttempts)...',
      );

      if (_token != null) {
        connect(_token!);
      }
    });
  }

  // Start heartbeat
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_isConnected) {
        _sendMessage({'type': 'ping'});
      }
    });
  }

  // Stop heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Send message to WebSocket
  void _sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(json.encode(message));
      } catch (e) {
        print('Error sending WebSocket message: $e');
      }
    }
  }

  // Mark announcement as read via REST API (primary) + WebSocket (supplementary)
  Future<bool> markAsRead(String announcementId) async {
    // Call REST API
    bool success = false;
    try {
      final token = await TokenStorageService().getToken();
      if (token != null) {
        success = await AnnouncementService.markAsRead(
          token: token,
          announcementId: announcementId,
        );
      }
    } catch (e) {
      print('REST markAsRead error: \$e');
    }

    // Also notify via WebSocket if connected
    _sendMessage({
      'type': 'mark_read',
      'announcementId': announcementId,
      'timestamp': DateTime.now().toIso8601String(),
    });

    return success;
  }

  // Disconnect and cleanup
  Future<void> disconnect() async {
    print('Disconnecting WebSocket...');

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _stopHeartbeat();

    await _channelSubscription?.cancel();
    _channelSubscription = null;

    await _channel?.sink.close(status.goingAway);
    _channel = null;

    _isConnected = false;
  }

  // Dispose the service
  Future<void> dispose() async {
    if (_isDisposed) return;

    print('Disposing WebSocket service...');
    _isDisposed = true;

    await disconnect();

    await _announcementsController?.close();
    _announcementsController = null;

    _cachedAnnouncements.clear();
  }
}
