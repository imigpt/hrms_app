// lib/services/workflow_service.dart
// Workflow Management Service
// Handles all workflow-related API calls (templates, task assignment, steps)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hrms_app/core/config/api_config.dart';

class WorkflowService {
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

  /// Get all workflow templates
  static Future<dynamic> getTemplates(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/workflow-templates');
      print('[WorkflowService] GET $uri');
      
      final response = await http
          .get(uri, headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));

      print('[WorkflowService] Response status: ${response.statusCode}');
      print('[WorkflowService] Response body: ${response.body}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final parsed = jsonDecode(response.body);
        print('[WorkflowService] Parsed response: $parsed');
        return parsed;
      } else {
        final error = _parseError(response);
        print('[WorkflowService] Error: $error');
        throw Exception(error);
      }
    } catch (e) {
      print('[WorkflowService] Exception: $e');
      throw Exception('Failed to fetch workflow templates: $e');
    }
  }

  /// Get a single workflow template by ID
  static Future<dynamic> getTemplateById(String token, String templateId) async {
    try {
      final uri = Uri.parse('$baseUrl/workflow-templates/$templateId');
      final response = await http
          .get(uri, headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to fetch workflow template: $e');
    }
  }

  /// Get workflow details for a specific task
  static Future<dynamic> getTaskWorkflow(String token, String taskId) async {
    try {
      // Note: Backend doesn't have a GET endpoint for task workflow
      // This would need to be implemented or we fetch from task details
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
      throw Exception('Failed to fetch task workflow: $e');
    }
  }

  // ─── POST ENDPOINTS ────────────────────────────────────────────────────────

  /// Create a new workflow template
  /// [name] - Workflow template name
  /// [description] - Optional workflow description
  static Future<dynamic> createTemplate(
    String token, {
    required String name,
    String? description,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/workflow-templates'),
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
      throw Exception('Failed to create workflow template: $e');
    }
  }

  /// Assign a workflow template to a task
  /// [templateId] - The workflow template ID to assign
  /// [workflowName] - The name of the workflow (for reference)
  static Future<dynamic> assignToTask(
    String token,
    String taskId, {
    required String templateId,
    String? workflowName,
  }) async {
    try {
      final body = {
        'templateId': templateId,
        if (workflowName != null) 'workflowName': workflowName,
      };

      final response = await http
          .put(
            Uri.parse('$baseUrl/workflow-templates/task/$taskId/assign'),
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
      throw Exception('Failed to assign workflow: $e');
    }
  }

  /// Complete a workflow step
  /// [stepIndex] - The index of the step to complete
  /// [comment] - Optional comment/notes for the step
  static Future<dynamic> completeStep(
    String token,
    String taskId, {
    required int stepIndex,
    String? comment,
  }) async {
    try {
      final body = {
        'stepIndex': stepIndex,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      };

      final response = await http
          .put(
            Uri.parse('$baseUrl/workflow-templates/task/$taskId/step/$stepIndex/complete'),
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
      throw Exception('Failed to complete workflow step: $e');
    }
  }

  // ─── PUT ENDPOINTS (Update) ───────────────────────────────────────────────

  /// Update an existing workflow template
  /// [templateId] - The ID of the template to update
  /// [name] - Updated workflow name
  /// [description] - Updated description
  /// [isShared] - Whether the template should be shared with team
  /// [steps] - List of workflow steps
  static Future<dynamic> updateTemplate(
    String token,
    String templateId, {
    required String name,
    String? description,
    bool? isShared,
    List<Map<String, dynamic>>? steps,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        if (description != null) 'description': description,
        if (isShared != null) 'isShared': isShared,
        if (steps != null) 'steps': steps,
      };

      final response = await http
          .put(
            Uri.parse('$baseUrl/workflow-templates/$templateId'),
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
      throw Exception('Failed to update workflow template: $e');
    }
  }

  /// Duplicate a workflow template
  /// [templateId] - The ID of the template to duplicate
  static Future<dynamic> duplicateTemplate(String token, String templateId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/workflow-templates/$templateId/duplicate'),
            headers: _getHeaders(token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to duplicate workflow template: $e');
    }
  }

  // ─── DELETE ENDPOINTS ──────────────────────────────────────────────────────

  /// Delete a workflow template
  /// [templateId] - The ID of the template to delete
  static Future<dynamic> deleteTemplate(String token, String templateId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/workflow-templates/$templateId'),
            headers: _getHeaders(token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to delete workflow template: $e');
    }
  }

  /// Remove workflow from a task
  static Future<dynamic> removeFromTask(String token, String taskId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/workflow-templates/task/$taskId/workflow'),
            headers: _getHeaders(token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Failed to remove workflow: $e');
    }
  }
}
