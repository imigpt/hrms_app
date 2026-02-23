// To parse this JSON data, do
//
//     final applyLeaveResponse = applyLeaveResponseFromJson(jsonString);

import 'dart:convert';

ApplyLeaveResponse applyLeaveResponseFromJson(String str) => 
    ApplyLeaveResponse.fromJson(json.decode(str));

String applyLeaveResponseToJson(ApplyLeaveResponse data) => 
    json.encode(data.toJson());

class ApplyLeaveResponse {
  bool success;
  String message;
  LeaveData data;

  ApplyLeaveResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ApplyLeaveResponse.fromJson(Map<String, dynamic> json) => 
      ApplyLeaveResponse(
        success: json["success"],
        message: json["message"],
        data: LeaveData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data.toJson(),
      };
}

class LeaveData {
  String user;
  dynamic company;
  String leaveType;
  DateTime startDate;
  DateTime endDate;
  int days;
  String reason;
  String status;
  List<dynamic> attachments;
  int balanceDeducted;
  bool balanceRestored;
  String id;
  DateTime createdAt;
  DateTime updatedAt;
  int v;

  LeaveData({
    required this.user,
    required this.company,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.reason,
    required this.status,
    required this.attachments,
    required this.balanceDeducted,
    required this.balanceRestored,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory LeaveData.fromJson(Map<String, dynamic> json) => LeaveData(
        user: json["user"],
        company: json["company"],
        leaveType: json["leaveType"],
        startDate: DateTime.parse(json["startDate"]),
        endDate: DateTime.parse(json["endDate"]),
        days: json["days"],
        reason: json["reason"],
        status: json["status"],
        attachments: List<dynamic>.from(json["attachments"].map((x) => x)),
        balanceDeducted: json["balanceDeducted"],
        balanceRestored: json["balanceRestored"],
        id: json["_id"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
        v: json["__v"],
      );

  Map<String, dynamic> toJson() => {
        "user": user,
        "company": company,
        "leaveType": leaveType,
        "startDate": startDate.toIso8601String(),
        "endDate": endDate.toIso8601String(),
        "days": days,
        "reason": reason,
        "status": status,
        "attachments": List<dynamic>.from(attachments.map((x) => x)),
        "balanceDeducted": balanceDeducted,
        "balanceRestored": balanceRestored,
        "_id": id,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
        "__v": v,
      };
}

// ────────────────────────────────────────────────────────────────────────────
// Leave List  GET /api/leaves
// Returns { success, count, data: [ LeaveItem, ... ] }
// ────────────────────────────────────────────────────────────────────────────

class LeaveListResponse {
  final bool success;
  final int count;
  final List<LeaveItem> data;

  LeaveListResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory LeaveListResponse.fromJson(Map<String, dynamic> json) =>
      LeaveListResponse(
        success: json['success'] ?? false,
        count: json['count'] ?? 0,
        data: (json['data'] as List<dynamic>? ?? [])
            .map((e) => LeaveItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ────────────────────────────────────────────────────────────────────────────
// Leave Detail  GET /api/leaves/:id  |  PUT /api/leaves/:id/cancel
// Returns { success, message?, data: LeaveItem }
// ────────────────────────────────────────────────────────────────────────────

class LeaveDetailResponse {
  final bool success;
  final String? message;
  final LeaveItem? data;

  LeaveDetailResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory LeaveDetailResponse.fromJson(Map<String, dynamic> json) =>
      LeaveDetailResponse(
        success: json['success'] ?? false,
        message: json['message'],
        data: json['data'] != null
            ? LeaveItem.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );
}

// ────────────────────────────────────────────────────────────────────────────
// Shared leave document (list + detail use the same shape)
// ────────────────────────────────────────────────────────────────────────────

class LeaveItem {
  final String id;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final int days;
  final String reason;
  final String status; // pending | approved | rejected | cancelled
  final int balanceDeducted;
  final bool balanceRestored;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic user;       // String id OR populated { name, employeeId, ... }
  final dynamic reviewedBy; // null OR populated { name, employeeId }
  final DateTime? reviewedAt;
  final String? reviewNote;
  final dynamic company;

  LeaveItem({
    required this.id,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.reason,
    required this.status,
    required this.balanceDeducted,
    required this.balanceRestored,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNote,
    this.company,
  });

  factory LeaveItem.fromJson(Map<String, dynamic> json) => LeaveItem(
        id: json['_id'] ?? '',
        leaveType: json['leaveType'] ?? '',
        startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
        endDate: DateTime.tryParse(json['endDate'] ?? '') ?? DateTime.now(),
        days: (json['days'] ?? 0) as int,
        reason: json['reason'] ?? '',
        status: json['status'] ?? 'pending',
        balanceDeducted: (json['balanceDeducted'] ?? 0) as int,
        balanceRestored: json['balanceRestored'] ?? false,
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
        user: json['user'],
        reviewedBy: json['reviewedBy'],
        reviewedAt: json['reviewedAt'] != null
            ? DateTime.tryParse(json['reviewedAt'])
            : null,
        reviewNote: json['reviewNote'],
        company: json['company'],
      );

  /// Convenience: leave type with first letter capitalised + "Leave" suffix
  String get displayType {
    if (leaveType.isEmpty) return 'Leave';
    return '${leaveType[0].toUpperCase()}${leaveType.substring(1)} Leave';
  }

  /// Convenience: status capitalised
  String get displayStatus {
    if (status.isEmpty) return 'Pending';
    return status[0].toUpperCase() + status.substring(1);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Leave Balance  GET /api/leaves/balance
// Returns { success, data: { annual, sick, casual, maternity, paternity, unpaid } }
// ────────────────────────────────────────────────────────────────────────────

class LeaveBalanceResponse {
  final bool success;
  final LeaveBalance? data;

  LeaveBalanceResponse({required this.success, this.data});

  factory LeaveBalanceResponse.fromJson(Map<String, dynamic> json) =>
      LeaveBalanceResponse(
        success: json['success'] ?? false,
        data: json['data'] != null
            ? LeaveBalance.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );
}

class LeaveBalance {
  final String id;
  final String user;
  final int paid;
  final int sick;
  final int unpaid;
  final int usedPaid;
  final int usedSick;
  final int usedUnpaid;

  LeaveBalance({
    required this.id,
    required this.user,
    required this.paid,
    required this.sick,
    required this.unpaid,
    required this.usedPaid,
    required this.usedSick,
    required this.usedUnpaid,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) => LeaveBalance(
        id: (json['_id'] ?? '') as String,
        user: (json['user'] ?? '') as String,
        paid: (json['paid'] ?? 0) as int,
        sick: (json['sick'] ?? 0) as int,
        unpaid: (json['unpaid'] ?? 0) as int,
        usedPaid: (json['usedPaid'] ?? 0) as int,
        usedSick: (json['usedSick'] ?? 0) as int,
        usedUnpaid: (json['usedUnpaid'] ?? 0) as int,
      );
}

// ────────────────────────────────────────────────────────────────────────────
// Leave Statistics  GET /api/leaves/statistics
// Returns { success, data: { total, pending, approved, rejected, cancelled,
//                             daysTaken, byType } }
// ────────────────────────────────────────────────────────────────────────────

class LeaveStatisticsResponse {
  final bool success;
  final LeaveStatistics? data;

  LeaveStatisticsResponse({required this.success, this.data});

  factory LeaveStatisticsResponse.fromJson(Map<String, dynamic> json) =>
      LeaveStatisticsResponse(
        success: json['success'] ?? false,
        data: json['data'] != null
            ? LeaveStatistics.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );
}

class LeaveStatistics {
  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final int cancelled;
  final int daysTaken;
  final Map<String, int> byType;

  LeaveStatistics({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.cancelled,
    required this.daysTaken,
    required this.byType,
  });

  factory LeaveStatistics.fromJson(Map<String, dynamic> json) {
    final rawByType = json['byType'] as Map<String, dynamic>? ?? {};
    final byType =
        rawByType.map((k, v) => MapEntry(k, (v ?? 0) as int));
    return LeaveStatistics(
      total: (json['total'] ?? 0) as int,
      pending: (json['pending'] ?? 0) as int,
      approved: (json['approved'] ?? 0) as int,
      rejected: (json['rejected'] ?? 0) as int,
      cancelled: (json['cancelled'] ?? 0) as int,
      daysTaken: (json['daysTaken'] ?? 0) as int,
      byType: byType,
    );
  }
}
