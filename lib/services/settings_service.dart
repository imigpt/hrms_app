import 'dart:convert';
import 'package:http/http.dart' as http;

/// Settings API service — wraps all /api/settings/* and related endpoints.
/// All methods require a valid admin JWT token.
class SettingsService {
  static const String _base = 'https://hrms-backend-zzzc.onrender.com/api';
  static const Duration _timeout = Duration(seconds: 30);

  static Map<String, String> _h(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  static Map<String, dynamic> _decode(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 401 || res.statusCode == 403) {
        return {'success': false, 'message': body['message'] ?? 'Unauthorized'};
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
        'message': 'Unexpected response (${res.statusCode})',
      };
    }
  }

  // ── Company Settings ───────────────────────────────────────────────────────

  /// GET /api/settings/company
  static Future<Map<String, dynamic>> getCompanySettings(String token) async {
    final res = await http
        .get(Uri.parse('$_base/settings/company'), headers: _h(token))
        .timeout(_timeout);
    return _decode(res);
  }

  /// PUT /api/settings/company
  static Future<Map<String, dynamic>> updateCompanySettings(
    String token,
    Map<String, dynamic> data,
  ) async {
    final res = await http
        .put(
          Uri.parse('$_base/settings/company'),
          headers: _h(token),
          body: jsonEncode(data),
        )
        .timeout(_timeout);
    return _decode(res);
  }

  // ── User Credentials ───────────────────────────────────────────────────────

  /// GET /api/auth/user-credentials?search=&role=&page=&limit=
  static Future<Map<String, dynamic>> getUserCredentials(
    String token, {
    String? search,
    String? role,
    int page = 1,
    int limit = 15,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (search != null && search.isNotEmpty) 'search': search,
      if (role != null && role.isNotEmpty) 'role': role,
    };
    final uri = Uri.parse(
      '$_base/auth/user-credentials',
    ).replace(queryParameters: params);
    final res = await http.get(uri, headers: _h(token)).timeout(_timeout);
    return _decode(res);
  }

  /// GET /api/auth/generate-password
  static Future<Map<String, dynamic>> generatePassword(String token) async {
    final res = await http
        .get(Uri.parse('$_base/auth/generate-password'), headers: _h(token))
        .timeout(_timeout);
    return _decode(res);
  }

  /// PUT /api/auth/admin-reset-password/:userId
  static Future<Map<String, dynamic>> adminResetUserPassword(
    String token,
    String userId,
    String newPassword,
  ) async {
    final res = await http
        .put(
          Uri.parse('$_base/auth/admin-reset-password/$userId'),
          headers: _h(token),
          body: jsonEncode({'newPassword': newPassword}),
        )
        .timeout(_timeout);
    return _decode(res);
  }

  // ── Localization / Translations ────────────────────────────────────────────

  /// GET /api/settings/localization
  static Future<Map<String, dynamic>> getLocalizationSettings(
    String token,
  ) async {
    final res = await http
        .get(Uri.parse('$_base/settings/localization'), headers: _h(token))
        .timeout(_timeout);
    return _decode(res);
  }

  /// PUT /api/settings/localization
  static Future<Map<String, dynamic>> updateLocalizationSettings(
    String token,
    Map<String, dynamic> data,
  ) async {
    final res = await http
        .put(
          Uri.parse('$_base/settings/localization'),
          headers: _h(token),
          body: jsonEncode(data),
        )
        .timeout(_timeout);
    return _decode(res);
  }

  // ── Roles & Permissions ────────────────────────────────────────────────────

  /// GET /api/settings/roles
  static Future<Map<String, dynamic>> getRoles(String token) async {
    final res = await http
        .get(Uri.parse('$_base/settings/roles'), headers: _h(token))
        .timeout(_timeout);
    return _decode(res);
  }

  /// GET /api/settings/roles/:id/permissions
  static Future<Map<String, dynamic>> getRolePermissions(
    String token,
    String roleId,
  ) async {
    final res = await http
        .get(
          Uri.parse('$_base/settings/roles/$roleId/permissions'),
          headers: _h(token),
        )
        .timeout(_timeout);
    return _decode(res);
  }

  /// GET /api/settings/modules
  static Future<Map<String, dynamic>> getPermissionModules(String token) async {
    final res = await http
        .get(Uri.parse('$_base/settings/modules'), headers: _h(token))
        .timeout(_timeout);
    return _decode(res);
  }

  // ── Work Status ────────────────────────────────────────────────────────────

  /// GET /api/settings/work-status
  static Future<Map<String, dynamic>> getWorkStatusSettings(
    String token,
  ) async {
    final res = await http
        .get(Uri.parse('$_base/settings/work-status'), headers: _h(token))
        .timeout(_timeout);
    return _decode(res);
  }

  /// PUT /api/settings/work-status
  static Future<Map<String, dynamic>> updateWorkStatusSettings(
    String token,
    List<String> statuses,
  ) async {
    final res = await http
        .put(
          Uri.parse('$_base/settings/work-status'),
          headers: _h(token),
          body: jsonEncode({'statuses': statuses}),
        )
        .timeout(_timeout);
    return _decode(res);
  }

  // ── HRM Settings ───────────────────────────────────────────────────────────

  /// GET /api/settings/hrm
  static Future<Map<String, dynamic>> getHRMSettings(String token) async {
    final res = await http
        .get(Uri.parse('$_base/settings/hrm'), headers: _h(token))
        .timeout(_timeout);
    return _decode(res);
  }

  /// PUT /api/settings/hrm
  static Future<Map<String, dynamic>> updateHRMSettings(
    String token,
    Map<String, dynamic> data,
  ) async {
    final res = await http
        .put(
          Uri.parse('$_base/settings/hrm'),
          headers: _h(token),
          body: jsonEncode(data),
        )
        .timeout(_timeout);
    return _decode(res);
  }

  // ── Payroll Settings ───────────────────────────────────────────────────────

  /// GET /api/settings/payroll
  static Future<Map<String, dynamic>> getPayrollSettings(String token) async {
    final res = await http
        .get(Uri.parse('$_base/settings/payroll'), headers: _h(token))
        .timeout(_timeout);
    return _decode(res);
  }

  /// PUT /api/settings/payroll
  static Future<Map<String, dynamic>> updatePayrollSettings(
    String token,
    Map<String, dynamic> data,
  ) async {
    final res = await http
        .put(
          Uri.parse('$_base/settings/payroll'),
          headers: _h(token),
          body: jsonEncode(data),
        )
        .timeout(_timeout);
    return _decode(res);
  }

  // ── Employee ID Config ─────────────────────────────────────────────────────

  /// GET /api/settings/employee-id
  static Future<Map<String, dynamic>> getEmployeeIDConfig(String token) async {
    final res = await http
        .get(Uri.parse('$_base/settings/employee-id'), headers: _h(token))
        .timeout(_timeout);
    return _decode(res);
  }

  /// PUT /api/settings/employee-id
  static Future<Map<String, dynamic>> updateEmployeeIDConfig(
    String token,
    Map<String, dynamic> data,
  ) async {
    final res = await http
        .put(
          Uri.parse('$_base/settings/employee-id'),
          headers: _h(token),
          body: jsonEncode(data),
        )
        .timeout(_timeout);
    return _decode(res);
  }

  // ── Email Settings ─────────────────────────────────────────────────────────

  /// GET /api/settings/email
  static Future<Map<String, dynamic>> getEmailSettings(String token) async {
    final res = await http
        .get(Uri.parse('$_base/settings/email'), headers: _h(token))
        .timeout(_timeout);
    return _decode(res);
  }

  /// PUT /api/settings/email
  static Future<Map<String, dynamic>> updateEmailSettings(
    String token,
    Map<String, dynamic> data,
  ) async {
    final res = await http
        .put(
          Uri.parse('$_base/settings/email'),
          headers: _h(token),
          body: jsonEncode(data),
        )
        .timeout(_timeout);
    return _decode(res);
  }

  /// POST /api/settings/email/test
  static Future<Map<String, dynamic>> sendTestEmail(
    String token,
    String to,
  ) async {
    final res = await http
        .post(
          Uri.parse('$_base/settings/email/test'),
          headers: _h(token),
          body: jsonEncode({'to': to}),
        )
        .timeout(_timeout);
    return _decode(res);
  }

  // ── Storage Settings ───────────────────────────────────────────────────────

  /// GET /api/settings/storage
  static Future<Map<String, dynamic>> getStorageSettings(String token) async {
    final res = await http
        .get(Uri.parse('$_base/settings/storage'), headers: _h(token))
        .timeout(_timeout);
    return _decode(res);
  }

  /// PUT /api/settings/storage
  static Future<Map<String, dynamic>> updateStorageSettings(
    String token,
    Map<String, dynamic> data,
  ) async {
    final res = await http
        .put(
          Uri.parse('$_base/settings/storage'),
          headers: _h(token),
          body: jsonEncode(data),
        )
        .timeout(_timeout);
    return _decode(res);
  }

  /// GET /api/settings/email/logs
  static Future<Map<String, dynamic>> getEmailLogs(String token) async {
    final res = await http
        .get(Uri.parse('$_base/settings/email/logs'), headers: _h(token))
        .timeout(_timeout);
    return _decode(res);
  }

  /// POST /api/settings/roles
  static Future<Map<String, dynamic>> createRole(
    String token,
    Map<String, dynamic> data,
  ) async {
    final res = await http
        .post(
          Uri.parse('$_base/settings/roles'),
          headers: _h(token),
          body: jsonEncode(data),
        )
        .timeout(_timeout);
    return _decode(res);
  }

  /// PUT /api/settings/roles/:id
  static Future<Map<String, dynamic>> updateRole(
    String token,
    String id,
    Map<String, dynamic> data,
  ) async {
    final res = await http
        .put(
          Uri.parse('$_base/settings/roles/$id'),
          headers: _h(token),
          body: jsonEncode(data),
        )
        .timeout(_timeout);
    return _decode(res);
  }

  /// DELETE /api/settings/roles/:id
  static Future<Map<String, dynamic>> deleteRole(
    String token,
    String id,
  ) async {
    final res = await http
        .delete(Uri.parse('$_base/settings/roles/$id'), headers: _h(token))
        .timeout(_timeout);
    return _decode(res);
  }

  /// PUT /api/settings/roles/:id/permissions
  static Future<Map<String, dynamic>> assignPermissions(
    String token,
    String roleId,
    List<dynamic> permissions,
  ) async {
    final res = await http
        .put(
          Uri.parse('$_base/settings/roles/$roleId/permissions'),
          headers: _h(token),
          body: jsonEncode({'permissions': permissions}),
        )
        .timeout(_timeout);
    return _decode(res);
  }

  /// POST /api/settings/employee-id/assign
  static Future<Map<String, dynamic>> assignEmployeeID(
    String token,
    Map<String, dynamic> data,
  ) async {
    final res = await http
        .post(
          Uri.parse('$_base/settings/employee-id/assign'),
          headers: _h(token),
          body: jsonEncode(data),
        )
        .timeout(_timeout);
    return _decode(res);
  }
}
