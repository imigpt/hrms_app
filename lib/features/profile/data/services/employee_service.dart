// lib/services/employee_service.dart
// Covers all 10 /api/employees/* endpoints

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:hrms_app/core/config/api_config.dart';
import 'package:hrms_app/features/profile/data/models/employee_model.dart';
import 'package:hrms_app/features/dashboard/data/models/dashboard_stats_model.dart';

class EmployeeService {
  static String get _baseUrl => ApiConfig.baseUrl;

  // ── Shared header builder ─────────────────────────────────────────────────
  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ── Shared error extractor ────────────────────────────────────────────────
  static String _extractError(http.Response response, String fallback) {
    try {
      final body = json.decode(response.body);
      return (body['message'] ?? body['error'] ?? fallback).toString();
    } catch (_) {
      return 'Server error (${response.statusCode})';
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 1. GET /api/employees/dashboard
  // ──────────────────────────────────────────────────────────────────────────
  static Future<DashboardStatsResponse> getDashboard({
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/employees/dashboard');
      print('EmployeeService.getDashboard: $uri');

      final response = await http.get(uri, headers: _headers(token));
      print('  status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return dashboardStatsResponseFromJson(response.body);
      }
      throw Exception(_extractError(response, 'Failed to load dashboard'));
    } catch (e) {
      print('getDashboard error: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2. GET /api/employees/profile
  // ──────────────────────────────────────────────────────────────────────────
  static Future<EmployeeProfileResponse> getProfile({
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/employees/profile');
      print('EmployeeService.getProfile: $uri');

      final response = await http.get(uri, headers: _headers(token));
      print('  status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return employeeProfileResponseFromJson(response.body);
      }
      throw Exception(_extractError(response, 'Failed to load profile'));
    } catch (e) {
      print('getProfile error: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. PUT /api/employees/profile  (multipart — phone, address, dateOfBirth, photo)
  // ──────────────────────────────────────────────────────────────────────────
  static Future<EmployeeProfileResponse> updateProfile({
    required String token,
    String? phone,
    String? address,
    String? dateOfBirth,
    File? profilePhoto,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/employees/profile');
      print('EmployeeService.updateProfile: $uri');

      final request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';

      if (phone != null) request.fields['phone'] = phone;
      if (address != null) request.fields['address'] = address;
      if (dateOfBirth != null) request.fields['dateOfBirth'] = dateOfBirth;

      if (profilePhoto != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profilePhoto',
            profilePhoto.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      print('  status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return employeeProfileResponseFromJson(response.body);
      }
      throw Exception(_extractError(response, 'Failed to update profile'));
    } catch (e) {
      print('updateProfile error: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. PUT /api/employees/change-password
  // ──────────────────────────────────────────────────────────────────────────
  static Future<ChangePasswordResponse> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/employees/change-password');
      print('EmployeeService.changePassword: $uri');

      final response = await http.put(
        uri,
        headers: _headers(token),
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
      print('  status: ${response.statusCode}');

      final body = json.decode(response.body);
      return ChangePasswordResponse(
        success: body['success'] ?? false,
        message: (body['message'] ?? 'Unexpected response').toString(),
      );
    } catch (e) {
      print('changePassword error: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 5. GET /api/employees/tasks
  // ──────────────────────────────────────────────────────────────────────────
  static Future<EmployeeTasksResponse> getMyTasks({
    required String token,
    String? status,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/employees/tasks',
      ).replace(queryParameters: status != null ? {'status': status} : null);
      print('EmployeeService.getMyTasks: $uri');

      final response = await http.get(uri, headers: _headers(token));
      print('  status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return employeeTasksResponseFromJson(response.body);
      }
      throw Exception(_extractError(response, 'Failed to load tasks'));
    } catch (e) {
      print('getMyTasks error: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 6. GET /api/employees/leaves
  // ──────────────────────────────────────────────────────────────────────────
  static Future<EmployeeLeavesResponse> getMyLeaves({
    required String token,
    String? status,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/employees/leaves',
      ).replace(queryParameters: status != null ? {'status': status} : null);
      print('EmployeeService.getMyLeaves: $uri');

      final response = await http.get(uri, headers: _headers(token));
      print('  status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return employeeLeavesResponseFromJson(response.body);
      }
      throw Exception(_extractError(response, 'Failed to load leaves'));
    } catch (e) {
      print('getMyLeaves error: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 7. GET /api/employees/expenses
  // ──────────────────────────────────────────────────────────────────────────
  static Future<EmployeeExpensesResponse> getMyExpenses({
    required String token,
    String? status,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/employees/expenses',
      ).replace(queryParameters: status != null ? {'status': status} : null);
      print('EmployeeService.getMyExpenses: $uri');

      final response = await http.get(uri, headers: _headers(token));
      print('  status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return employeeExpensesResponseFromJson(response.body);
      }
      throw Exception(_extractError(response, 'Failed to load expenses'));
    } catch (e) {
      print('getMyExpenses error: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 8. GET /api/employees/attendance
  // ──────────────────────────────────────────────────────────────────────────
  static Future<EmployeeAttendanceResponse> getMyAttendance({
    required String token,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final uri = Uri.parse(
        '$_baseUrl/employees/attendance',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      print('EmployeeService.getMyAttendance: $uri');

      final response = await http.get(uri, headers: _headers(token));
      print('  status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return employeeAttendanceResponseFromJson(response.body);
      }
      throw Exception(_extractError(response, 'Failed to load attendance'));
    } catch (e) {
      print('getMyAttendance error: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 9. GET /api/employees/leave-balance
  // ──────────────────────────────────────────────────────────────────────────
  static Future<EmployeeLeaveBalanceResponse> getLeaveBalance({
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/employees/leave-balance');
      print('EmployeeService.getLeaveBalance: $uri');

      final response = await http.get(uri, headers: _headers(token));
      print('  status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return EmployeeLeaveBalanceResponse.fromJson(body);
      }
      throw Exception(_extractError(response, 'Failed to load leave balance'));
    } catch (e) {
      print('getLeaveBalance error: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 10. GET /api/employees/team
  // ──────────────────────────────────────────────────────────────────────────
  static Future<EmployeeTeamResponse> getTeamMembers({
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/employees/team');
      print('EmployeeService.getTeamMembers: $uri');

      final response = await http.get(uri, headers: _headers(token));
      print('  status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return employeeTeamResponseFromJson(response.body);
      }
      throw Exception(_extractError(response, 'Failed to load team'));
    } catch (e) {
      print('getTeamMembers error: $e');
      rethrow;
    }
  }
}
