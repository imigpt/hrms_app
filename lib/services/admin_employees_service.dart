// lib/services/admin_employees_service.dart
// Admin endpoint: GET /api/admin/employees

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AdminEmployeesService {
  static const String _baseUrl = 'https://hrms-backend-zzzc.onrender.com/api';

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// GET /api/admin/employees
  /// Optional filters: company (ID), department (string), status (active|inactive|on-leave)
  static Future<Map<String, dynamic>> getAllEmployees(
    String token, {
    String? company,
    String? department,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (company != null && company.isNotEmpty)
        queryParams['company'] = company;
      if (department != null && department.isNotEmpty)
        queryParams['department'] = department;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final uri = Uri.parse(
        '$_baseUrl/admin/employees',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else {
        final body = jsonDecode(response.body);
        throw Exception(
          body['message'] ??
              'Failed to fetch employees (${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error fetching employees: $e');
    }
  }

  /// POST /api/hr/employees
  /// Create a new employee (multipart form-data with optional profilePhoto)
  /// Note: Company is auto-assigned from logged-in user's company
  static Future<Map<String, dynamic>> addEmployee({
    required String token,
    required String name,
    required String employeeId,
    required String password,
    required String email,
    String? phone,
    String? dateOfBirth,
    String? address,
    String? department,
    String? position,
    String? joinDate,
    String? status,
    File? profilePhoto,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/hr/employees'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      request.fields['name'] = name;
      request.fields['employeeId'] = employeeId;
      request.fields['password'] = password;
      request.fields['email'] = email;
      if (phone != null && phone.isNotEmpty) request.fields['phone'] = phone;
      if (dateOfBirth != null && dateOfBirth.isNotEmpty)
        request.fields['dateOfBirth'] = dateOfBirth;
      if (address != null && address.isNotEmpty)
        request.fields['address'] = address;
      if (department != null && department.isNotEmpty)
        request.fields['department'] = department;
      if (position != null && position.isNotEmpty)
        request.fields['position'] = position;
      if (joinDate != null && joinDate.isNotEmpty)
        request.fields['joinDate'] = joinDate;
      if (status != null && status.isNotEmpty)
        request.fields['status'] = status;

      // Add profile photo if available
      if (profilePhoto != null) {
        request.files.add(
          http.MultipartFile(
            'profilePhoto',
            profilePhoto.readAsBytes().asStream(),
            profilePhoto.lengthSync(),
            filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      }

      final response = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        final body = jsonDecode(responseBody);
        throw Exception(body['message'] ?? 'Invalid employee data');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else {
        final body = jsonDecode(responseBody);
        throw Exception(
          body['message'] ?? 'Failed to add employee (${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error adding employee: $e');
    }
  }

  /// PUT /api/hr/employees/:id
  /// Update employee profile (multipart form-data with optional profilePhoto)
  /// Can update: name, email, phone, employeeId, department, position, status, dateOfBirth, joinDate, address, profilePhoto
  static Future<Map<String, dynamic>> updateEmployee({
    required String token,
    required String employeeId,
    String? name,
    String? email,
    String? phone,
    String? dateOfBirth,
    String? address,
    String? department,
    String? position,
    String? joinDate,
    String? status,
    File? profilePhoto,
  }) async {
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$_baseUrl/hr/employees/$employeeId'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields (only if provided to avoid overwriting with null)
      if (name != null && name.isNotEmpty) request.fields['name'] = name;
      if (email != null && email.isNotEmpty) request.fields['email'] = email;
      if (phone != null && phone.isNotEmpty) request.fields['phone'] = phone;
      if (dateOfBirth != null && dateOfBirth.isNotEmpty)
        request.fields['dateOfBirth'] = dateOfBirth;
      if (address != null && address.isNotEmpty)
        request.fields['address'] = address;
      if (department != null && department.isNotEmpty)
        request.fields['department'] = department;
      if (position != null && position.isNotEmpty)
        request.fields['position'] = position;
      if (joinDate != null && joinDate.isNotEmpty)
        request.fields['joinDate'] = joinDate;
      if (status != null && status.isNotEmpty)
        request.fields['status'] = status;

      // Add profile photo if available
      if (profilePhoto != null) {
        request.files.add(
          http.MultipartFile(
            'profilePhoto',
            profilePhoto.readAsBytes().asStream(),
            profilePhoto.lengthSync(),
            filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      }

      final response = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        final body = jsonDecode(responseBody);
        throw Exception(body['message'] ?? 'Invalid employee data');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else if (response.statusCode == 404) {
        throw Exception('Employee not found');
      } else {
        final body = jsonDecode(responseBody);
        throw Exception(
          body['message'] ??
              'Failed to update employee (${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error updating employee: $e');
    }
  }

  /// Fetch attendance records for a specific employee (admin view)
  static Future<List<dynamic>> getEmployeeAttendance(
    String token,
    String userId, {
    int limit = 30,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/attendance/records',
      ).replace(queryParameters: {'userId': userId, 'limit': limit.toString()});
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['data'] is List) return data['data'] as List;
        if (data is Map && data['records'] is List)
          return data['records'] as List;
        if (data is List) return data;
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Failed to fetch attendance');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error fetching attendance: $e');
    }
  }

  /// GET /api/tasks/all?assignedTo=:userId
  /// Fetch tasks assigned to a specific employee (admin view)
  static Future<List<dynamic>> getEmployeeTasks(
    String token,
    String userId,
  ) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/tasks/all',
      ).replace(queryParameters: {'assignedTo': userId});
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['data'] is List) return data['data'] as List;
        if (data is List) return data;
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Failed to fetch tasks');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error fetching tasks: $e');
    }
  }
}
