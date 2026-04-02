import 'dart:convert';
import 'dart:async';
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
        print('[CALENDAR API ERROR] Status ${res.statusCode}: Unauthorized - ${body['message']}');
        return {'success': false, 'message': body['message'] ?? 'Unauthorized'};
      }
      if (res.statusCode >= 400) {
        print('[CALENDAR API ERROR] Status ${res.statusCode}: ${body['message']}');
        return {
          'success': false,
          'message': body['message'] ?? 'Request failed (${res.statusCode})',
        };
      }
      print('[CALENDAR API] Response status: ${res.statusCode}');
      return body;
    } catch (e) {
      print('[CALENDAR API ERROR] Failed to decode response: $e');
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
      final url = '$_base/company/$companyId/holidays?year=$year&month=$month';
      print('[CALENDAR API] GET Company Holidays - CompanyId: $companyId, Month: $month/$year');
      print('[CALENDAR API] Request URL: $url');
      
      final startTime = DateTime.now();
      final res = await http
          .get(
            Uri.parse(url),
            headers: _h(token),
          )
          .timeout(_timeout);
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      
      print('[CALENDAR API] Response received in ${duration}ms - Status: ${res.statusCode}');
      final result = _decode(res);
      if (result['success'] != false) {
        print('[CALENDAR API] ✅ Holidays fetched successfully: ${result['data']?.length ?? 0} holidays found');
      }
      return result;
    } on TimeoutException {
      print('[CALENDAR API ERROR] Request timeout (${_timeout.inSeconds}s) - getCompanyHolidays');
      return {
        'success': false,
        'message': 'Request timeout while fetching holidays',
      };
    } catch (e) {
      print('[CALENDAR API ERROR] Exception in getCompanyHolidays: $e');
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
      final url = '$_base/company/$companyId/holidays';
      print('[CALENDAR API] POST Create Holiday - CompanyId: $companyId');
      print('[CALENDAR API] Request data: ${jsonEncode(data)}');
      
      final startTime = DateTime.now();
      final res = await http
          .post(
            Uri.parse(url),
            headers: _h(token),
            body: jsonEncode(data),
          )
          .timeout(_timeout);
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      
      print('[CALENDAR API] Response received in ${duration}ms - Status: ${res.statusCode}');
      final result = _decode(res);
      if (result['success'] != false) {
        print('[CALENDAR API] ✅ Holiday created successfully');
      }
      return result;
    } on TimeoutException {
      print('[CALENDAR API ERROR] Request timeout (${_timeout.inSeconds}s) - createHoliday');
      return {
        'success': false,
        'message': 'Request timeout while creating holiday',
      };
    } catch (e) {
      print('[CALENDAR API ERROR] Exception in createHoliday: $e');
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
      final url = '$_base/company/$companyId/holidays/$holidayId';
      print('[CALENDAR API] DELETE Holiday - CompanyId: $companyId, HolidayId: $holidayId');
      
      final startTime = DateTime.now();
      final res = await http
          .delete(
            Uri.parse(url),
            headers: _h(token),
          )
          .timeout(_timeout);
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      
      print('[CALENDAR API] Response received in ${duration}ms - Status: ${res.statusCode}');
      final result = _decode(res);
      if (result['success'] != false) {
        print('[CALENDAR API] ✅ Holiday deleted successfully');
      }
      return result;
    } on TimeoutException {
      print('[CALENDAR API ERROR] Request timeout (${_timeout.inSeconds}s) - deleteHoliday');
      return {
        'success': false,
        'message': 'Request timeout while deleting holiday',
      };
    } catch (e) {
      print('[CALENDAR API ERROR] Exception in deleteHoliday: $e');
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
      final url = '$_base/schedule/employee/$employeeId?year=$year&month=$month';
      print('[CALENDAR API] GET Employee Schedule - EmployeeId: $employeeId, Month: $month/$year');
      print('[CALENDAR API] Request URL: $url');
      
      final startTime = DateTime.now();
      final res = await http
          .get(
            Uri.parse(url),
            headers: _h(token),
          )
          .timeout(_timeout);
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      
      print('[CALENDAR API] Response received in ${duration}ms - Status: ${res.statusCode}');
      final result = _decode(res);
      if (result['success'] != false) {
        print('[CALENDAR API] ✅ Employee schedule fetched successfully');
      }
      return result;
    } on TimeoutException {
      print('[CALENDAR API ERROR] Request timeout (${_timeout.inSeconds}s) - getEmployeeSchedule');
      return {
        'success': false,
        'message': 'Request timeout while fetching employee schedule',
      };
    } catch (e) {
      print('[CALENDAR API ERROR] Exception in getEmployeeSchedule: $e');
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
      final url = '$_base/schedule/admin?companyId=$companyId&year=$year&month=$month';
      print('[CALENDAR API] GET Admin Schedule - CompanyId: $companyId, Month: $month/$year');
      print('[CALENDAR API] Request URL: $url');
      
      final startTime = DateTime.now();
      final res = await http
          .get(
            Uri.parse(url),
            headers: _h(token),
          )
          .timeout(_timeout);
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      
      print('[CALENDAR API] Response received in ${duration}ms - Status: ${res.statusCode}');
      final result = _decode(res);
      if (result['success'] != false) {
        print('[CALENDAR API] ✅ Admin schedule fetched successfully');
      }
      return result;
    } on TimeoutException {
      print('[CALENDAR API ERROR] Request timeout (${_timeout.inSeconds}s) - getAdminSchedule');
      return {
        'success': false,
        'message': 'Request timeout while fetching admin schedule',
      };
    } catch (e) {
      print('[CALENDAR API ERROR] Exception in getAdminSchedule: $e');
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
      final url = '$_base/calendar/events?userId=$userId&startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}';
      print('[CALENDAR API] GET Calendar Events - UserId: $userId');
      print('[CALENDAR API] Date range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
      print('[CALENDAR API] Request URL: $url');
      
      final startTime = DateTime.now();
      final res = await http
          .get(
            Uri.parse(url),
            headers: _h(token),
          )
          .timeout(_timeout);
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      
      print('[CALENDAR API] Response received in ${duration}ms - Status: ${res.statusCode}');
      final result = _decode(res);
      if (result['success'] != false) {
        print('[CALENDAR API] ✅ Calendar events fetched successfully: ${result['data']?.length ?? 0} events found');
      }
      return result;
    } on TimeoutException {
      print('[CALENDAR API ERROR] Request timeout (${_timeout.inSeconds}s) - getCalendarEvents');
      return {
        'success': false,
        'message': 'Request timeout while fetching calendar events',
      };
    } catch (e) {
      print('[CALENDAR API ERROR] Exception in getCalendarEvents: $e');
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
      final url = '$_base/calendar/events';
      print('[CALENDAR API] POST Create Event');
      print('[CALENDAR API] Request data: ${jsonEncode(data)}');
      
      final startTime = DateTime.now();
      final res = await http
          .post(
            Uri.parse(url),
            headers: _h(token),
            body: jsonEncode(data),
          )
          .timeout(_timeout);
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      
      print('[CALENDAR API] Response received in ${duration}ms - Status: ${res.statusCode}');
      final result = _decode(res);
      if (result['success'] != false) {
        print('[CALENDAR API] ✅ Event created successfully - EventId: ${result['data']?['id'] ?? 'unknown'}');
      }
      return result;
    } on TimeoutException {
      print('[CALENDAR API ERROR] Request timeout (${_timeout.inSeconds}s) - createEvent');
      return {
        'success': false,
        'message': 'Request timeout while creating event',
      };
    } catch (e) {
      print('[CALENDAR API ERROR] Exception in createEvent: $e');
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
      final url = '$_base/calendar/events/$eventId';
      print('[CALENDAR API] PUT Update Event - EventId: $eventId');
      print('[CALENDAR API] Request data: ${jsonEncode(data)}');
      
      final startTime = DateTime.now();
      final res = await http
          .put(
            Uri.parse(url),
            headers: _h(token),
            body: jsonEncode(data),
          )
          .timeout(_timeout);
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      
      print('[CALENDAR API] Response received in ${duration}ms - Status: ${res.statusCode}');
      final result = _decode(res);
      if (result['success'] != false) {
        print('[CALENDAR API] ✅ Event updated successfully');
      }
      return result;
    } on TimeoutException {
      print('[CALENDAR API ERROR] Request timeout (${_timeout.inSeconds}s) - updateEvent');
      return {
        'success': false,
        'message': 'Request timeout while updating event',
      };
    } catch (e) {
      print('[CALENDAR API ERROR] Exception in updateEvent: $e');
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
      final url = '$_base/calendar/events/$eventId';
      print('[CALENDAR API] DELETE Event - EventId: $eventId');
      
      final startTime = DateTime.now();
      final res = await http
          .delete(
            Uri.parse(url),
            headers: _h(token),
          )
          .timeout(_timeout);
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      
      print('[CALENDAR API] Response received in ${duration}ms - Status: ${res.statusCode}');
      final result = _decode(res);
      if (result['success'] != false) {
        print('[CALENDAR API] ✅ Event deleted successfully');
      }
      return result;
    } on TimeoutException {
      print('[CALENDAR API ERROR] Request timeout (${_timeout.inSeconds}s) - deleteEvent');
      return {
        'success': false,
        'message': 'Request timeout while deleting event',
      };
    } catch (e) {
      print('[CALENDAR API ERROR] Exception in deleteEvent: $e');
      return {
        'success': false,
        'message': 'Failed to delete event: $e',
      };
    }
  }
}
