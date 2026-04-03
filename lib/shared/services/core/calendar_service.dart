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

  // ── Company Holidays (as Calendar Events with eventType='holiday') ────────

  /// GET /api/calendar?eventType=holiday&startDate=...&endDate=...
  /// Fetch holidays for a company in a given date range
  static Future<Map<String, dynamic>> getCompanyHolidays(
    String token,
    String companyId,
    int year,
    int month,
  ) async {
    try {
      // Get first and last day of the month
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0); // Last day of month
      
      final url = '$_base/calendar'
          '?eventType=holiday'
          '&startDate=${startDate.toIso8601String()}'
          '&endDate=${endDate.toIso8601String()}';
      
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
      
      // Log response body for debugging
      if (res.statusCode >= 400) {
        print('[CALENDAR API] ❌ API Error - Status: ${res.statusCode}');
        print('[CALENDAR API] Response body: ${res.body.substring(0, 500)}');
      }
      
      final result = _decode(res);
      if (result['success'] != false) {
        final holidayCount = result['data']?.length ?? 0;
        print('[CALENDAR API] ✅ Holidays fetched successfully: $holidayCount holidays found');
        // Log sample holiday for debugging
        if (result['data'] is List && (result['data'] as List).isNotEmpty) {
          final firstHoliday = (result['data'] as List)[0];
          print('[CALENDAR API] Sample holiday: title=${firstHoliday['title']}, eventType=${firstHoliday['eventType']}');
        }
      } else {
        print('[CALENDAR API] ❌ API returned error: ${result['message']}');
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
      print('[CALENDAR API ERROR] Stack trace: ${StackTrace.current}');
      return {
        'success': false,
        'message': 'Failed to fetch holidays: $e',
      };
    }
  }

  /// POST /api/calendar
  /// Create a new holiday as a calendar event with eventType='holiday'
  static Future<Map<String, dynamic>> createHoliday(
    String token,
    String companyId,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = '$_base/calendar';
      final payload = {
        ...data,
        'eventType': 'holiday', // Ensure it's marked as holiday
      };
      
      print('[CALENDAR API] POST Create Holiday - CompanyId: $companyId');
      print('[CALENDAR API] Request data: ${jsonEncode(payload)}');
      
      final startTime = DateTime.now();
      final res = await http
          .post(
            Uri.parse(url),
            headers: _h(token),
            body: jsonEncode(payload),
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

  /// DELETE /api/calendar/:id
  /// Delete a holiday (which is a calendar event)
  static Future<Map<String, dynamic>> deleteHoliday(
    String token,
    String companyId,
    String holidayId,
  ) async {
    try {
      final url = '$_base/calendar/$holidayId';
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

  // ── Calendar Events ────────────────────────────────────────────────────────

  /// GET /api/calendar?startDate=...&endDate=...
  /// Fetch all calendar events for a date range (excludes holidays)
  static Future<Map<String, dynamic>> getCalendarEvents(
    String token,
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Fetch events while excluding holidays
      final url = '$_base/calendar'
          '?startDate=${startDate.toIso8601String()}'
          '&endDate=${endDate.toIso8601String()}';
      
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
      
      // Log response body for debugging
      if (res.statusCode >= 400) {
        print('[CALENDAR API] ❌ API Error - Status: ${res.statusCode}');
        print('[CALENDAR API] Response body: ${res.body.substring(0, 500)}');
      }
      
      final result = _decode(res);
      if (result['success'] != false) {
        final eventCount = result['data']?.length ?? 0;
        print('[CALENDAR API] ✅ Calendar events fetched successfully: $eventCount events found');
        // Log sample event for debugging
        if (result['data'] is List && (result['data'] as List).isNotEmpty) {
          final firstEvent = (result['data'] as List)[0];
          print('[CALENDAR API] Sample event: id=${firstEvent['_id'] ?? firstEvent['id']}, title=${firstEvent['title']}, eventType=${firstEvent['eventType']}');
        }
      } else {
        print('[CALENDAR API] ❌ API returned error: ${result['message']}');
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
      print('[CALENDAR API ERROR] Stack trace: ${StackTrace.current}');
      return {
        'success': false,
        'message': 'Failed to fetch events: $e',
      };
    }
  }

  /// POST /api/calendar
  /// Create a new calendar event
  static Future<Map<String, dynamic>> createEvent(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = '$_base/calendar';
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
        print('[CALENDAR API] ✅ Event created successfully - EventId: ${result['data']?['_id'] ?? result['data']?['id'] ?? 'unknown'}');
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

  /// PUT /api/calendar/:id
  /// Update a calendar event
  static Future<Map<String, dynamic>> updateEvent(
    String token,
    String eventId,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = '$_base/calendar/$eventId';
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

  /// DELETE /api/calendar/:id
  /// Delete a calendar event
  static Future<Map<String, dynamic>> deleteEvent(
    String token,
    String eventId,
  ) async {
    try {
      final url = '$_base/calendar/$eventId';
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

  /// GET /api/calendar/aggregated?startDate=...&endDate=...&sources=events,tasks,followups
  /// Get aggregated calendar (events, tasks, lead follow-ups)
  static Future<Map<String, dynamic>> getAggregatedCalendar(
    String token,
    DateTime startDate,
    DateTime endDate, {
    List<String> sources = const ['events', 'tasks', 'followups'],
  }) async {
    try {
      final sourceParam = sources.join(',');
      final url = '$_base/calendar/aggregated'
          '?startDate=${startDate.toIso8601String()}'
          '&endDate=${endDate.toIso8601String()}'
          '&sources=$sourceParam';
      
      print('[CALENDAR API] GET Aggregated Calendar');
      print('[CALENDAR API] Date range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
      print('[CALENDAR API] Sources: $sourceParam');
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
        print('[CALENDAR API] ✅ Aggregated calendar fetched successfully: ${result['data']?.length ?? 0} items found');
      }
      return result;
    } on TimeoutException {
      print('[CALENDAR API ERROR] Request timeout (${_timeout.inSeconds}s) - getAggregatedCalendar');
      return {
        'success': false,
        'message': 'Request timeout while fetching aggregated calendar',
      };
    } catch (e) {
      print('[CALENDAR API ERROR] Exception in getAggregatedCalendar: $e');
      return {
        'success': false,
        'message': 'Failed to fetch aggregated calendar: $e',
      };
    }
  }
}
