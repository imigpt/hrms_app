import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Initialize notification service
  /// Must be called once when the app starts
  Future<void> initialize() async {
    if (_isInitialized) return;

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

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final result = await _notificationsPlugin.initialize(initSettings);
    _isInitialized = result ?? false;

    print('Notification service initialized: $_isInitialized');
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

        // Create notification channels
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

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'announcements_channel',
            'Announcements',
            channelDescription: 'Notifications for new announcements',
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
        body ?? message,
        details,
        payload: payload?['id'] ?? '',
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

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'chat_channel',
          'Chat Messages',
          channelDescription: 'Notifications for new chat messages',
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
        payload: roomId,
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
          channelDescription: 'Notifications for leave approvals and rejections',
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
    final body = '$employeeName\'s $leaveType leave has been approved ($startDate to $endDate)';

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
          channelDescription: 'Notifications for leave approvals and rejections',
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

    final priorityLabel = priority != null && priority.isNotEmpty ? ' [$priority]' : '';
    final title = 'Task Assigned';
    final body = 'Task "$taskTitle" has been assigned to $assignedTo$priorityLabel';

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
    required String updateType, // e.g., 'completed', 'status_changed', 'deadline_reminder'
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
  }) async {
    if (!_isInitialized) {
      await initialize();
      await requestNotificationPermissions();
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'general_channel',
          'General Notifications',
          channelDescription: 'General app notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/launcher_icon',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        message,
        details,
        payload: notificationType ?? '',
      );
      print('Status notification shown: $title');
    } catch (e) {
      print('Error showing status notification: $e');
    }
  }
}
