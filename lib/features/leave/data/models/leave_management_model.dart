import 'dart:convert';

// ── Top-level helpers ─────────────────────────────────────────────────────────

AdminLeavesResponse adminLeavesResponseFromJson(String str) =>
    AdminLeavesResponse.fromJson(json.decode(str));

// ── Response wrapper ──────────────────────────────────────────────────────────

class AdminLeavesResponse {
  final bool success;
  final int count;
  final List<AdminLeaveData> data;

  AdminLeavesResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory AdminLeavesResponse.fromJson(Map<String, dynamic> json) =>
      AdminLeavesResponse(
        success: json['success'] ?? false,
        count: json['count'] ?? 0,
        data: (json['data'] as List<dynamic>? ?? [])
            .map((e) => AdminLeaveData.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ── Leave entry ───────────────────────────────────────────────────────────────

class AdminLeaveData {
  final String id;
  final LeaveUser? user;
  final String leaveType; // sick | paid | unpaid
  final bool isHalfDay;
  final String? session; // morning | afternoon | null
  final DateTime startDate;
  final DateTime endDate;
  final double days;
  final String reason;
  final String status; // pending | approved | rejected | cancelled
  final LeaveUser? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdminLeaveData({
    required this.id,
    this.user,
    required this.leaveType,
    required this.isHalfDay,
    this.session,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.reason,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminLeaveData.fromJson(Map<String, dynamic> json) {
    // user can be a populated object or just a string ID
    LeaveUser? user;
    final rawUser = json['user'];
    if (rawUser is Map<String, dynamic>) {
      user = LeaveUser.fromJson(rawUser);
    }

    // reviewedBy can be a populated object or string ID
    LeaveUser? reviewedBy;
    final rawReviewer = json['reviewedBy'];
    if (rawReviewer is Map<String, dynamic>) {
      reviewedBy = LeaveUser.fromJson(rawReviewer);
    }

    return AdminLeaveData(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      user: user,
      leaveType: json['leaveType']?.toString() ?? 'paid',
      isHalfDay: json['isHalfDay'] as bool? ?? false,
      session: json['session']?.toString(),
      startDate: _parseDate(json['startDate']) ?? DateTime.now(),
      endDate: _parseDate(json['endDate']) ?? DateTime.now(),
      days: (json['days'] as num?)?.toDouble() ?? 1,
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      reviewedBy: reviewedBy,
      reviewedAt: _parseDate(json['reviewedAt']),
      reviewNote: json['reviewNote']?.toString(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    try {
      return DateTime.parse(val.toString());
    } catch (_) {
      return null;
    }
  }
}

// ── Embedded user ─────────────────────────────────────────────────────────────

class LeaveUser {
  final String id;
  final String? name;
  final String? employeeId;
  final String? department;
  final String? position;
  final String? email;
  final String? profilePhoto;
  final String? role;

  LeaveUser({
    required this.id,
    this.name,
    this.employeeId,
    this.department,
    this.position,
    this.email,
    this.profilePhoto,
    this.role,
  });

  factory LeaveUser.fromJson(Map<String, dynamic> json) => LeaveUser(
    id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
    name: json['name']?.toString(),
    employeeId: json['employeeId']?.toString(),
    department: json['department']?.toString(),
    position: json['position']?.toString(),
    email: json['email']?.toString(),
    profilePhoto: json['profilePhoto']?.toString(),
    role: json['role']?.toString(),
  );
}
