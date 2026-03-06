import 'dart:convert';
import 'package:http/http.dart' as http;

/// Admin API service — wraps all /api/admin/* endpoints.
/// All methods require a valid admin JWT token.
class AdminService {
  static const String _base = 'https://hrms-backend-zzzc.onrender.com/api';
  static const Duration _timeout = Duration(seconds: 30);

  static Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  // ── Dashboard ─────────────────────────────────────────────────────────────

  /// GET /api/admin/dashboard
  /// Returns stats, systemHealth, alerts.
  static Future<Map<String, dynamic>> getDashboardStats(String token) async {
    final res = await http
        .get(Uri.parse('$_base/admin/dashboard'), headers: _headers(token))
        .timeout(_timeout);
    return _decode(res);
  }

  /// GET /api/admin/activity?limit=<limit>
  /// Returns a list of recent leaves / tasks / expenses / attendance.
  static Future<Map<String, dynamic>> getRecentActivity(
    String token, {
    int limit = 20,
  }) async {
    final res = await http
        .get(
          Uri.parse('$_base/admin/activity?limit=$limit'),
          headers: _headers(token),
        )
        .timeout(_timeout);
    return _decode(res);
  }

  // ── Companies ─────────────────────────────────────────────────────────────

  /// GET /api/admin/companies
  static Future<Map<String, dynamic>> getAllCompanies(String token) async {
    final res = await http
        .get(Uri.parse('$_base/admin/companies'), headers: _headers(token))
        .timeout(_timeout);
    return _decode(res);
  }

  // ── HR Account Management ───────────────────────────────────────────────

  /// GET /api/admin/hr-accounts
  static Future<Map<String, dynamic>> getAllHR(String token) async {
    final res = await http
        .get(Uri.parse('$_base/admin/hr-accounts'), headers: _headers(token))
        .timeout(_timeout);
    return _decode(res);
  }

  /// GET /api/admin/hr/:id
  static Future<Map<String, dynamic>> getHRDetail(
    String token,
    String hrId,
  ) async {
    final res = await http
        .get(Uri.parse('$_base/admin/hr/$hrId'), headers: _headers(token))
        .timeout(_timeout);
    return _decode(res);
  }

  /// POST /api/admin/hr/:id/reset-password
  static Future<Map<String, dynamic>> resetHRPassword(
    String token,
    String hrId,
  ) async {
    final res = await http
        .post(
          Uri.parse('$_base/admin/hr/$hrId/reset-password'),
          headers: _headers(token),
          body: jsonEncode({}),
        )
        .timeout(_timeout);
    return _decode(res);
  }

  // ── Employee Management ──────────────────────────────────────────────────

  /// GET /api/admin/employees?company=&department=&status=
  static Future<Map<String, dynamic>> getAllEmployees(
    String token, {
    String? company,
    String? department,
    String? status,
  }) async {
    final params = <String, String>{};
    if (company != null && company.isNotEmpty) params['company'] = company;
    if (department != null && department.isNotEmpty) {
      params['department'] = department;
    }
    if (status != null && status.isNotEmpty) params['status'] = status;

    final uri = Uri.parse(
      '$_base/admin/employees',
    ).replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri, headers: _headers(token)).timeout(_timeout);
    return _decode(res);
  }

  // ── Leave Management ─────────────────────────────────────────────────────

  /// GET /api/admin/leaves?status=&company=
  static Future<Map<String, dynamic>> getAllLeaves(
    String token, {
    String? status,
    String? company,
  }) async {
    final params = <String, String>{};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (company != null && company.isNotEmpty) params['company'] = company;

    final uri = Uri.parse(
      '$_base/admin/leaves',
    ).replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri, headers: _headers(token)).timeout(_timeout);
    return _decode(res);
  }

  // ── Task Management ──────────────────────────────────────────────────────

  /// GET /api/admin/tasks?status=&company=
  static Future<Map<String, dynamic>> getAllTasks(
    String token, {
    String? status,
    String? company,
  }) async {
    final params = <String, String>{};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (company != null && company.isNotEmpty) params['company'] = company;

    final uri = Uri.parse(
      '$_base/admin/tasks',
    ).replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri, headers: _headers(token)).timeout(_timeout);
    return _decode(res);
  }

  // ── Helper ───────────────────────────────────────────────────────────────

  static Map<String, dynamic> _decode(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 401) {
        return {
          'success': false,
          'message': 'Unauthorized. Please log in again.',
        };
      }
      if (res.statusCode == 403) {
        return {
          'success': false,
          'message': 'Access denied. Admin role required.',
        };
      }
      if (res.statusCode >= 400) {
        return {
          'success': false,
          'message': body['message'] ?? 'Request failed (${res.statusCode})',
        };
      }
      return body;
    } catch (_) {
      return {
        'success': false,
        'message': 'Unexpected server response (${res.statusCode})',
      };
    }
  }
}
