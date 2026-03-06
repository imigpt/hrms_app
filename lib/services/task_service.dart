// lib/services/task_service.dart
// Task Management Service
// Handles all task-related API calls (CRUD, attachments, progress tracking)

import 'dart:convert';
import 'package:http/http.dart' as http;

class TaskService {
  static const String baseUrl = 'https://hrms-backend-zzzc.onrender.com/api';

  // ─── Helper Methods ────────────────────────────────────────────────────────

  static Map<String, String> _getHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  static String _parseError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return body['message'] ?? 'Error: ${response.statusCode}';
    } catch (_) {
      return 'Error: ${response.statusCode}';
    }
  }

  // ─── GET ENDPOINTS ─────────────────────────────────────────────────────────

  /// Get all tasks with optional filtering
  /// [status] - Filter by task status (pending, in-progress, completed)
  /// [assignedTo] - Filter by assigned user ID
  /// [sortBy] - Sort by field (createdAt, dueDate, priority)
  /// [page] - Pagination page number
  static Future<dynamic> getTasks(
    String token, {
    String? status,
    String? assignedTo,
    String? sortBy,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'status': ?status,
        'assignedTo': ?assignedTo,
        'sortBy': ?sortBy,
      };

      final uri = Uri.parse('$baseUrl/tasks').replace(queryParameters: params);
      final response = await http
          .get(uri, headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  /// Get single task by ID
  static Future<dynamic> getTaskById(String token, String taskId) async {
    try {
      final uri = Uri.parse('$baseUrl/tasks/$taskId');
      final response = await http
          .get(uri, headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to fetch task: $e');
    }
  }

  /// Get task statistics (count by status)
  static Future<dynamic> getTaskStatistics(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/tasks/statistics');
      final response = await http
          .get(uri, headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to fetch task statistics: $e');
    }
  }

  // ─── POST ENDPOINTS ────────────────────────────────────────────────────────

  /// Create a new task (Managers/Team Leads only)
  /// [title] - Task title
  /// [description] - Task description
  /// [priority] - Priority level (low, medium, high, critical)
  /// [dueDate] - Due date (ISO format: 2024-12-31)
  /// [assignedTo] - Employee ID to assign task to
  /// [projectId] - Optional project ID
  /// [tags] - Optional list of tags
  static Future<dynamic> createTask(
    String token, {
    required String title,
    required String description,
    required String priority,
    required String dueDate,
    required String assignedTo,
    String? projectId,
    List<String>? tags,
  }) async {
    try {
      final body = {
        'title': title,
        'description': description,
        'priority': priority,
        'dueDate': dueDate,
        'assignedTo': assignedTo,
        'projectId': ?projectId,
        'tags': ?tags,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/tasks'),
            headers: _getHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  // ─── PUT ENDPOINTS ─────────────────────────────────────────────────────────

  /// Update task details
  /// Can update: title, description, priority, dueDate, status
  static Future<dynamic> updateTask(
    String token,
    String taskId, {
    String? title,
    String? description,
    String? priority,
    String? dueDate,
    String? status,
  }) async {
    try {
      final body = <String, dynamic>{
        'title': ?title,
        'description': ?description,
        'priority': ?priority,
        'dueDate': ?dueDate,
        'status': ?status,
      };

      if (body.isEmpty) {
        throw Exception('No fields to update');
      }

      final response = await http
          .put(
            Uri.parse('$baseUrl/tasks/$taskId'),
            headers: _getHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  /// Update task progress/status
  /// [status] - pending, in-progress, completed, cancelled
  /// [progress] - Progress from 0 to 100
  static Future<dynamic> updateTaskProgress(
    String token,
    String taskId, {
    String? status,
    int? completionPercentage,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        'status': ?status,
        'progress': ?completionPercentage, // API expects 'progress'
        'notes': ?notes,
      };

      final response = await http
          .put(
            Uri.parse('$baseUrl/tasks/$taskId/progress'),
            headers: _getHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to update task progress: $e');
    }
  }

  /// Update sub-task status
  static Future<dynamic> updateSubTask(
    String token,
    String taskId,
    String subTaskId, {
    required String status,
  }) async {
    try {
      final body = {'status': status};

      final response = await http
          .put(
            Uri.parse('$baseUrl/tasks/$taskId/subtasks/$subTaskId'),
            headers: _getHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to update sub-task: $e');
    }
  }

  // ─── FILE UPLOAD ───────────────────────────────────────────────────────────

  /// Add attachment to task
  /// [filePath] - Path to file to upload
  /// [fileName] - Name of file
  /// [fileType] - MIME type (application/pdf, image/jpeg, etc.)
  static Future<dynamic> addAttachment(
    String token,
    String taskId, {
    required String filePath,
    required String fileName,
    required String fileType,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/tasks/$taskId/attachments');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          filename: fileName,
          contentType: null,
        ),
      );

      final response = await request.send().timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = await response.stream.bytesToString();
        return jsonDecode(body);
      } else {
        final body = await response.stream.bytesToString();
        throw Exception(_parseError(http.Response(body, response.statusCode)));
      }
    } catch (e) {
      throw Exception('Failed to add attachment: $e');
    }
  }

  // ─── DELETE ENDPOINTS ──────────────────────────────────────────────────────

  /// Delete attachment from task
  /// DELETE /api/tasks/:taskId/attachments/:attachmentId
  static Future<void> deleteAttachment(
    String token,
    String taskId,
    String attachmentId,
  ) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/tasks/$taskId/attachments/$attachmentId'),
            headers: _getHeaders(token),
          )
          .timeout(const Duration(seconds: 15));

      if (!(response.statusCode >= 200 && response.statusCode < 300)) {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to delete attachment: $e');
    }
  }

  /// Delete task (Managers/Task creators only)
  static Future<void> deleteTask(String token, String taskId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/tasks/$taskId'),
            headers: _getHeaders(token),
          )
          .timeout(const Duration(seconds: 15));

      if (!(response.statusCode >= 200 && response.statusCode < 300)) {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  // ─── CONVENIENCE METHODS ───────────────────────────────────────────────────

  /// Get all tasks assigned to current user
  static Future<dynamic> getMyTasks(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/employees/tasks'),
            headers: _getHeaders(token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to fetch my tasks: $e');
    }
  }

  /// Update task status directly (convenience method)
  /// [status] - one of: pending, in-progress, completed, cancelled
  static Future<dynamic> updateTaskStatus(
    String token,
    String taskId,
    String status,
  ) async {
    return updateTask(token, taskId, status: status);
  }

  /// Mark task as complete (convenience method)
  static Future<dynamic> completeTask(String token, String taskId) async {
    return updateTaskProgress(
      token,
      taskId,
      status: 'completed',
      completionPercentage: 100,
    );
  }

  /// Cancel task (convenience method)
  static Future<dynamic> cancelTask(
    String token,
    String taskId, {
    String? reason,
  }) async {
    return updateTaskProgress(
      token,
      taskId,
      status: 'cancelled',
      notes: reason,
    );
  }

  /// Add or update review on a task (Admin/HR only)
  /// PUT /api/tasks/:id/review
  /// [comment] - Review comment text
  /// [rating]  - Rating from 1 to 5
  static Future<dynamic> addReview(
    String token,
    String taskId, {
    required String comment,
    required int rating,
  }) async {
    try {
      final body = {'comment': comment, 'rating': rating};
      final response = await http
          .put(
            Uri.parse('$baseUrl/tasks/$taskId/review'),
            headers: _getHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }
}
