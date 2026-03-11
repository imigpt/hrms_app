import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_notification_service.dart';

/// Standalone plugin instance used ONLY inside the background isolate.
/// The foreground singleton [NotificationService._notificationsPlugin] is
/// not accessible from a separate isolate, so we create a fresh one here.
final FlutterLocalNotificationsPlugin _bgPlugin =
    FlutterLocalNotificationsPlugin();

/// Whether the background plugin has been initialised in this isolate.
bool _bgPluginReady = false;

/// Initialise [_bgPlugin] once per background-isolate lifetime.
Future<void> _initBgPlugin() async {
  if (_bgPluginReady) return;
  const AndroidInitializationSettings android =
      AndroidInitializationSettings('@mipmap/launcher_icon');
  const DarwinInitializationSettings ios = DarwinInitializationSettings();
  await _bgPlugin.initialize(
    const InitializationSettings(android: android, iOS: ios),
  );
  _bgPluginReady = true;
}

/// Map notification [type] to the pre-created Android channel.
/// Must stay in sync with the channels registered in [requestNotificationPermissions].
String _channelForType(String type) {
  switch (type) {
    case 'chat':          return 'chat_channel';
    case 'announcement':  return 'announcements_channel';
    case 'task_assigned':
    case 'task_updated':
    case 'task_comment':  return 'task_channel';
    case 'leave':         return 'leave_channel';
    case 'approval':      return 'approval_channel';
    case 'expense':       return 'expense_channel';
    case 'payroll':       return 'payroll_channel';
    case 'attendance':    return 'attendance_channel';
    default:              return 'hrms_notifications';
  }
}

/// Build a human-readable notification body that includes type-specific
/// context extracted from the FCM data payload.
String _buildBody(RemoteMessage message, String fallbackBody) {
  final data = message.data;
  final type = data['type'] ?? 'general';

  switch (type) {
    case 'chat':
      final sender  = data['senderName'] ?? 'Someone';
      final isGroup = data['isGroup'] == 'true';
      final group   = data['groupName'] ?? '';
      final media   = data['mediaType'] ?? '';
      final action  = data['action'] ?? '';
      if (action == 'group_created')         return '$sender created group "$group"';
      if (action == 'group_members_added')   return '$sender added you to "$group"';
      if (action == 'group_member_removed')  return 'You were removed from "$group"';
      if (media == 'image' || media == 'photo')     return '$sender: 📷 Image';
      if (media == 'voice' || media == 'audio')     return '$sender: 🎙️ Voice message';
      if (media == 'document' || media == 'file')   return '$sender: 📄 Document';
      if (media == 'video')                          return '$sender: 🎬 Video';
      return isGroup && group.isNotEmpty ? '$sender: $fallbackBody' : fallbackBody;

    case 'task_assigned':
      final task = data['taskTitle'] ?? '';
      final by   = data['assignedBy'] ?? 'Someone';
      return task.isNotEmpty ? '$by assigned you: "$task"' : fallbackBody;

    case 'task_updated':
      final task   = data['taskTitle'] ?? '';
      final change = data['change'] ?? fallbackBody;
      return task.isNotEmpty ? '"$task" — $change' : fallbackBody;

    case 'task_comment':
      final task = data['taskTitle'] ?? '';
      final by   = data['commentBy'] ?? 'Someone';
      return task.isNotEmpty ? '$by commented on "$task"' : fallbackBody;

    case 'leave':
      final action = data['action'] ?? data['leaveStatus'] ?? '';
      final lType  = data['leaveType'] ?? '';
      if (action == 'approved') return '${lType.isNotEmpty ? lType : 'Leave'} approved ✅';
      if (action == 'rejected') return '${lType.isNotEmpty ? lType : 'Leave'} rejected ❌';
      if (action == 'cancelled') return '${lType.isNotEmpty ? lType : 'Leave'} request cancelled';
      if (action == 'half_day') {
        final emp = data['employeeName'] ?? 'An employee';
        return '$emp requested a half day';
      }
      return fallbackBody;

    case 'expense':
      final action = data['action'] ?? data['expenseStatus'] ?? '';
      final amount = data['amount'] ?? '';
      final suffix = amount.isNotEmpty ? ' (₹$amount)' : '';
      if (action == 'approved') return 'Expense approved ✅$suffix';
      if (action == 'rejected') return 'Expense rejected ❌$suffix';
      if (action == 'paid')     return 'Expense paid 💰$suffix';
      if (action == 'created') {
        final emp = data['employeeName'] ?? 'An employee';
        return '$emp submitted an expense$suffix';
      }
      return fallbackBody;

    case 'attendance':
      final action = data['action'] ?? '';
      final by     = data['requestedBy'] ?? '';
      if (action == 'edit_requested') return '${by.isNotEmpty ? by : 'An employee'} requested attendance edit';
      if (action == 'approved') return 'Attendance edit approved ✅';
      if (action == 'rejected') return 'Attendance edit rejected ❌';
      return fallbackBody;

    case 'payroll':
      final action = data['action'] ?? '';
      final month  = data['month'] ?? '';
      final year   = data['year'] ?? '';
      final amount = data['amount'] ?? '';
      final period = (month.isNotEmpty && year.isNotEmpty) ? ' for $month/$year' : '';
      if (action == 'payroll_generated') return 'Payroll generated$period 💵';
      if (action == 'pre_payment') {
        return 'Salary advance credited${amount.isNotEmpty ? ': ₹$amount' : ''}  💸';
      }
      if (action == 'increment' || action == 'promotion') {
        return 'Congratulations! ${action == 'promotion' ? 'Promotion 🎉' : 'Increment 🎉'}';
      }
      return fallbackBody;

    default:
      return fallbackBody;
  }
}

/// Show a system-tray notification from the background isolate.
/// Called for BOTH regular fcm+notification messages (to override the channel)
/// and pure data-only messages where Android won't auto-show anything.
Future<void> _showBgNotification(RemoteMessage message) async {
  await _initBgPlugin();

  final type  = message.data['type']?.toString() ?? 'general';
  final title = message.notification?.title ??
                message.data['title']?.toString() ?? 'HRMS';
  final rawBody = message.notification?.body ??
                  message.data['body']?.toString() ??
                  message.data['message']?.toString() ?? '';
  final body  = _buildBody(message, rawBody);
  final refId = message.data['referenceId']?.toString() ?? '';

  if (title.isEmpty && body.isEmpty) return;

  final channelId = _channelForType(type);

  // Stable notification ID per reference (or random fallback)
  final notifId = refId.isNotEmpty
      ? refId.hashCode.abs() % 2147483647
      : DateTime.now().millisecondsSinceEpoch ~/ 1000;

  final androidDetails = AndroidNotificationDetails(
    channelId,
    channelId, // channel name equals id — channels are already named in foreground init
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

  await _bgPlugin.show(
    notifId,
    title,
    body,
    NotificationDetails(android: androidDetails, iOS: iosDetails),
    payload: '$type|$refId',
  );
}

// ─── Background message handler (must be top-level) ──────────────────────────
// This runs in its own isolate when the app is killed / in background.
// It must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // IMPORTANT: Use print() not debugPrint() — debugPrint won't show in background!
  print('═══════════════════════════════════════════════════════════');
  print('🔥 FCM BACKGROUND/TERMINATED MESSAGE RECEIVED 🔥');
  print('═══════════════════════════════════════════════════════════');

  final type  = message.data['type']?.toString() ?? 'general';
  final title = message.notification?.title ??
                message.data['title']?.toString() ?? 'HRMS';
  final body  = message.notification?.body ??
                message.data['body']?.toString() ??
                message.data['message']?.toString() ?? '';
  final refId = message.data['referenceId']?.toString() ?? '';

  print('[DATA] Type: $type');
  print('[DATA] ReferenceId: $refId');
  print('[NOTIFICATION] Title: $title');
  print('[NOTIFICATION] Body: $body');

  // ── Display notification in system tray ─────────────────────────────────
  // We always call _showBgNotification so that:
  //  • data-only messages (no 'notification' field) are shown in the tray.
  //  • regular messages are shown on the CORRECT typed channel instead of
  //    the generic 'hrms_notifications' fallback.
  try {
    await _showBgNotification(message);
    print('✅ Background notification displayed (type=$type, channel=${_channelForType(type)})');
  } catch (e) {
    print('⚠️ _showBgNotification error: $e');
  }

  print('═══════════════════════════════════════════════════════════');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  bool _isInitialized = false;
  bool _isInitializing = false; // Prevent concurrent initialization
  
  // Notification deduplication: track recently displayed notifications
  final Set<String> _recentNotificationIds = {};
  static const int _dedupeWindowMs = 5000; // 5 second window
  
  // FCM token registration retry config
  static const int _maxTokenRetries = 3;
  static const Duration _tokenRetryDelay = Duration(seconds: 2);

  // Active onTokenRefresh subscription — cancelled before each re-subscribe
  // to prevent duplicate listeners when registerFcmToken() is called more than once.
  StreamSubscription<String>? _tokenRefreshSub;

  /// Global navigator key — assign this to [MaterialApp.navigatorKey] so
  /// NotificationService can push routes without a BuildContext.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Register a handler here (e.g. from main.dart / HrmsApp) to perform
  /// the actual screen navigation when a notification is tapped.
  /// Signature: (type, referenceId) where type matches the backend types
  /// (chat, leave, task_assigned, etc.) and referenceId is the entity ID.
  static void Function(String type, String referenceId)? onNotificationTap;

  /// Holds the notification type/referenceId from a terminated-state tap.
  /// Consumed by the app once the navigator and auth state are ready.
  static String? pendingNotificationType;
  static String? pendingNotificationReferenceId;

  /// Set to the currently open chat room ID so FCM-triggered notifications
  /// are suppressed when the user is already viewing that conversation.
  static String? activeChatRoomId;

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
      // Wait up to 30 seconds for init to complete (increased timeout)
      int waited = 0;
      while (_isInitializing && waited < 300) {
        await Future.delayed(const Duration(milliseconds: 100));
        waited++;
      }
      if (_isInitializing) {
        debugPrint('⚠️ Initialization timeout after 30 seconds');
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
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'approval_channel',
            'Approval Notifications',
            description: 'Notifications for approval requests',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'expense_channel',
            'Expense Notifications',
            description: 'Notifications for expense claims',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'payroll_channel',
            'Payroll Notifications',
            description: 'Notifications for payroll and salary updates',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'attendance_channel',
            'Attendance Notifications',
            description: 'Notifications for attendance updates',
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
  /// Includes retry logic and permission verification.
  Future<void> registerFcmToken(String authToken) async {
    // Guard: can't register without a valid JWT.
    if (authToken.isEmpty) {
      debugPrint('❌ registerFcmToken: authToken is empty, aborting.');
      return;
    }
    try {
      // Request permission (iOS prompt, Android 13+) and verify it was granted
      debugPrint('📲 Requesting notification permissions...');
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      final permissionGranted = settings.authorizationStatus == AuthorizationStatus.authorized;
      debugPrint('📲 Permission status: ${settings.authorizationStatus} (granted: $permissionGranted)');

      final token = await _fcm.getToken();
      debugPrint('🔑 FCM getToken() result: ${token == null ? 'NULL' : '${token.substring(0, token.length.clamp(0, 20))}...'}');
      if (token != null && token.isNotEmpty) {
        final device = Platform.isIOS ? 'ios' : 'android';
        debugPrint('🔑 Got FCM token (${token.length} chars) for device: $device');

        // Deduplication guard: only send to backend if token changed
        final prefs = await SharedPreferences.getInstance();
        final lastSentToken = prefs.getString('last_sent_fcm_token');
        if (lastSentToken == token) {
          debugPrint('⏭️ FCM token unchanged, skipping backend registration');
          // Still set up onTokenRefresh listener below
        } else {
        // Register token with retry logic
        bool saved = false;
        for (int attempt = 1; attempt <= _maxTokenRetries; attempt++) {
          try {
            debugPrint('📤 Saving token (attempt $attempt/$_maxTokenRetries)...');
            saved = await ApiNotificationService.saveToken(
              authToken: authToken,
              fcmToken: token,
              device: device,
            );
            if (saved) {
              debugPrint('✅ FCM token registered successfully (attempt $attempt)');
              await prefs.setString('last_sent_fcm_token', token);
              break;
            }
          } catch (e) {
            debugPrint('❌ Token registration failed on attempt $attempt: $e');
            if (attempt < _maxTokenRetries) {
              await Future.delayed(_tokenRetryDelay);
            }
          }
        }
        
        if (!saved) {
          debugPrint('❌ Failed to register FCM token after $_maxTokenRetries attempts');
        }
        } // end deduplication check
      } else {
        debugPrint('⚠️ Could not retrieve FCM token');
      }

      // Re-register whenever the token rotates.
      // Cancel any previous subscription first to avoid stacking listeners
      // when registerFcmToken() is called on both login and auth-check screens.
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _fcm.onTokenRefresh.listen((newToken) async {
        if (newToken.isEmpty) return;
        final device = Platform.isIOS ? 'ios' : 'android';
        debugPrint('🔄 FCM token refreshed: ${newToken.substring(0, newToken.length.clamp(0, 20))}...');

        for (int attempt = 1; attempt <= _maxTokenRetries; attempt++) {
          try {
            final saved = await ApiNotificationService.saveToken(
              authToken: authToken,
              fcmToken: newToken,
              device: device,
            );
            if (saved) {
              debugPrint('✅ Token refresh registered successfully');
              final p = await SharedPreferences.getInstance();
              await p.setString('last_sent_fcm_token', newToken);
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
    } catch (e) {
      debugPrint('❌ Critical error registering FCM token: $e');
    }
  }

  /// Remove FCM token from the backend (call on logout).
  Future<void> removeFcmToken(String authToken) async {
    if (authToken.isEmpty) {
      debugPrint('⚠️ removeFcmToken: authToken is empty, skipping.');
      return;
    }
    try {
      // Cancel token-refresh listener so it doesn't fire after logout.
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = null;

      // Clear stored token so the next login always re-registers
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_sent_fcm_token');

      final token = await _fcm.getToken();
      if (token != null && token.isNotEmpty) {
        await ApiNotificationService.removeToken(
          authToken: authToken,
          fcmToken: token,
        );
        debugPrint('✅ FCM token removed from backend');
      } else {
        debugPrint('⚠️ removeFcmToken: no token on device, nothing to remove');
      }
    } catch (e) {
      debugPrint('❌ Error removing FCM token: $e');
    }
  }

  // ── Deep-link navigation ─────────────────────────────────────────────────

  /// Retry navigation for up to [maxAttempts] × 500 ms, waiting for the
  /// navigator key to have a live state (i.e. the widget tree is built).
  void _navigateWithRetry(String type, String ref, {int maxAttempts = 10}) {
    int attempt = 0;
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      attempt++;
      final nav = navigatorKey.currentState;
      if (nav != null && onNotificationTap != null) {
        print('   → [attempt $attempt] Navigator ready, routing: type=$type, ref=$ref');
        pendingNotificationType        = null;
        pendingNotificationReferenceId = null;
        _handleNotificationTap(type, ref);
        return false; // stop loop
      }
      if (attempt >= maxAttempts) {
        print('   ⚠️ Navigator not ready after $maxAttempts attempts. Notification remains pending.');
        return false; // stop loop — app will consume pendingNotification later
      }
      return true; // keep retrying
    });
  }

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

    // ── iOS: show foreground notifications as banners ──────────────────────
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // ── Terminated-state tap ────────────────────────────────────────────────
    // The app was fully closed when the user tapped the notification.
    // We store the payload and retry navigation until the navigator is ready
    // (up to 6 × 500 ms = 3 s) so app-startup async work doesn't lose the tap.
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        print('🔔 FCM terminated-state tap: ${initial.notification?.title}');
        print('   Notification: ${initial.notification?.body}');
        print('   Type: ${initial.data['type']}');
        print('   ReferenceId: ${initial.data['referenceId']}');

        final type = initial.data['type']?.toString() ?? 'general';
        final ref  = initial.data['referenceId']?.toString() ?? '';

        // Store for later consumption by the app once auth is resolved.
        pendingNotificationType     = type;
        pendingNotificationReferenceId = ref;

        print('   → Stored pending notification: type=$type, ref=$ref');
        print('   → Will navigate once navigator + auth are ready.');

        // Also attempt immediate navigation with retries.
        _navigateWithRetry(type, ref);
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
      try {
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
        // Use backend-assigned notificationId for dedup when available
        final notificationId = (message.data['notificationId']?.toString().isNotEmpty == true)
            ? message.data['notificationId']!
            : message.messageId ?? '${message.sentTime}';

        print('[EXTRACTED]');
        print('  Title: $title');
        print('  Body: $body');
        print('  Type: $type');
        print('  ReferenceId: $referenceId');
        print('  NotifId: $notificationId');

        if (title.isEmpty && body.isEmpty) {
          print('⚠️ Empty notification, skipping display');
          return;
        }

        // DEDUPLICATION CHECK: Skip if we just showed this notification
        if (_recentNotificationIds.contains(notificationId)) {
          print('⚠️ Notification already shown recently (dedup), skipping duplicate');
          return;
        }
        _recentNotificationIds.add(notificationId);
        // Clear dedup cache after window expires
        Future.delayed(Duration(milliseconds: _dedupeWindowMs), () {
          _recentNotificationIds.remove(notificationId);
        });

        // Identify notification type and log extra fields from backend
        if (type == 'chat') {
          final action = message.data['action'] ?? '';
          final senderName = message.data['senderName'] ?? 'Unknown';
          final isGroup = message.data['isGroup'] == 'true';
          final groupName = message.data['groupName'] ?? '';
          final mediaType = message.data['mediaType'] ?? '';
          final roomId = message.data['roomId'] ?? message.data['chatRoomId'] ?? referenceId;
          
          print('[💬 CHAT NOTIFICATION DETECTED]');
          print('  Sender: $senderName');
          print('  RoomId: $roomId');
          if (isGroup) print('  Group: $groupName');
          if (action.isNotEmpty) print('  Action: $action');
          if (mediaType.isNotEmpty) print('  Media: $mediaType');
          print('  Using chat_channel for display');
          
          // Show specialized chat notification with media type handling
          if (!_isInitialized) {
            await initialize();
            await requestNotificationPermissions();
          }
          
          // Determine if this is a group action (not a regular message)
          bool isGroupAction = action == 'group_created' || 
                               action == 'group_members_added' || 
                               action == 'group_member_removed';
          
          // Build message preview based on media type (for regular messages)
          String messagePreview = body;
          if (!isGroupAction && mediaType.isNotEmpty) {
            if (mediaType == 'image' || mediaType == 'photo') {
              messagePreview = '📷 Image';
            } else if (mediaType == 'voice' || mediaType == 'audio') {
              messagePreview = '🎙️ Voice message';
            } else if (mediaType == 'document' || mediaType == 'file') {
              messagePreview = '📄 Document';
            } else if (mediaType == 'video') {
              messagePreview = '🎬 Video';
            }
          }
          
          // Determine room display name
          final roomDisplayName = isGroup ? groupName : senderName;
          
          // Call specialized chat notification method with group action support
          try {
            await showChatNotification(
              senderName: senderName,
              roomName: roomDisplayName,
              message: messagePreview,
              roomId: roomId,
              isGroupAction: isGroupAction,
              action: action,
            );
            print('✅ Chat notification sent via specialized method');
          } catch (e) {
            print('⚠️ Error showing specialized chat notification: $e');
            print('   Falling back to generic display...');
            // Fall through to generic display below
          }
          
          // Early return after displaying via specialized method
          print('═════════════════════════════════════════════════════════════════');
          return;
        } else if (type == 'announcement') {
          print('[📢 ANNOUNCEMENT NOTIFICATION DETECTED]');
        } else if (type == 'task_assigned') {
          print('[✅ TASK ASSIGNED]');
          print('  Task: ${message.data['taskTitle'] ?? ''}');
          print('  By: ${message.data['assignedBy'] ?? 'Unknown'}');
        } else if (type == 'task_updated') {
          print('[✏️  TASK UPDATED]');
          print('  Task: ${message.data['taskTitle'] ?? ''}');
          print('  Change: ${message.data['change'] ?? ''}');
        } else if (type == 'task_comment') {
          print('[💬 TASK COMMENT]');
          print('  Task: ${message.data['taskTitle'] ?? ''}');
          print('  By: ${message.data['commentBy'] ?? 'Unknown'}');
        } else if (type == 'leave') {
          final leaveStatus = message.data['leaveStatus'] ?? '';
          final leaveType = message.data['leaveType'] ?? '';
          final action = message.data['action'] ?? '';
          print('[📋 LEAVE NOTIFICATION DETECTED]');
          if (leaveType.isNotEmpty) print('  Type: $leaveType');
          if (leaveStatus.isNotEmpty) print('  Status: $leaveStatus');
          if (action.isNotEmpty) print('  Action: $action');
        } else if (type == 'approval') {
          print('[🔔 APPROVAL REQUIRED]');
          print('  For: ${message.data['itemType'] ?? ''} - ${message.data['itemTitle'] ?? ''}');
          print('  By: ${message.data['requestedBy'] ?? 'Unknown'}');
        } else if (type == 'expense') {
          final expenseStatus = message.data['expenseStatus'] ?? '';
          final action = message.data['action'] ?? '';
          print('[💰 EXPENSE NOTIFICATION]');
          print('  Amount: ${message.data['amount'] ?? ''}');
          if (expenseStatus.isNotEmpty) print('  Status: $expenseStatus');
          if (action.isNotEmpty) print('  Action: $action');
        } else if (type == 'attendance') {
          print('[🕐 ATTENDANCE NOTIFICATION]');
          print('  Action: ${message.data['action'] ?? ''}');
          print('  By: ${message.data['requestedBy'] ?? ''}');
        } else if (type == 'payroll') {
          final action = message.data['action'] ?? '';
          print('[💵 PAYROLL NOTIFICATION]');
          print('  Period: ${message.data['month'] ?? ''}/${message.data['year'] ?? ''}');
          if (message.data['amount'] != null) print('  Amount: ${message.data['amount']}');
          if (action.isNotEmpty) print('  Action: $action');
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

        // Pick channel based on notification type (matches backend notificationTriggers.js)
        String channelId = 'hrms_notifications';
        String channelName = 'HRMS Notifications';
        if (type == 'chat') {
          channelId = 'chat_channel';
          channelName = 'Chat Messages';
        } else if (type == 'announcement') {
          channelId = 'announcements_channel';
          channelName = 'Announcements';
        } else if (type == 'leave') {
          channelId = 'leave_channel';
          channelName = 'Leave Notifications';
        } else if (type == 'task_assigned' || type == 'task_updated' || type == 'task_comment') {
          channelId = 'task_channel';
          channelName = 'Task Notifications';
        } else if (type == 'approval') {
          channelId = 'approval_channel';
          channelName = 'Approval Notifications';
        } else if (type == 'expense') {
          channelId = 'expense_channel';
          channelName = 'Expense Notifications';
        } else if (type == 'payroll') {
          channelId = 'payroll_channel';
          channelName = 'Payroll Notifications';
        } else if (type == 'attendance') {
          channelId = 'attendance_channel';
          channelName = 'Attendance Notifications';
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

        const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
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
        } catch (e, stackTrace) {
          print('[❌] Error displaying foreground notification: $e');
          print('Stack trace: $stackTrace');
          print('═════════════════════════════════════════════════════════════════');
          // Still trigger the tap handler even if display fails
          debugPrint('⚠️ Notification display failed, but processing tap anyway...');
        }
      } catch (e) {
        print('[❌] CRITICAL ERROR in foreground message handler: $e');
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
  /// [roomName]   – display name of the chat room or group
  /// [message]    – text preview (or "[image]", "[voice]", etc.)
  /// [roomId]     – used as payload so the app can navigate on tap
  /// [isGroupAction] – if true, indicates a group event (created/member added/removed)
  /// [action]     – group action type (group_created, group_members_added, group_member_removed)
  Future<void> showChatNotification({
    required String senderName,
    required String roomName,
    required String message,
    required String roomId,
    bool isGroupAction = false,
    String action = '',
  }) async {
    // Suppress if the user is currently viewing this chat room
    if (activeChatRoomId != null && activeChatRoomId == roomId) {
      print('🔕 Chat notification suppressed — user is viewing room $roomId');
      return;
    }

    if (!_isInitialized) {
      await initialize();
      await requestNotificationPermissions();
    }

    // Build display title based on action type
    String displayTitle = senderName;
    String displayBody = message;
    
    if (isGroupAction && action.isNotEmpty) {
      if (action == 'group_created') {
        displayTitle = '✨ New Group';
        displayBody = '$senderName created group "$roomName"';
      } else if (action == 'group_members_added') {
        displayTitle = '👥 Added to Group';
        displayBody = '$senderName added you to "$roomName"';
      } else if (action == 'group_member_removed') {
        displayTitle = '⚠️ Removed from Group';
        displayBody = 'You were removed from "$roomName"';
      }
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
            displayBody,
            contentTitle: !isGroupAction && roomName.isNotEmpty
                ? '$senderName • $roomName'
                : displayTitle,
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

    final id = roomId.hashCode.abs() % 100000; // stable per room

    try {
      await _notificationsPlugin.show(
        id,
        displayTitle,
        displayBody,
        details,
        // Encode as "chat|roomId" for tap routing
        payload: 'chat|$roomId',
      );
      print('✅ Chat notification displayed: $displayTitle');
    } catch (e) {
      print('❌ Error showing chat notification: $e');
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
