import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_notification_service.dart';

// ─── Background message handler (must be top-level) ──────────────────────────
// This runs in its own isolate when the app is killed / in background.
// It must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // IMPORTANT: Use print() not debugPrint() — debugPrint won't show in background!
  // FCM-ONLY MODE: No local notifications, just process FCM payload
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
    print('   The system will display this in the notification tray');
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
  print('✅ Android system will show notification automatically');
  print('═══════════════════════════════════════════════════════════');

  // In FCM-only mode, we don't show a local notification here
  // The system will automatically display the FCM notification
  // based on the notification payload from the backend
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  bool _isInitialized = false;
  bool _isInitializing = false; // Prevent concurrent initialization

  /// Global navigator key — assign this to [MaterialApp.navigatorKey] so
  /// NotificationService can push routes without a BuildContext.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Register a handler here (e.g. from main.dart / HrmsApp) to perform
  /// the actual screen navigation when a notification is tapped.
  /// Signature: (type, referenceId) where type matches the backend types
  /// (chat, leave, task_assigned, etc.) and referenceId is the entity ID.
  static void Function(String type, String referenceId)? onNotificationTap;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Initialize notification service (re-entrant, safe for concurrent calls)
  /// Must be called once when the app starts
  Future<void> initialize() async {
    // If already initialized, return immediately
    if (_isInitialized) return;
    
    // If currently initializing, wait for it to complete
    if (_isInitializing) {
      debugPrint('⏳ Initialization already in progress, waiting...');
      // Wait up to 10 seconds for init to complete
      int waited = 0;
      while (_isInitializing && waited < 100) {
        await Future.delayed(const Duration(milliseconds: 100));
        waited++;
      }
      return;
    }

    _isInitializing = true;

    try {
      // Android initialization
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      // iOS initialization
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      final InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final result = await _notificationsPlugin.initialize(
        initSettings,
        // Foreground local-notification tap handler
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload ?? '';
          debugPrint('🔔 Local notification tapped. payload: $payload');
          _routeFromPayload(payload);
        },
      );
      _isInitialized = result ?? false;

      debugPrint('Notification service initialized: $_isInitialized');
    } catch (e) {
      debugPrint('❌ Error initializing notification service: $e');
      _isInitialized = false;
    } finally {
      _isInitializing = false;
    }
  }

  /// Request notification permissions (Android 13+ and iOS)
  Future<bool> requestNotificationPermissions() async {
    try {
      // For Android 13+ (API 33+)
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        print('Android notification permission granted: $granted');

        // Create all notification channels upfront so they exist
        // before any background/terminated notification arrives.
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'general_channel',
            'General Notifications',
            description: 'General app notifications',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'announcements_channel',
            'Announcements',
            description: 'Notifications for new announcements',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'chat_channel',
            'Chat Messages',
            description: 'Notifications for new chat messages',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'leave_channel',
            'Leave Notifications',
            description: 'Notifications for leave approvals and rejections',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'task_channel',
            'Task Notifications',
            description: 'Notifications for task assignments and updates',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'hrms_notifications',
            'HRMS Notifications',
            description: 'HRMS app notifications',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );

        debugPrint('✅ All notification channels created');
        return granted ?? false;
      }

      // For iOS
      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iosPlugin != null) {
        final result = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('iOS notification permission granted: $result');
        return result ?? false;
      }

      return false;
    } catch (e) {
      print('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Show a notification for new announcement
  Future<void> showAnnouncementNotification({
    required String title,
    required String message,
    String? body,
    Map<String, String>? payload,
  }) async {
    try {
      // Ensure initialized
      if (!_isInitialized) {
        print('Notification service not initialized, initializing now...');
        await initialize();
        await requestNotificationPermissions();
      }

      final String displayBody = body ?? message;
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'announcements_channel',
            'Announcements',
            channelDescription: 'Notifications for new announcements',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/launcher_icon',
            // Expand full text when notification is expanded
            styleInformation: BigTextStyleInformation(displayBody),
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use unique ID based on timestamp
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      print('Showing notification: id=$notificationId, title=$title');

      await _notificationsPlugin.show(
        notificationId,
        title,
        displayBody,
        details,
        // Encode as "type|referenceId" for tap routing
        payload:
            'announcement|${payload?['id'] ?? payload?['referenceId'] ?? ''}',
      );

      print('Announcement notification shown successfully: $title');
    } catch (e, stackTrace) {
      print('Error showing notification: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Show a simple notification
  Future<void> showNotification({
    required String title,
    required String message,
    Map<String, String>? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'general_channel',
            'General',
            channelDescription: 'General notifications',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecond,
        title,
        message,
        details,
        payload: payload?['id'] ?? '',
      );

      print('Notification shown: $title');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      print('Error canceling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      print('Error canceling all notifications: $e');
    }
  }

  /// Test notification - call this to verify notifications are working
  Future<void> showTestNotification() async {
    await showAnnouncementNotification(
      title: 'Test Notification',
      message: 'Notifications are working correctly!',
      body: 'This is a test notification from HRMS App',
    );
  }

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  // ── FCM Token Management ────────────────────────────────────────────────

  /// Register FCM token with the backend and listen for token refresh.
  Future<void> registerFcmToken(String authToken) async {
    try {
      // Request permission (iOS prompt, Android 13+)
      await _fcm.requestPermission(alert: true, badge: true, sound: true);

      final token = await _fcm.getToken();
      if (token != null) {
        final device = Platform.isIOS ? 'ios' : 'android';
        final saved = await ApiNotificationService.saveToken(
          authToken: authToken,
          fcmToken: token,
          device: device,
        );
        debugPrint('FCM token ${saved ? 'saved ✅' : 'failed to save ❌'}');
      }

      // Re-register whenever the token rotates
      _fcm.onTokenRefresh.listen((newToken) async {
        final device = Platform.isIOS ? 'ios' : 'android';
        await ApiNotificationService.saveToken(
          authToken: authToken,
          fcmToken: newToken,
          device: device,
        );
        debugPrint('FCM token refreshed and saved ✅');
      });
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  /// Remove FCM token from the backend (call on logout).
  Future<void> removeFcmToken(String authToken) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await ApiNotificationService.removeToken(
          authToken: authToken,
          fcmToken: token,
        );
        debugPrint('FCM token removed ✅');
      }
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  // ── Deep-link navigation ─────────────────────────────────────────────────

  /// Invoke [onNotificationTap] callback registered by the app.
  void _handleNotificationTap(String type, String referenceId) {
    debugPrint('🔔 Notification tap → type=$type, ref=$referenceId');
    if (onNotificationTap != null) {
      onNotificationTap!(type, referenceId);
    } else {
      debugPrint('⚠ onNotificationTap not set — cannot navigate');
    }
  }

  /// Parse a local-notification payload string ("type|referenceId") and navigate.
  void _routeFromPayload(String payload) {
    if (payload.isEmpty) return;
    final parts = payload.split('|');
    final type = parts.isNotEmpty ? parts[0] : 'general';
    final ref = parts.length > 1 ? parts[1] : '';
    _handleNotificationTap(type, ref);
  }

  /// Set up FCM foreground + background handlers.
  /// Call once after Firebase.initializeApp().
  /// This handles notifications from both HRMS system and external apps.
  Future<void> setupFcmHandlers() async {
    debugPrint('🔧 Setting up FCM handlers for notifications...');

    // Background handler is registered in main.dart via:
    // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // ── Terminated-state tap ────────────────────────────────────────────────
    // The app was fully closed when the user tapped the notification.
    // We delay slightly to let the navigator settle after hot-start.
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        print('🔔 FCM terminated-state tap: ${initial.notification?.title}');
        print('   Notification: ${initial.notification?.body}');
        print('   Type: ${initial.data['type']}');
        print('   ReferenceId: ${initial.data['referenceId']}');
        
        // Delay to allow navigator to settle after app launch
        Future.delayed(const Duration(milliseconds: 1000), () {
          final type = initial.data['type']?.toString() ?? 'general';
          final ref = initial.data['referenceId']?.toString() ?? '';
          print('   → Routing to: type=$type, ref=$ref');
          _handleNotificationTap(type, ref);
        });
      }
    } catch (e) {
      print('❌ Error reading initial FCM message: $e');
    }

    // ── Background-state tap ───────────────────────────────────────────────
    // App was running in background; user tapped the system notification.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 FCM background tap: ${message.notification?.title}');
      print('   Notification: ${message.notification?.body}');
      print('   Data: ${message.data}');
      
      // Extract type and referenceId for navigation
      final type = message.data['type']?.toString() ?? 'general';
      final referenceId = message.data['referenceId']?.toString() ?? '';
      
      print('   → Routing to: type=$type, ref=$referenceId');
      
      // Navigate to appropriate screen based on notification type
      _handleNotificationTap(type, referenceId);
    });

    // ── Foreground messages ────────────────────────────────────────────────
    // Android does NOT auto-show FCM notifications when app is in foreground.
    // We use flutter_local_notifications purely as a DISPLAY mechanism — the
    // trigger is still FCM. This mirrors the system notification you'd see
    // when the app is closed.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('═════════════════════════════════════════════════════════════════');
      print('🔔 FCM FOREGROUND MESSAGE (App is OPEN)');
      print('═════════════════════════════════════════════════════════════════');
      print('[NOTIFICATION]');
      print('  Title: ${message.notification?.title}');
      print('  Body: ${message.notification?.body}');
      print('[DATA]');
      print('  Complete data map: ${message.data}');

      final title =
          message.notification?.title ??
          message.data['title']?.toString() ??
          '';
      final body =
          message.notification?.body ??
          message.data['message']?.toString() ??
          message.data['body']?.toString() ??
          '';
      final type = message.data['type']?.toString() ?? 'general';
      final referenceId = message.data['referenceId']?.toString() ?? '';

      print('[EXTRACTED]');
      print('  Title: $title');
      print('  Body: $body');
      print('  Type: $type');
      print('  ReferenceId: $referenceId');

      if (title.isEmpty && body.isEmpty) {
        print('⚠️ Empty notification, skipping display');
        return;
      }

      // Identify notification type
      if (type == 'chat' || type.toString().contains('chat')) {
        print('[💬 CHAT NOTIFICATION DETECTED]');
        print('  Sender: ${message.data['senderName'] ?? 'Unknown'}');
        print('  Room: ${message.data['roomName'] ?? 'Unknown'}');
        print('  Using chat_channel for display');
      } else if (type == 'announcement') {
        print('[📢 ANNOUNCEMENT NOTIFICATION DETECTED]');
      } else if (type.toString().contains('leave')) {
        print('[📋 LEAVE NOTIFICATION DETECTED]');
      } else if (type.toString().contains('task')) {
        print('[✓ TASK NOTIFICATION DETECTED]');
      } else {
        print('[📱 GENERAL/EXTERNAL NOTIFICATION: $type]');
      }

      print('📱 Displaying FCM notification in foreground');

      // Ensure service is initialized
      if (!_isInitialized) {
        try {
          await initialize();
          await requestNotificationPermissions();
        } catch (e) {
          print('❌ Init error in foreground handler: $e');
        }
      }

      // Pick channel based on notification type
      String channelId = 'hrms_notifications';
      String channelName = 'HRMS Notifications';
      if (type == 'chat') {
        channelId = 'chat_channel';
        channelName = 'Chat Messages';
      } else if (type == 'announcement') {
        channelId = 'announcements_channel';
        channelName = 'Announcements';
      } else if (type.startsWith('leave')) {
        channelId = 'leave_channel';
        channelName = 'Leave Notifications';
      } else if (type.startsWith('task')) {
        channelId = 'task_channel';
        channelName = 'Task Notifications';
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'HRMS $channelName',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/launcher_icon',
        styleInformation: BigTextStyleInformation(body),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      try {
        final notifId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final payload = '$type|$referenceId';
        
        print('[DISPLAY] Showing notification:');
        print('  ID: $notifId');
        print('  Channel: $channelId ($channelName)');
        print('  Title: $title');
        print('  Payload: $payload');
        
        await _notificationsPlugin.show(
          notifId,
          title,
          body,
          NotificationDetails(android: androidDetails, iOS: iosDetails),
          payload: payload,
        );
        
        print('[✅] FCM foreground notification displayed successfully');
        print('═════════════════════════════════════════════════════════════════');
      } catch (e) {
        print('[❌] Error showing foreground notification: $e');
        print('═════════════════════════════════════════════════════════════════');
      }
    });

    print('═════════════════════════════════════════════════════════════════');
    print('[✅] FCM HANDLERS SETUP COMPLETE');
    print('   • Background handler: ✓');
    print('   • Background tap handler: ✓');
    print('   • Foreground message handler: ✓');
    print('   • Chat notifications: ✓ (chat_channel)');
    print('   • External notifications: ✓');
    print('═════════════════════════════════════════════════════════════════');
  }

  /// Show a chat message notification.
  /// [senderName] – who sent the message
  /// [roomName]   – display name of the chat room
  /// [message]    – text preview (or "[image]" etc.)
  /// [roomId]     – used as payload so the app can navigate on tap
  Future<void> showChatNotification({
    required String senderName,
    required String roomName,
    required String message,
    required String roomId,
  }) async {
    if (!_isInitialized) {
      await initialize();
      await requestNotificationPermissions();
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'chat_channel',
          'Chat Messages',
          channelDescription: 'Notifications for new chat messages',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/launcher_icon',
          // Show full message when the notification is expanded
          styleInformation: BigTextStyleInformation(
            message,
            contentTitle: roomName.isNotEmpty
                ? '$senderName • $roomName'
                : senderName,
          ),
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Title: sender name; body: message preview
    final title = senderName;
    final body = message;

    final id = roomId.hashCode.abs() % 100000; // stable per room

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        details,
        // Encode as "chat|roomId" for tap routing
        payload: 'chat|$roomId',
      );
    } catch (e) {
      print('Error showing chat notification: $e');
    }
  }

  /// Show notification for leave approved
  Future<void> showLeaveApprovedNotification({
    required String employeeName,
    required String leaveType,
    required String startDate,
    required String endDate,
  }) async {
    if (!_isInitialized) {
      await initialize();
      await requestNotificationPermissions();
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'leave_channel',
          'Leave Notifications',
          channelDescription:
              'Notifications for leave approvals and rejections',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/launcher_icon',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = 'Leave Approved';
    final body =
        '$employeeName\'s $leaveType leave has been approved ($startDate to $endDate)';

    try {
      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: 'leave_approved',
      );
      print('Leave approved notification shown: $title');
    } catch (e) {
      print('Error showing leave approved notification: $e');
    }
  }

  /// Show notification for leave rejected
  Future<void> showLeaveRejectedNotification({
    required String employeeName,
    required String leaveType,
    String? reason,
  }) async {
    if (!_isInitialized) {
      await initialize();
      await requestNotificationPermissions();
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'leave_channel',
          'Leave Notifications',
          channelDescription:
              'Notifications for leave approvals and rejections',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/launcher_icon',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = 'Leave Rejected';
    final body = reason != null && reason.isNotEmpty
        ? '$employeeName\'s $leaveType leave has been rejected: $reason'
        : '$employeeName\'s $leaveType leave has been rejected';

    try {
      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: 'leave_rejected',
      );
      print('Leave rejected notification shown: $title');
    } catch (e) {
      print('Error showing leave rejected notification: $e');
    }
  }

  /// Show notification for task assigned
  Future<void> showTaskAssignedNotification({
    required String taskTitle,
    required String assignedTo,
    String? priority,
  }) async {
    if (!_isInitialized) {
      await initialize();
      await requestNotificationPermissions();
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'task_channel',
          'Task Notifications',
          channelDescription: 'Notifications for task assignments and updates',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/launcher_icon',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final priorityLabel = priority != null && priority.isNotEmpty
        ? ' [$priority]'
        : '';
    final title = 'Task Assigned';
    final body =
        'Task "$taskTitle" has been assigned to $assignedTo$priorityLabel';

    try {
      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: 'task_assigned',
      );
      print('Task assigned notification shown: $title');
    } catch (e) {
      print('Error showing task assigned notification: $e');
    }
  }

  /// Show notification for task updated
  Future<void> showTaskUpdateNotification({
    required String taskTitle,
    required String
    updateType, // e.g., 'completed', 'status_changed', 'deadline_reminder'
    String? details,
  }) async {
    if (!_isInitialized) {
      await initialize();
      await requestNotificationPermissions();
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'task_channel',
          'Task Notifications',
          channelDescription: 'Notifications for task assignments and updates',
          importance: Importance.defaultImportance,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/launcher_icon',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = 'Task Update: $taskTitle';
    final body = details ?? 'Task $updateType';

    try {
      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: 'task_update',
      );
      print('Task update notification shown: $title');
    } catch (e) {
      print('Error showing task update notification: $e');
    }
  }

  /// Show generic status notification
  Future<void> showStatusNotification({
    required String title,
    required String message,
    String? notificationType,
    String? referenceId,
  }) async {
    if (!_isInitialized) {
      await initialize();
      await requestNotificationPermissions();
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'general_channel',
          'General Notifications',
          channelDescription: 'General app notifications',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/launcher_icon',
          // Expand full text when notification is expanded
          styleInformation: BigTextStyleInformation(message),
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        message,
        details,
        // Encode as "type|referenceId" for tap routing
        payload: '${notificationType ?? 'general'}|${referenceId ?? ''}',
      );
      print('Status notification shown: $title');
    } catch (e) {
      print('Error showing status notification: $e');
    }
  }
}
