import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hrms_app/core/config/api_config.dart';

/// Calendar API service — handles calendar events, holidays, and schedules
class CalendarService {
  static String get _base => ApiConfig.baseUrl;
  static const Duration _timeout = Duration(seconds: 30);

  static Map<String, String> _h(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  static Map<String, dynamic> _decode(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 401 || res.statusCode == 403) {
        return {'success': false, 'message': body['message'] ?? 'Unauthorized'};
      }
      if (res.statusCode >= 400) {
        return {
          'success': false,
          'message': body['message'] ?? 'Request failed (${res.statusCode})',
        };
      }
      return body;
    } catch (_) {
      return {
        'success': false,
        'message': 'Unexpected response (${res.statusCode})',
      };
    }
  }

  // ── Company Holidays ───────────────────────────────────────────────────────

  /// GET /api/company/holidays
  /// Fetch holidays for a company in a given month/year
  static Future<Map<String, dynamic>> getCompanyHolidays(
    String token,
    String companyId,
    int year,
    int month,
  ) async {
    try {
      final res = await http
          .get(
            Uri.parse(
              '$_base/company/$companyId/holidays?year=$year&month=$month',
            ),
            headers: _h(token),
          )
          .timeout(_timeout);
      return _decode(res);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch holidays: $e',
      };
    }
  }

  /// POST /api/company/holidays
  /// Create a new holiday
  static Future<Map<String, dynamic>> createHoliday(
    String token,
    String companyId,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/company/$companyId/holidays'),
            headers: _h(token),
            body: jsonEncode(data),
          )
          .timeout(_timeout);
      return _decode(res);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create holiday: $e',
      };
    }
  }

  /// DELETE /api/company/holidays/:id
  /// Delete a holiday
  static Future<Map<String, dynamic>> deleteHoliday(
    String token,
    String companyId,
    String holidayId,
  ) async {
    try {
      final res = await http
          .delete(
            Uri.parse('$_base/company/$companyId/holidays/$holidayId'),
            headers: _h(token),
          )
          .timeout(_timeout);
      return _decode(res);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete holiday: $e',
      };
    }
  }

  // ── Employee Schedules ─────────────────────────────────────────────────────

  /// GET /api/schedule/employee/:id
  /// Fetch employee schedule/events for a month
  static Future<Map<String, dynamic>> getEmployeeSchedule(
    String token,
    String employeeId,
    int year,
    int month,
  ) async {
    try {
      final res = await http
          .get(
            Uri.parse(
              '$_base/schedule/employee/$employeeId?year=$year&month=$month',
            ),
            headers: _h(token),
          )
          .timeout(_timeout);
      return _decode(res);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch schedule: $e',
      };
    }
  }

  /// GET /api/schedule/admin
  /// Fetch all employees' schedules for a month (admin only)
  static Future<Map<String, dynamic>> getAdminSchedule(
    String token,
    String companyId,
    int year,
    int month,
  ) async {
    try {
      final res = await http
          .get(
            Uri.parse(
              '$_base/schedule/admin?companyId=$companyId&year=$year&month=$month',
            ),
            headers: _h(token),
          )
          .timeout(_timeout);
      return _decode(res);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch admin schedule: $e',
      };
    }
  }

  // ── Events (Tasks, Leaves, Approvals) ──────────────────────────────────────

  /// GET /api/calendar/events
  /// Fetch all events (tasks, leaves, approvals) for a date range
  static Future<Map<String, dynamic>> getCalendarEvents(
    String token,
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final res = await http
          .get(
            Uri.parse(
              '$_base/calendar/events?userId=$userId&startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}',
            ),
            headers: _h(token),
          )
          .timeout(_timeout);
      return _decode(res);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch events: $e',
      };
    }
  }

  /// POST /api/calendar/events
  /// Create a new event
  static Future<Map<String, dynamic>> createEvent(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/calendar/events'),
            headers: _h(token),
            body: jsonEncode(data),
          )
          .timeout(_timeout);
      return _decode(res);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create event: $e',
      };
    }
  }

  /// PUT /api/calendar/events/:id
  /// Update an event
  static Future<Map<String, dynamic>> updateEvent(
    String token,
    String eventId,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await http
          .put(
            Uri.parse('$_base/calendar/events/$eventId'),
            headers: _h(token),
            body: jsonEncode(data),
          )
          .timeout(_timeout);
      return _decode(res);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update event: $e',
      };
    }
  }

  /// DELETE /api/calendar/events/:id
  /// Delete an event
  static Future<Map<String, dynamic>> deleteEvent(
    String token,
    String eventId,
  ) async {
    try {
      final res = await http
          .delete(
            Uri.parse('$_base/calendar/events/$eventId'),
            headers: _h(token),
          )
          .timeout(_timeout);
      return _decode(res);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete event: $e',
      };
    }
  }
}
