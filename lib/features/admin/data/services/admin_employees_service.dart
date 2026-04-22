// lib/services/admin_employees_service.dart
// Admin endpoint: GET /api/admin/employees

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hrms_app/core/config/api_config.dart';

class AdminEmployeesService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// GET /api/admin/employees or /api/hr/employees based on role
  /// Admin → /api/admin/employees (all employees across companies)
  /// HR → /api/hr/employees (employees in their company)
  /// Optional filters: company (ID), department (string), status (active|inactive|on-leave)
  static Future<Map<String, dynamic>> getAllEmployees(
    String token, {
    String role = 'admin',
    String? company,
    String? department,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (company != null && company.isNotEmpty) {
        queryParams['company'] = company;
      }
      if (department != null && department.isNotEmpty) {
        queryParams['department'] = department;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      // Use role-based endpoint selection
      final endpoint = (role.toLowerCase() == 'admin')
          ? '/admin/employees'
          : '/hr/employees';

      final uri = Uri.parse('$_baseUrl$endpoint')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      debugPrint('📋 AdminEmployeesService.getAllEmployees: Role=$role, Endpoint=$endpoint');

      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 30));

      debugPrint('  Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        final count = (result['data'] as List?)?.length ?? 0;
        debugPrint('  ✅ Loaded $count employees');
        return result;
      } else if (response.statusCode == 401) {
        debugPrint('  ❌ 401 Unauthorized - Invalid or expired token');
        throw Exception('Unauthorized: Invalid or expired token');
      } else if (response.statusCode == 403) {
        debugPrint('  ❌ 403 Forbidden - ${response.body}');
        final body = jsonDecode(response.body);
        throw Exception(
          body['message'] ??
              'Access denied: Your role ($role) is not authorized for this endpoint',
        );
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
    String? salary,
    String? salaryType,
    String? status,
    String? company,
    String role = 'admin',
    File? profilePhoto,
  }) async {
    try {
      final endpoint = (role.toLowerCase() == 'admin') ? '/admin/employees' : '/hr/employees';
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl$endpoint'),
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
      if (salary != null && salary.isNotEmpty)
        request.fields['salary'] = salary;
      if (salaryType != null && salaryType.isNotEmpty)
        request.fields['salaryType'] = salaryType;
      if (status != null && status.isNotEmpty)
        request.fields['status'] = status;
      if (company != null && company.isNotEmpty)
        request.fields['company'] = company;

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
    String? company,
    String role = 'admin',
    File? profilePhoto,
  }) async {
    try {
      final endpoint = (role.toLowerCase() == 'admin') ? '/admin/employees' : '/hr/employees';
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$_baseUrl$endpoint/$employeeId'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields (only if provided to avoid overwriting with null)
      if (name != null && name.isNotEmpty) {
        request.fields['name'] = name;
      }
      if (email != null && email.isNotEmpty) {
        request.fields['email'] = email;
      }
      if (phone != null && phone.isNotEmpty) {
        request.fields['phone'] = phone;
      }
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
        request.fields['dateOfBirth'] = dateOfBirth;
      }
      if (address != null && address.isNotEmpty) {
        request.fields['address'] = address;
      }
      if (department != null && department.isNotEmpty) {
        request.fields['department'] = department;
      }
      if (position != null && position.isNotEmpty) {
        request.fields['position'] = position;
      }
      if (joinDate != null && joinDate.isNotEmpty) {
        request.fields['joinDate'] = joinDate;
      }
      if (status != null && status.isNotEmpty) {
        request.fields['status'] = status;
      }
      if (company != null && company.isNotEmpty) {
        request.fields['company'] = company;
      }

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
  /// Uses /api/attendance endpoint with date range filters and filters by userId on client side
  static Future<List<dynamic>> getEmployeeAttendance(
    String token,
    String userId, {
    String? startDate,
    String? endDate,
    int limit = 100,
  }) async {
    try {
      final params = <String, String>{};
      if (startDate != null) params['startDate'] = startDate;
      if (endDate != null) params['endDate'] = endDate;
      
      final uri = Uri.parse(
        '$_baseUrl/attendance',
      ).replace(queryParameters: params.isNotEmpty ? params : null);
      
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> allRecords = [];
        
        if (data is Map && data['data'] is List) {
          allRecords = data['data'] as List;
        } else if (data is Map && data['records'] is List) {
          allRecords = data['records'] as List;
        } else if (data is List) {
          allRecords = data;
        }
        
        // Filter records by userId since each record contains user info
        final filtered = allRecords.where((record) {
          if (record is Map && record['user'] is Map) {
            final user = record['user'] as Map;
            return user['_id'] == userId || user['id'] == userId;
          }
          return false;
        }).toList();
        
        // Transform records to ensure proper field names for display
        final transformed = filtered.map((record) {
          if (record is Map) {
            return {
              ...record,
              // Ensure date field exists
              'date': record['date'] ?? record['createdAt'] ?? DateTime.now().toIso8601String(),
              // Normalize check-in/check-out format
              'checkIn': record['checkIn'] ?? record['checkin'] ?? {},
              'checkOut': record['checkOut'] ?? record['checkout'] ?? {},
              // Normalize work hours field
              'workHours': record['workHours'] ?? record['hoursWorked'] ?? record['hours_worked'] ?? 0,
              // Ensure status field exists
              'status': record['status'] ?? 'unmarked',
              // Notes/remarks field
              'notes': record['notes'] ?? record['remarks'] ?? '',
            };
          }
          return record;
        }).toList();
        
        return transformed;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Token expired or invalid');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden - You don\'t have permission to view this data');
      } else if (response.statusCode == 404) {
        throw Exception('Employee not found');
      } else {
        // Better error handling for HTML responses
        if (response.body.contains('<!DOCTYPE') || response.body.contains('<html')) {
          throw Exception('Server error - Please contact support');
        }
        try {
          final body = jsonDecode(response.body);
          throw Exception(body['message'] ?? 'Failed to fetch attendance (HTTP ${response.statusCode})');
        } catch (e) {
          throw Exception('Failed to fetch attendance (HTTP ${response.statusCode})');
        }
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

  /// PUT /api/tasks/:id
  /// Update task details (title, description, priority, status, progress, dueDate, etc.)
  static Future<Map<String, dynamic>> updateTask(
    String token,
    String taskId, {
    String? title,
    String? description,
    String? priority,
    String? status,
    double? progress,
    String? dueDate,
    String? startDate,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null && title.isNotEmpty) body['title'] = title;
      if (description != null && description.isNotEmpty)
        body['description'] = description;
      if (priority != null && priority.isNotEmpty) body['priority'] = priority;
      if (status != null && status.isNotEmpty) body['status'] = status;
      if (progress != null) body['progress'] = progress.clamp(0, 100);
      if (dueDate != null && dueDate.isNotEmpty) body['dueDate'] = dueDate;
      if (startDate != null && startDate.isNotEmpty) body['startDate'] = startDate;

      final response = await http
          .put(
            Uri.parse('$_baseUrl/tasks/$taskId'),
            headers: _headers(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else if (response.statusCode == 404) {
        throw Exception('Task not found');
      } else {
        final respBody = jsonDecode(response.body);
        throw Exception(respBody['message'] ?? 'Failed to update task');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error updating task: $e');
    }
  }

  /// DELETE /api/tasks/:id
  /// Delete a task
  static Future<void> deleteTask(String token, String taskId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/tasks/$taskId'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else if (response.statusCode == 404) {
        throw Exception('Task not found');
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Failed to delete task');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error deleting task: $e');
    }
  }

  /// GET /api/tasks/:id/comments
  /// Fetch comments for a task
  static Future<List<dynamic>> getTaskComments(
    String token,
    String taskId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/tasks/$taskId/comments'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['data'] is List) return data['data'] as List;
        if (data is List) return data;
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        return [];
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error fetching comments: $e');
    }
  }

  /// POST /api/tasks/:id/comments
  /// Add a comment to a task
  static Future<Map<String, dynamic>> addTaskComment(
    String token,
    String taskId,
    String text,
  ) async {
    try {
      final body = <String, dynamic>{'text': text};
      final response = await http
          .post(
            Uri.parse('$_baseUrl/tasks/$taskId/comments'),
            headers: _headers(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        final respBody = jsonDecode(response.body);
        throw Exception(respBody['message'] ?? 'Failed to add comment');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error adding comment: $e');
    }
  }

  /// GET /api/tasks/:id/history
  /// Fetch change history for a task
  static Future<List<dynamic>> getTaskHistory(
    String token,
    String taskId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/tasks/$taskId/history'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['data'] is List) return data['data'] as List;
        if (data is List) return data;
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        return [];
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error fetching history: $e');
    }
  }

  /// PUT /api/tasks/:id/status
  /// Update only the task status (for workflow transitions)
  static Future<Map<String, dynamic>> updateTaskStatus(
    String token,
    String taskId,
    String newStatus, {
    String? comment,
  }) async {
    try {
      final body = <String, dynamic>{'status': newStatus};
      if (comment != null && comment.isNotEmpty) body['comment'] = comment;

      final response = await http
          .put(
            Uri.parse('$_baseUrl/tasks/$taskId/status'),
            headers: _headers(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        final respBody = jsonDecode(response.body);
        throw Exception(respBody['message'] ?? 'Failed to update status');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error updating status: $e');
    }
  }
}
