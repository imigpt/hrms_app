import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:hrms_app/core/config/api_config.dart';
import 'package:hrms_app/features/leave/data/models/apply_leave_model.dart';
import 'package:hrms_app/features/leave/data/models/leave_balance_model.dart';
import 'package:hrms_app/features/leave/data/models/leave_management_model.dart';

class LeaveService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Map<String, String> _authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ── POST /api/leaves/half-day ──────────────────────────────────────────────
  /// Apply for half-day leave. Returns [ApplyLeaveResponse] on success.
  static Future<ApplyLeaveResponse> applyHalfDayLeave({
    required String token,
    required DateTime date,
    required String session, // 'morning' or 'afternoon'
    required String reason,
    String leaveType = 'paid', // 'paid' or 'unpaid'
  }) async {
    // Format date as yyyy-MM-dd
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    final payload = {
      'date': dateStr,
      'session': session.toLowerCase(),
      'leaveType': leaveType.toLowerCase(),
      'reason': reason,
    };
    print('[HalfDayLeave] Payload: ' + jsonEncode(payload));
    final response = await http.post(
      Uri.parse('$baseUrl/leaves/half-day'),
      headers: _authHeaders(token),
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return applyLeaveResponseFromJson(response.body);
    }

    // Parse error message from body
    try {
      final body = json.decode(response.body) as Map<String, dynamic>;
      final message =
          body['message'] ?? body['error'] ?? 'Failed to apply half-day leave';
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
      if (e is FormatException)
        throw Exception('Server error (${response.statusCode})');
      rethrow;
    }
  }

  // ── POST /api/leaves ────────────────────────────────────────────────────
  /// Apply for leave. Returns [ApplyLeaveResponse] on success, throws on error.
  static Future<ApplyLeaveResponse> applyLeave({
    required String token,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    double? days, // Optional parameter for custom days (e.g., 0.5 for half day)
  }) async {
    print(
      '🔵 [ApplyLeave] Input dates: startDate=$startDate, endDate=$endDate',
    );

    // Strip trailing " Leave" suffix and lowercase (backend expects e.g. "annual")
    final normalizedType = leaveType
        .replaceAll(RegExp(r'\s*[Ll]eave$'), '')
        .toLowerCase();
    final calculatedDays = days ?? (endDate.difference(startDate).inDays + 1);

    // Format dates as yyyy-MM-dd
    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    print(
      '✅ [ApplyLeave] Formatted dates: startDate=$startDateStr, endDate=$endDateStr, type=$normalizedType, days=$calculatedDays, reason=$reason',
    );

    final body = {
      'leaveType': normalizedType,
      'startDate': startDateStr,
      'endDate': endDateStr,
      'days': calculatedDays,
      'reason': reason,
    };

    print('📤 [ApplyLeave] Request body: ${jsonEncode(body)}');

    final response = await http.post(
      Uri.parse('$baseUrl/leaves'),
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );

    print('📥 [ApplyLeave] Response status: ${response.statusCode}');
    print('📥 [ApplyLeave] Response body: ${response.body}');

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
      if (e is FormatException)
        throw Exception('Server error (${response.statusCode})');
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

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception(
      _errorMessage(response.body) ?? 'Failed to fetch leave requests',
    );
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
      _errorMessage(response.body) ?? 'Failed to fetch leave request',
    );
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
      _errorMessage(response.body) ?? 'Failed to fetch leave balance',
    );
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
    final uri = Uri.parse(
      '$baseUrl/leaves/statistics',
    ).replace(queryParameters: params);

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
      _errorMessage(response.body) ?? 'Failed to fetch leave statistics',
    );
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
      _errorMessage(response.body) ?? 'Failed to cancel leave request',
    );
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

  // ── GET /api/leaves  (admin - all company leaves) ─────────────────────────
  /// Admin: fetch all leave requests for the company, optional [status] filter.
  static Future<AdminLeavesResponse> getAdminLeaves({
    required String token,
    String? status,
  }) async {
    final params = <String, String>{};
    if (status != null && status.isNotEmpty) params['status'] = status;
    final uri = Uri.parse('$baseUrl/leaves').replace(queryParameters: params);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return adminLeavesResponseFromJson(response.body);
    }
    throw Exception(
      _errorMessage(response.body) ?? 'Failed to fetch leave requests',
    );
  }

  // ── PUT /api/leaves/:id/approve ────────────────────────────────────────────
  /// Admin/HR: approve a leave request.
  static Future<void> approveAdminLeave({
    required String token,
    required String leaveId,
    String? reviewNote,
  }) async {
    final body = <String, dynamic>{};
    if (reviewNote != null && reviewNote.isNotEmpty)
      body['reviewNote'] = reviewNote;

    final response = await http.put(
      Uri.parse('$baseUrl/leaves/$leaveId/approve'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        _errorMessage(response.body) ?? 'Failed to approve leave request',
      );
    }
  }

  // ── PUT /api/leaves/:id/reject ─────────────────────────────────────────────
  /// Admin/HR: reject a leave request.
  static Future<void> rejectAdminLeave({
    required String token,
    required String leaveId,
    String? reviewNote,
  }) async {
    final body = <String, dynamic>{};
    if (reviewNote != null && reviewNote.isNotEmpty)
      body['reviewNote'] = reviewNote;

    final response = await http.put(
      Uri.parse('$baseUrl/leaves/$leaveId/reject'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        _errorMessage(response.body) ?? 'Failed to reject leave request',
      );
    }
  }

  // ── Leave Balance (admin) ─────────────────────────────────────────────────

  /// GET /api/leave-balance?role=&search=
  static Future<LeaveBalanceListResponse> getLeaveBalances({
    required String token,
    String role = 'all',
    String search = '',
  }) async {
    final params = <String, String>{};
    if (role.isNotEmpty && role != 'all') params['role'] = role;
    if (search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse(
      '$baseUrl/leave-balance',
    ).replace(queryParameters: params.isEmpty ? null : params);

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return LeaveBalanceListResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(
      _errorMessage(response.body) ?? 'Failed to fetch leave balances',
    );
  }

  /// PUT /api/leave-balance/:userId  — assign / update balance
  static Future<void> assignLeaveBalance({
    required String token,
    required String userId,
    required int paid,
    required int sick,
    required int unpaid,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/leave-balance/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'paid': paid, 'sick': sick, 'unpaid': unpaid}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        _errorMessage(response.body) ?? 'Failed to assign leave balance',
      );
    }
  }

  /// POST /api/leave-balance/bulk  — bulk assign
  static Future<void> bulkAssignLeaveBalance({
    required String token,
    required List<String> userIds,
    required int paid,
    required int sick,
    required int unpaid,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/leave-balance/bulk'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userIds': userIds,
        'paid': paid,
        'sick': sick,
        'unpaid': unpaid,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        _errorMessage(response.body) ?? 'Failed to bulk assign balances',
      );
    }
  }
}
