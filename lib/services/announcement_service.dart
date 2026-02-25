import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/announcement_model.dart';

class AnnouncementService {
  // Keep in sync with AttendanceService.baseUrl
  static const String baseUrl = 'https://hrms-backend-zzzc.onrender.com/api';

  // ── GET /api/announcements ─────────────────────────────────────────────────
  // Optional filters: priority ('low' | 'medium' | 'high'), department (String)
  static Future<AnnouncementResponse> getAnnouncements({
    required String token,
    String? priority,
    String? department,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (priority != null && priority.isNotEmpty) queryParams['priority'] = priority;
      if (department != null && department.isNotEmpty) queryParams['department'] = department;

      final uri = Uri.parse('$baseUrl/announcements')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      print('=== FETCH ANNOUNCEMENTS ===');
      print('URL: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Announcements request timed out'),
          );

      print('Status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return AnnouncementResponse.fromJson(jsonData);
      } else {
        try {
          final errorData = json.decode(response.body);
          throw Exception(
              errorData['message'] ?? 'Failed to fetch announcements (${response.statusCode})');
        } catch (_) {
          throw Exception(
              'Failed to fetch announcements: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Get announcements error: $e');
      rethrow;
    }
  }

  // ── GET /api/announcements/unread/count ────────────────────────────────────
  static Future<int> getUnreadCount({
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/announcements/unread/count');

      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception('Unread count timed out'),
          );

      print('Unread count status: ${response.statusCode}');
      print('Unread count body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return (jsonData['count'] as num).toInt();
        }
      }
      return 0;
    } catch (e) {
      print('Get unread count error: $e');
      return 0;
    }
  }

  // ── GET /api/announcements/:id ─────────────────────────────────────────────
  static Future<Announcement> getAnnouncementById({
    required String token,
    required String announcementId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/announcements/$announcementId');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Get announcement by id status: ${response.statusCode}');
      print('Get announcement by id body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return Announcement.fromJson(jsonData['data']);
        }
      }
      final errorData = json.decode(response.body);
      throw Exception(
          errorData['message'] ?? 'Failed to fetch announcement (${response.statusCode})');
    } catch (e) {
      print('Get announcement by id error: $e');
      rethrow;
    }
  }

  // ── PUT /api/announcements/:id/read ────────────────────────────────────────
  static Future<bool> markAsRead({
    required String token,
    required String announcementId,
  }) async {
    try {
      final uri =
          Uri.parse('$baseUrl/announcements/$announcementId/read');

      print('Marking announcement as read: $announcementId');

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Mark as read status: ${response.statusCode}');
      print('Mark as read body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Mark as read error: $e');
      return false;
    }
  }
}
