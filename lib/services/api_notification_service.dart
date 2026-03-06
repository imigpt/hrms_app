import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── Model ─────────────────────────────────────────────────────────────────

class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String? referenceId;
  bool isRead;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;
  final bool pushSent;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.referenceId,
    this.isRead = false,
    this.readAt,
    this.metadata,
    this.pushSent = false,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      referenceId: json['referenceId']?.toString(),
      isRead: json['isRead'] == true,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      pushSent: json['pushSent'] == true,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class NotificationPagination {
  final int page;
  final int limit;
  final int total;
  final int pages;

  const NotificationPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory NotificationPagination.fromJson(Map<String, dynamic> json) {
    return NotificationPagination(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      pages: (json['pages'] as num?)?.toInt() ?? 1,
    );
  }

  bool get hasMore => page < pages;
}

typedef NotificationPage = ({
  List<NotificationItem> items,
  NotificationPagination pagination,
});

// ─── Service ───────────────────────────────────────────────────────────────

class ApiNotificationService {
  static const String _base = 'https://hrms-backend-zzzc.onrender.com/api';

  static Map<String, String> _headers(String authToken) => {
    'Authorization': 'Bearer $authToken',
    'Content-Type': 'application/json',
  };

  // ── Save FCM token ──────────────────────────────────────────────────────
  /// Saves FCM token to backend for both HRMS and external app notifications
  static Future<bool> saveToken({
    required String authToken,
    required String fcmToken,
    String device = 'android',
  }) async {
    try {
      print('💾 Saving FCM token (device: $device)...');
      final res = await http.post(
        Uri.parse('$_base/notifications/save-token'),
        headers: _headers(authToken),
        body: jsonEncode({'token': fcmToken, 'device': device}),
      );
      
      if (res.statusCode == 200) {
        print('✅ FCM token saved successfully');
        return true;
      } else {
        print('⚠️ Failed to save FCM token: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('❌ ApiNotificationService.saveToken error: $e');
      return false;
    }
  }

  // ── Remove FCM token ────────────────────────────────────────────────────
  static Future<bool> removeToken({
    required String authToken,
    required String fcmToken,
  }) async {
    try {
      final res = await http.delete(
        Uri.parse('$_base/notifications/remove-token'),
        headers: _headers(authToken),
        body: jsonEncode({'token': fcmToken}),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('ApiNotificationService.removeToken error: $e');
      return false;
    }
  }

  // ── Get notifications (paginated) ──────────────────────────────────────
  static Future<NotificationPage> getNotifications({
    required String authToken,
    required String userId,
    int page = 1,
    int limit = 30,
    String? type,
    bool? isRead,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (type != null && type.isNotEmpty) 'type': type,
      if (isRead != null) 'isRead': '$isRead',
    };

    final uri = Uri.parse(
      '$_base/notifications/$userId',
    ).replace(queryParameters: params);

    final res = await http.get(uri, headers: _headers(authToken));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final data = body['data'];
      final List<dynamic> rawList = data is List
          ? data
          : (body['notifications'] as List? ?? []);
      final rawPagination = body['pagination'] as Map<String, dynamic>? ?? {};

      return (
        items: rawList
            .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        pagination: NotificationPagination.fromJson(rawPagination),
      );
    } else {
      throw Exception(
        'Failed to fetch notifications: ${res.statusCode} ${res.body}',
      );
    }
  }

  // ── Get unread count ────────────────────────────────────────────────────
  static Future<int> getUnreadCount({
    required String authToken,
    required String userId,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/notifications/unread-count/$userId'),
        headers: _headers(authToken),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        return (data?['unreadCount'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  // ── Mark single notification as read ───────────────────────────────────
  static Future<bool> markAsRead({
    required String authToken,
    required String notificationId,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$_base/notifications/read/$notificationId'),
        headers: _headers(authToken),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('ApiNotificationService.markAsRead error: $e');
      return false;
    }
  }

  // ── Mark all notifications as read ─────────────────────────────────────
  static Future<bool> markAllAsRead({
    required String authToken,
    required String userId,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$_base/notifications/read-all/$userId'),
        headers: _headers(authToken),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('ApiNotificationService.markAllAsRead error: $e');
      return false;
    }
  }
}
