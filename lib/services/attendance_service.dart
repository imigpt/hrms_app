import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/attendance_checkin_model.dart';
import '../models/attendance_summary_model.dart';
import '../models/today_attendance_model.dart';
import '../models/attendance_history_model.dart' as history_model;
import '../models/attendance_records_model.dart';
import '../models/attendance_edit_request_model.dart';
import '../models/dashboard_stats_model.dart';

class AttendanceService {
  // Replace with your actual API base URL
  // static const String baseUrl = 'https://hrms-backend-807r.onrender.com/api';
  static const String baseUrl = 'https://hrms-backend-zzzc.onrender.com/api';
  
  // Check In
  static Future<CheckInResponse> checkIn({
    required String token,
    required File photoFile,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/attendance/check-in');
      
      print('=== CHECK-IN API REQUEST ===');
      print('URL: $uri');
      print('Latitude: $latitude');
      print('Longitude: $longitude');
      print('Photo file: ${photoFile.path}');
      
      var request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add photo file
      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          photoFile.path,
        ),
      );
      
      // Add location data as JSON string (as per API docs)
      final locationData = {
        'latitude': latitude,
        'longitude': longitude,
      };
      request.fields['location'] = json.encode(locationData);
      
      print('Request fields: ${request.fields}');
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('=== CHECK-IN API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        
        // Log the location from response
        if (jsonData['data'] != null && jsonData['data']['checkIn'] != null) {
          print('Response Check-In Location: ${jsonData['data']['checkIn']['location']}');
        }
        
        return CheckInResponse.fromJson(jsonData);
      } else {
        final errorBody = response.body;
        print('Check-in failed with status ${response.statusCode}');
        print('Response body: $errorBody');
        
        try {
          final errorData = json.decode(errorBody);
          throw Exception(errorData['message'] ?? 'Failed to check in');
        } catch (e) {
          throw Exception('Failed to check in: ${response.statusCode} - ${errorBody.substring(0, errorBody.length > 100 ? 100 : errorBody.length)}');
        }
      }
    } catch (e) {
      throw Exception('Check-in error: $e');
    }
  }
  
  // Check Out
  static Future<CheckInResponse> checkOut({
    required String token,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/attendance/check-out');
      
      print('\n📤 [CHECK-OUT] === API REQUEST ===');
      print('📍 [CHECK-OUT] URL: $uri');
      print('📍 [CHECK-OUT] Latitude: $latitude');
      print('📍 [CHECK-OUT] Longitude: $longitude');
      
      final requestBody = {
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
      };
      
      print('📨 [CHECK-OUT] Request body: ${json.encode(requestBody)}');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );
      
      print('\n📥 [CHECK-OUT] === API RESPONSE ===');
      print('📊 [CHECK-OUT] Status Code: ${response.statusCode}');
      print('📄 [CHECK-OUT] Response Body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonData = json.decode(response.body);
        
        // Log the location from response
        if (jsonData['data'] != null && jsonData['data']['checkOut'] != null) {
          var checkOutLocation = jsonData['data']['checkOut']['location'];
          print('📍 [CHECK-OUT] Server Response Location: $checkOutLocation');
          
          // ⚠️ WORKAROUND: If backend doesn't return location, inject it manually
          if (checkOutLocation == null) {
            print('⚠️ [CHECK-OUT] WARNING: Backend returned null location!');
            print('✅ [CHECK-OUT] Injecting location manually...');
            
            jsonData['data']['checkOut']['location'] = {
              'latitude': latitude,
              'longitude': longitude,
            };
            
            print('📍 [CHECK-OUT] Injected location: Lat=$latitude, Long=$longitude');
          }
        }
        
        return CheckInResponse.fromJson(jsonData);
      } else {
        final errorBody = response.body;
        
        String errorMessage = 'Failed to check out';
        try {
          final errorData = json.decode(errorBody);
          errorMessage = errorData['message'] ?? errorMessage;
          
          // If there's additional error info, include it
          if (errorData['error'] != null) {
            errorMessage += ': ${errorData['error']}';
          }
        } catch (e) {
          errorMessage = 'Failed to check out (${response.statusCode}): $errorBody';
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ [CHECK-OUT] Check-out exception: $e');
      throw Exception('Check-out error: $e');
    }
  }
  
  // Get Today's Attendance
  static Future<TodayAttendance?> getTodayAttendance({
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/attendance/today');
      
      print('📅 [TODAY\'S ATTENDANCE] Fetching: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('📅 [TODAY\'S ATTENDANCE] Status: ${response.statusCode}');
      print('📅 [TODAY\'S ATTENDANCE] Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final todayAttendance = TodayAttendance.fromJson(jsonData);
        
        print('✅ [TODAY\'S ATTENDANCE] Parsed successfully');
        print('   - Success: ${todayAttendance.success}');
        print('   - Has Check-in: ${todayAttendance.data?.hasCheckedIn}');
        print('   - Has Check-out: ${todayAttendance.data?.hasCheckedOut}');
        print('   - Status: ${todayAttendance.data?.status}');
        print('   - Work Hours: ${todayAttendance.data?.workHours}');
        
        return todayAttendance;
      } else if (response.statusCode == 404) {
        // No attendance record for today
        print('📅 [TODAY\'S ATTENDANCE] No record found (404)');
        return null;
      } else {
        final errorBody = response.body;
        print('❌ [TODAY\'S ATTENDANCE] Failed with status ${response.statusCode}');
        print('Response body: $errorBody');
        
        try {
          final errorData = json.decode(errorBody);
          throw Exception(errorData['message'] ?? 'Failed to get attendance');
        } catch (e) {
          throw Exception('Failed to get attendance: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ [TODAY\'S ATTENDANCE] Exception: $e');
      throw Exception('Get attendance error: $e');
    }
  }
  
  // Get Attendance Summary
  static Future<AttendanceSummary> getAttendanceSummary({
    required String token,
    required int month,
    required int year,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/attendance/summary?month=$month&year=$year');
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return AttendanceSummary.fromJson(jsonData);
      } else {
        final errorBody = response.body;
        print('Get attendance summary failed with status ${response.statusCode}');
        print('Response body: $errorBody');
        
        try {
          final errorData = json.decode(errorBody);
          throw Exception(errorData['message'] ?? 'Failed to get attendance summary');
        } catch (e) {
          throw Exception('Failed to get attendance summary: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Get attendance summary error: $e');
    }
  }
  
  // Get Attendance History for Calendar
  // Maps /api/attendance/my-attendance (date-ranged) → AttendanceHistory for calendar rendering
  static Future<history_model.AttendanceHistory> getAttendanceHistory({
    required String token,
    required int month,
    required int year,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0); // last day of the month

      final queryParams = {
        'startDate': DateFormat('yyyy-MM-dd').format(startDate),
        'endDate': DateFormat('yyyy-MM-dd').format(endDate),
        'month': month.toString(),
        'year': year.toString(),
      };

      final uri = Uri.parse('$baseUrl/attendance/my-attendance')
          .replace(queryParameters: queryParams);

      print('📅 [HISTORY] Fetching attendance history: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('📅 [HISTORY] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        // Parse as full AttendanceRecords and convert to lightweight AttendanceHistory
        final records = AttendanceRecords.fromJson(jsonData);

        final historyRecords = records.data
            .map((r) => history_model.AttendanceRecord(
                  id: r.id,
                  date: r.date,
                  status: r.status,
                  workHours: r.workHours,
                ))
            .toList();

        print('📅 [HISTORY] Converted ${historyRecords.length} records for calendar');
        return history_model.AttendanceHistory(
          success: records.success,
          data: historyRecords,
        );
      } else {
        final errorBody = response.body;
        print('❌ [HISTORY] Failed with status ${response.statusCode}');
        print('Response body: $errorBody');
        return history_model.AttendanceHistory(success: false, data: []);
      }
    } catch (e) {
      print('❌ [HISTORY] Error: $e');
      return history_model.AttendanceHistory(success: false, data: []);
    }
  }
  
  // Get Attendance Records with Filters
  static Future<AttendanceRecords> getAttendanceRecords({
    required String token,
    required String startDate,
    required String endDate,
    required int month,
    required int year,
    String? status,
  }) async {
    try {
      // Build query parameters
      final queryParams = {
        'startDate': startDate,
        'endDate': endDate,
        'month': month.toString(),
        'year': year.toString(),
      };
      
      // Add status filter if provided
      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
        queryParams['status'] = status.toLowerCase();
      }
      
      final uri = Uri.parse('$baseUrl/attendance/my-attendance')
          .replace(queryParameters: queryParams);
      
      print('Fetching attendance records:');
      print('URL: $uri');
      print('Status filter: ${status ?? "All"}');
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final records = AttendanceRecords.fromJson(jsonData);
        print('Parsed ${records.count} records successfully');
        return records;
      } else {
        final errorBody = response.body;
        print('Get attendance records failed with status ${response.statusCode}');
        print('Response body: $errorBody');
        
        // Return empty records on error
        return AttendanceRecords(success: false, count: 0, data: []);
      }
    } catch (e) {
      print('Get attendance records error: $e');
      print('Error stack trace: ${StackTrace.current}');
      // Return empty records on exception
      return AttendanceRecords(success: false, count: 0, data: []);
    }
  }

  // Submit Attendance Edit Request
  static Future<AttendanceEditRequest> submitEditRequest({
    required String token,
    required String attendanceId,
    required String requestedCheckIn,
    required String requestedCheckOut,
    required String reason,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/attendance/edit-request');
      
      final requestBody = {
        'attendanceId': attendanceId,
        'requestedCheckIn': requestedCheckIn,
        'requestedCheckOut': requestedCheckOut,
        'reason': reason,
      };
      
      print('📤 [EDIT REQUEST] URL: $uri');
      print('📤 [EDIT REQUEST] Body: ${json.encode(requestBody)}');
      
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return AttendanceEditRequest.fromJson(jsonData);
      } else {
        final errorBody = json.decode(response.body);
        final message = errorBody['message'] ?? 'Failed to submit edit request';
        throw Exception(message);
      }
    } catch (e) {
      print('Submit edit request error: $e');
      throw Exception('Failed to submit edit request: $e');
    }
  }

  // Get My Attendance Edit Requests
  static Future<AttendanceEditRequestsList> getEditRequests({
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/attendance/edit-requests');
      print('📋 [EDIT REQUESTS] Fetching: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📋 [EDIT REQUESTS] Status: ${response.statusCode}');
      print('📋 [EDIT REQUESTS] Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return AttendanceEditRequestsList.fromJson(jsonData);
      } else {
        final errorBody = json.decode(response.body);
        final message = errorBody['message'] ?? 'Failed to fetch edit requests';
        throw Exception(message);
      }
    } catch (e) {
      print('❌ [EDIT REQUESTS] Error: $e');
      throw Exception('Failed to fetch edit requests: $e');
    }
  }

  // Get Dashboard Stats
  static Future<DashboardStatsResponse?> getDashboardStats({
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/employees/dashboard');
      
      print('Fetching dashboard stats:');
      print('URL: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return dashboardStatsResponseFromJson(response.body);
      } else {
        print('Get dashboard stats failed with status ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Get dashboard stats error: $e');
      print('Error stack trace: ${StackTrace.current}');
      return null;
    }
  }
}
