import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:hrms_app/core/config/api_config.dart';

class TaskManagementEmployee {
  final String id;
  final String name;
  final String email;
  final String employeeId;

  const TaskManagementEmployee({
    required this.id,
    required this.name,
    required this.email,
    required this.employeeId,
  });

  factory TaskManagementEmployee.fromJson(Map<String, dynamic> json) {
    return TaskManagementEmployee(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      employeeId: (json['employeeId'] ?? '').toString(),
    );
  }
}

class TaskManagementTaskItem {
  final String id;
  final String title;
  final String description;
  final String estimatedTime;
  final String status;
  final String section;

  const TaskManagementTaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.estimatedTime,
    required this.status,
    required this.section,
  });

  factory TaskManagementTaskItem.fromJson(Map<String, dynamic> json) {
    return TaskManagementTaskItem(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      estimatedTime: (json['estimatedTime'] ?? '').toString(),
      status: (json['status'] ?? 'Doing').toString(),
      section: (json['section'] ?? 'General').toString(),
    );
  }
}

class TaskManagementEntry {
  final String id;
  final String employeeName;
  final String employeeId;
  final String date;
  final String time;
  final String type;
  final List<TaskManagementTaskItem> tasks;
  final List<String> sections;

  const TaskManagementEntry({
    required this.id,
    required this.employeeName,
    required this.employeeId,
    required this.date,
    required this.time,
    required this.type,
    required this.tasks,
    required this.sections,
  });

  factory TaskManagementEntry.fromJson(Map<String, dynamic> json) {
    final tasks = ((json['tasks'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TaskManagementTaskItem.fromJson)
        .toList();

    final sections = ((json['sections'] as List?) ?? const ['General'])
        .map((e) => e.toString())
        .toList();

    return TaskManagementEntry(
      id: (json['_id'] ?? '').toString(),
      employeeName: (json['employeeName'] ?? '').toString(),
      employeeId:
          (json['employee'] is Map<String, dynamic>
                  ? json['employee']['_id']
                  : json['employee'])
              .toString(),
      date: (json['date'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      tasks: tasks,
      sections: sections,
    );
  }
}

class TaskManagementService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static List<Uri> _taskManagementUris(String suffix) {
    return [
      Uri.parse('$_baseUrl/hrms/task-management$suffix'),
      Uri.parse('$_baseUrl/task-management$suffix'),
    ];
  }

  static Map<String, String> _headers(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static String _parseError(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (body['message'] ?? 'Request failed').toString();
    } catch (_) {
      return 'Request failed (${response.statusCode})';
    }
  }

  static Future<List<TaskManagementEntry>> getEntries(
    String token, {
    int page = 1,
    int limit = 200,
    String? employeeId,
    String? date,
    String? type,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (employeeId != null && employeeId.isNotEmpty) {
      params['employeeId'] = employeeId;
    }
    if (date != null && date.isNotEmpty) {
      params['date'] = date;
    }
    if (type != null && type.isNotEmpty) {
      params['type'] = type;
    }

    http.Response? response;
    for (final baseUri in _taskManagementUris('')) {
      final uri = baseUri.replace(queryParameters: params);
      final res = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 404) {
        response = res;
        continue;
      }

      response = res;
      break;
    }

    if (response == null ||
        response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(_parseError(response ?? http.Response('', 500)));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body['data'] as List?) ?? const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(TaskManagementEntry.fromJson)
        .toList();
  }

  static Future<TaskManagementEntry> getEntryById(
    String token,
    String id,
  ) async {
    http.Response? response;
    for (final uri in _taskManagementUris('/$id')) {
      final res = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 404) {
        response = res;
        continue;
      }

      response = res;
      break;
    }

    if (response == null ||
        response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(_parseError(response ?? http.Response('', 500)));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return TaskManagementEntry.fromJson(body['data'] as Map<String, dynamic>);
  }

  static Future<List<TaskManagementEmployee>> getEmployees(String token) async {
    http.Response? response;
    for (final uri in _taskManagementUris('/employees')) {
      final res = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 404) {
        response = res;
        continue;
      }

      response = res;
      break;
    }

    if (response == null ||
        response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(_parseError(response ?? http.Response('', 500)));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body['data'] as List?) ?? const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(TaskManagementEmployee.fromJson)
        .toList();
  }

  static Future<void> createEntry(
    String token, {
    required String employeeId,
    required String date,
    required String time,
    required String type,
  }) async {
    final payload = jsonEncode({
      'employeeId': employeeId,
      'date': date,
      'time': time,
      'type': type,
      'tasks': const [],
      'sections': const ['General'],
    });

    http.Response? response;
    for (final uri in _taskManagementUris('')) {
      final res = await http
          .post(uri, headers: _headers(token), body: payload)
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 404) {
        response = res;
        continue;
      }

      response = res;
      break;
    }

    if (response == null ||
        response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(_parseError(response ?? http.Response('', 500)));
    }
  }

  static Future<bool> updateEntry(
    String token,
    String id, {
    List<TaskManagementTaskItem>? tasks,
    List<String>? sections,
  }) async {
    // Validate tasks before sending
    if (tasks != null) {
      for (int i = 0; i < tasks.length; i++) {
        final task = tasks[i];
        if (task.title.trim().isEmpty) {
          throw Exception('Task ${i + 1}: Title is required');
        }
      }
    }

    final payload = jsonEncode({
      if (tasks != null)
        'tasks': tasks
            .map(
              (t) => {
                // Only include _id for existing tasks (non-empty id)
                if (t.id.isNotEmpty) '_id': t.id,
                'title': t.title,
                'description': t.description,
                'estimatedTime': t.estimatedTime,
                'status': t.status,
                'section': t.section,
              },
            )
            .toList(),
      if (sections != null) 'sections': sections,
    });

    http.Response? response;
    for (final uri in _taskManagementUris('/$id')) {
      final res = await http
          .put(uri, headers: _headers(token), body: payload)
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 404) {
        response = res;
        continue;
      }

      response = res;
      break;
    }

    if (response == null ||
        response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(_parseError(response ?? http.Response('', 500)));
    }

    return true;
  }
}
