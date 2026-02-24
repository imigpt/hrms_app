import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/apply_leave_model.dart';

class LeaveService {
  static const String baseUrl = 'https://hrms-backend-zzzc.onrender.com/api';

  static Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ── POST /api/leave ─────────────────────────────────────────────────────
  /// Apply for leave. Returns [ApplyLeaveResponse] on success, throws on error.
  static Future<ApplyLeaveResponse> applyLeave({
    required String token,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    double? days, // Optional parameter for custom days (e.g., 0.5 for half day)
  }) async {
    // Strip trailing " Leave" suffix and lowercase (backend expects e.g. "annual")
    final normalizedType =
        leaveType.replaceAll(RegExp(r'\s*[Ll]eave$'), '').toLowerCase();
    final calculatedDays = days ?? (endDate.difference(startDate).inDays + 1);

    final response = await http.post(
      Uri.parse('$baseUrl/leaves'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'leaveType': normalizedType,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'days': calculatedDays,
        'reason': reason,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return applyLeaveResponseFromJson(response.body);
    }

    // Parse error message from body
    try {
      final body = json.decode(response.body) as Map<String, dynamic>;
      final message =
          body['message'] ?? body['error'] ?? 'Failed to apply leave';
      if (body['errors'] != null) {
        final e = body['errors'];
        final detail = e is Map
            ? e.values.join(', ')
            : e is List
                ? (e).join(', ')
                : '';
        throw Exception('$message: $detail');
      }
      throw Exception(message);
    } catch (e) {
      if (e is FormatException) throw Exception('Server error (${response.statusCode})');
      rethrow;
    }
  }

  // ── GET /api/leaves ──────────────────────────────────────────────────────
  /// Get all leave requests for the current user (employees see only their own).
  /// Optional [status] filter: pending | approved | rejected | cancelled.
  static Future<Map<String, dynamic>> getMyLeaves({
    required String token,
    String? status,
  }) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    final uri = Uri.parse('$baseUrl/leaves').replace(queryParameters: params);

    final response = await http.get(uri,
        headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception(
        _errorMessage(response.body) ?? 'Failed to fetch leave requests');
  }

  // ── GET /api/leaves/:id ──────────────────────────────────────────────────
  /// Fetch a single leave request by its MongoDB ID.
  static Future<Map<String, dynamic>> getLeaveById({
    required String token,
    required String leaveId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/leaves/$leaveId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception(
        _errorMessage(response.body) ?? 'Failed to fetch leave request');
  }

  // ── GET /api/leave-balance/me ───────────────────────────────────────────
  /// Returns the current employee's leave balance (paid/sick/unpaid + used counts).
  static Future<LeaveBalanceResponse> getLeaveBalance({
    required String token,
    String? userId,
  }) async {
    // For employees: only use /me (always secure)
    // For admins: can optionally specify /:userId to check other users
    final path = (userId != null && userId.isNotEmpty)
        ? '$baseUrl/leave-balance/$userId'
        : '$baseUrl/leave-balance/me';
    
    final response = await http.get(
      Uri.parse(path),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return LeaveBalanceResponse.fromJson(json.decode(response.body));
    }
    
    // Better error handling
    if (response.statusCode == 403) {
      throw Exception('Access denied to leave balance');
    }
    throw Exception(
        _errorMessage(response.body) ?? 'Failed to fetch leave balance');
  }

  // ── GET /api/leaves/statistics ───────────────────────────────────────────
  /// Returns leave usage statistics for the current year (or [year] if given).
  /// Note: Employees can only view their own statistics. Admins/HR can view any user's stats.
  static Future<Map<String, dynamic>> getLeaveStatistics({
    required String token,
    int? year,
  }) async {
    final params = <String, String>{};
    if (year != null) params['year'] = year.toString();
    // Do NOT pass userId - let backend use current user from token
    final uri =
        Uri.parse('$baseUrl/leaves/statistics').replace(queryParameters: params);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    
    // Better error handling
    if (response.statusCode == 403) {
      throw Exception('Access denied to leave statistics');
    }
    throw Exception(
        _errorMessage(response.body) ?? 'Failed to fetch leave statistics');
  }

  // ── PUT /api/leaves/:id/cancel ───────────────────────────────────────────
  /// Cancel a pending leave request. Only the owner (or admin/hr) can cancel.
  static Future<Map<String, dynamic>> cancelLeave({
    required String token,
    required String leaveId,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/leaves/$leaveId/cancel'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception(
        _errorMessage(response.body) ?? 'Failed to cancel leave request');
  }

  // ── Internal helper ──────────────────────────────────────────────────────
  static String? _errorMessage(String body) {
    try {
      final decoded = json.decode(body) as Map<String, dynamic>;
      return decoded['message'] as String?;
    } catch (_) {
      return null;
    }
  }
}
