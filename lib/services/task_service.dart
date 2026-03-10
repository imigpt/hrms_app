// lib/services/task_service.dart
// Task Management Service
// Handles all task-related API calls (CRUD, attachments, progress tracking)

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class TaskService {
  static String get baseUrl => ApiConfig.baseUrl;

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
    String? startDate,
    int? estimatedTime,
    String? projectId,
    List<String>? tags,
  }) async {
    try {
      final body = <String, dynamic>{
        'title': title,
        'description': description,
        'priority': priority,
        'dueDate': dueDate,
        'assignedTo': assignedTo,
        if (startDate != null) 'startDate': startDate,
        if (estimatedTime != null) 'estimatedTime': estimatedTime,
        if (projectId != null) 'projectId': projectId,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
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
    String? startDate,
    int? estimatedTime,
    List<String>? tags,
    String? status,
  }) async {
    try {
      final body = <String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (priority != null) 'priority': priority,
        if (dueDate != null) 'dueDate': dueDate,
        if (startDate != null) 'startDate': startDate,
        if (estimatedTime != null) 'estimatedTime': estimatedTime,
        if (tags != null) 'tags': tags,
        if (status != null) 'status': status,
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

  // ─── PROJECTS ──────────────────────────────────────────────────────────────

  static Future<dynamic> getProjects(String token) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/tasks/projects'), headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to fetch projects: $e');
    }
  }

  static Future<dynamic> createProject(
    String token, {
    required String name,
    String? description,
    String priority = 'medium',
    String? startDate,
    String? endDate,
    String color = '#3b82f6',
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
        'priority': priority,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        'color': color,
      };
      final response = await http
          .post(Uri.parse('$baseUrl/tasks/projects'),
              headers: _getHeaders(token), body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  static Future<void> deleteProject(String token, String projectId) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/tasks/projects/$projectId'),
              headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));
      if (!(response.statusCode >= 200 && response.statusCode < 300)) {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to delete project: $e');
    }
  }

  // ─── MILESTONES ─────────────────────────────────────────────────────────────

  static Future<dynamic> getMilestones(String token, String projectId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/tasks/milestones/project/$projectId'),
              headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to fetch milestones: $e');
    }
  }

  static Future<dynamic> createMilestone(
    String token, {
    required String title,
    String? description,
    required String projectId,
    String? dueDate,
  }) async {
    try {
      final body = <String, dynamic>{
        'title': title,
        if (description != null && description.isNotEmpty) 'description': description,
        'project': projectId,
        if (dueDate != null) 'dueDate': dueDate,
      };
      final response = await http
          .post(Uri.parse('$baseUrl/tasks/milestones'),
              headers: _getHeaders(token), body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to create milestone: $e');
    }
  }

  static Future<void> deleteMilestone(String token, String milestoneId) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/tasks/milestones/$milestoneId'),
              headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));
      if (!(response.statusCode >= 200 && response.statusCode < 300)) {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to delete milestone: $e');
    }
  }

  // ─── TIME TRACKING ──────────────────────────────────────────────────────────

  static Future<dynamic> getRunningTimer(String token) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/tasks/timer/running'),
              headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'data': null};
      }
    } catch (_) {
      return {'success': false, 'data': null};
    }
  }

  static Future<dynamic> startTimer(String token, String taskId) async {
    try {
      final body = {'task': taskId};
      final response = await http
          .post(Uri.parse('$baseUrl/tasks/timer/start'),
              headers: _getHeaders(token), body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to start timer: $e');
    }
  }

  static Future<dynamic> stopTimer(String token, String logId) async {
    try {
      final response = await http
          .put(Uri.parse('$baseUrl/tasks/timer/stop/$logId'),
              headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to stop timer: $e');
    }
  }

  static Future<dynamic> getTimeLogs(
    String token, {
    int limit = 10,
    String? taskId,
  }) async {
    try {
      final params = <String, String>{'limit': limit.toString()};
      if (taskId != null) params['task'] = taskId;
      final uri = Uri.parse('$baseUrl/tasks/timelog')
          .replace(queryParameters: params);
      final response = await http
          .get(uri, headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to fetch time logs: $e');
    }
  }

  static Future<dynamic> logTime(
    String token, {
    required String taskId,
    required int durationMinutes,
    String? description,
    String? date,
  }) async {
    try {
      final body = <String, dynamic>{
        'task': taskId,
        'duration': durationMinutes,
        if (description != null && description.isNotEmpty) 'description': description,
        if (date != null) 'date': date,
      };
      final response = await http
          .post(Uri.parse('$baseUrl/tasks/timelog'),
              headers: _getHeaders(token), body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to log time: $e');
    }
  }

  // ─── COMMENTS ──────────────────────────────────────────────────────────────

  /// Add a comment to a task
  /// POST /api/tasks/:id/comments
  static Future<dynamic> addComment(
    String token,
    String taskId, {
    required String content,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/tasks/$taskId/comments'),
            headers: _getHeaders(token),
            body: jsonEncode({'content': content}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Delete a comment from a task
  /// DELETE /api/tasks/:id/comments/:commentId
  static Future<void> deleteComment(
    String token,
    String taskId,
    String commentId,
  ) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/tasks/$taskId/comments/$commentId'),
            headers: _getHeaders(token),
          )
          .timeout(const Duration(seconds: 15));
      if (!(response.statusCode >= 200 && response.statusCode < 300)) {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  /// Transition a task's workflow status
  /// POST /api/tasks/:id/transition
  static Future<dynamic> transitionTask(
    String token,
    String taskId, {
    required String action,
    String? comment,
  }) async {
    try {
      final body = <String, dynamic>{
        'action': action,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      };
      final response = await http
          .post(
            Uri.parse('$baseUrl/tasks/$taskId/transition'),
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
      throw Exception('Failed to transition task: $e');
    }
  }

  // ─── ANALYTICS ──────────────────────────────────────────────────────────────

  static Future<dynamic> getProductivityAnalytics(String token) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/tasks/analytics/productivity'),
              headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to fetch productivity analytics: $e');
    }
  }

  static Future<dynamic> getWorkloadDistribution(String token) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/tasks/analytics/workload'),
              headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to fetch workload distribution: $e');
    }
  }
}
