// To parse this JSON data, do
//
//     final attendanceEditRequest = attendanceEditRequestFromJson(jsonString);

import 'dart:convert';

AttendanceEditRequest attendanceEditRequestFromJson(String str) => 
    AttendanceEditRequest.fromJson(json.decode(str));

String attendanceEditRequestToJson(AttendanceEditRequest data) => 
    json.encode(data.toJson());

class AttendanceEditRequest {
  bool success;
  String message;
  AttendanceEditRequestData data;

  AttendanceEditRequest({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AttendanceEditRequest.fromJson(Map<String, dynamic> json) => 
      AttendanceEditRequest(
        success: json["success"],
        message: json["message"],
        data: AttendanceEditRequestData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data.toJson(),
      };
}

class AttendanceEditRequestData {
  String attendance;
  String user;
  String? company;
  DateTime date;
  DateTime? originalCheckIn;
  DateTime? originalCheckOut;
  DateTime requestedCheckIn;
  DateTime requestedCheckOut;
  String reason;
  String status;
  String id;
  DateTime createdAt;
  DateTime updatedAt;
  int v;

  AttendanceEditRequestData({
    required this.attendance,
    required this.user,
    this.company,
    required this.date,
    this.originalCheckIn,
    this.originalCheckOut,
    required this.requestedCheckIn,
    required this.requestedCheckOut,
    required this.reason,
    required this.status,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory AttendanceEditRequestData.fromJson(Map<String, dynamic> json) =>
      AttendanceEditRequestData(
        attendance: json["attendance"] ?? "",
        user: json["user"] ?? "",
        company: json["company"],
        date: DateTime.parse(json["date"]),
        originalCheckIn: json["originalCheckIn"] != null
            ? DateTime.parse(json["originalCheckIn"])
            : null,
        originalCheckOut: json["originalCheckOut"] != null
            ? DateTime.parse(json["originalCheckOut"])
            : null,
        requestedCheckIn: DateTime.parse(json["requestedCheckIn"]),
        requestedCheckOut: DateTime.parse(json["requestedCheckOut"]),
        reason: json["reason"] ?? "",
        status: json["status"] ?? "pending",
        id: json["_id"] ?? "",
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
        v: json["__v"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "attendance": attendance,
        "user": user,
        if (company != null) "company": company,
        "date": date.toIso8601String(),
        if (originalCheckIn != null) "originalCheckIn": originalCheckIn!.toIso8601String(),
        if (originalCheckOut != null) "originalCheckOut": originalCheckOut!.toIso8601String(),
        "requestedCheckIn": requestedCheckIn.toIso8601String(),
        "requestedCheckOut": requestedCheckOut.toIso8601String(),
        "reason": reason,
        "status": status,
        "_id": id,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
        "__v": v,
      };
}

// ─── List response wrapper ───────────────────────────────────────────────────
class AttendanceEditRequestsList {
  bool success;
  int count;
  List<AttendanceEditRequestData> data;

  AttendanceEditRequestsList({
    required this.success,
    required this.count,
    required this.data,
  });

  factory AttendanceEditRequestsList.fromJson(Map<String, dynamic> json) =>
      AttendanceEditRequestsList(
        success: json["success"] ?? false,
        count: json["count"] ?? 0,
        data: (json["data"] as List<dynamic>? ?? [])
            .map((e) => AttendanceEditRequestData.fromJson(e))
            .toList(),
      );
}

// ─── Admin: populated employee info ─────────────────────────────────────────
class EmployeeInfo {
  final String id;
  final String name;
  final String? employeeId;
  final String? department;
  final String? position;
  final String? email;
  final String? profilePhoto;
  final String? role;

  const EmployeeInfo({
    required this.id,
    required this.name,
    this.employeeId,
    this.department,
    this.position,
    this.email,
    this.profilePhoto,
    this.role,
  });

  factory EmployeeInfo.fromJson(Map<String, dynamic> json) => EmployeeInfo(
        id: json["_id"] ?? json["id"] ?? "",
        name: json["name"] ?? "Unknown",
        employeeId: json["employeeId"]?.toString(),
        department: json["department"]?.toString(),
        position: json["position"]?.toString(),
        email: json["email"]?.toString(),
        profilePhoto: json["profilePhoto"]?.toString(),
        role: json["role"]?.toString(),
      );
}

// ─── Admin edit request data (employee field is populated) ──────────────────
class AdminEditRequestData {
  final String id;
  final String attendanceId;
  final EmployeeInfo? employee;
  final String? companyName;
  final DateTime date;
  final DateTime? originalCheckIn;
  final DateTime? originalCheckOut;
  final DateTime requestedCheckIn;
  final DateTime requestedCheckOut;
  final String reason;
  final String status;
  final String? reviewNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminEditRequestData({
    required this.id,
    required this.attendanceId,
    this.employee,
    this.companyName,
    required this.date,
    this.originalCheckIn,
    this.originalCheckOut,
    required this.requestedCheckIn,
    required this.requestedCheckOut,
    required this.reason,
    required this.status,
    this.reviewNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminEditRequestData.fromJson(Map<String, dynamic> json) {
    // employee may come as an object (populated) or string (id only)
    EmployeeInfo? empInfo;
    final rawEmp = json["employee"] ?? json["user"];
    if (rawEmp is Map<String, dynamic>) {
      empInfo = EmployeeInfo.fromJson(rawEmp);
    }

    // company may be object {name} or just an id string
    String? companyName;
    final rawCo = json["company"];
    if (rawCo is Map<String, dynamic>) {
      companyName = rawCo["name"]?.toString();
    }

    // attendance may be object or string
    String attendanceId = "";
    final rawAtt = json["attendance"];
    if (rawAtt is Map<String, dynamic>) {
      attendanceId = rawAtt["_id"]?.toString() ?? rawAtt["id"]?.toString() ?? "";
    } else if (rawAtt is String) {
      attendanceId = rawAtt;
    }

    return AdminEditRequestData(
      id: json["_id"] ?? json["id"] ?? "",
      attendanceId: attendanceId,
      employee: empInfo,
      companyName: companyName,
      date: DateTime.parse(json["date"]),
      originalCheckIn: json["originalCheckIn"] != null
          ? DateTime.parse(json["originalCheckIn"])
          : null,
      originalCheckOut: json["originalCheckOut"] != null
          ? DateTime.parse(json["originalCheckOut"])
          : null,
      requestedCheckIn: DateTime.parse(json["requestedCheckIn"]),
      requestedCheckOut: DateTime.parse(json["requestedCheckOut"]),
      reason: json["reason"] ?? "",
      status: json["status"] ?? "pending",
      reviewNote: json["reviewNote"]?.toString(),
      createdAt: DateTime.parse(json["createdAt"]),
      updatedAt: DateTime.parse(json["updatedAt"]),
    );
  }
}

// ─── Admin list response ─────────────────────────────────────────────────────
class AdminEditRequestsList {
  final bool success;
  final int count;
  final List<AdminEditRequestData> data;

  const AdminEditRequestsList({
    required this.success,
    required this.count,
    required this.data,
  });

  factory AdminEditRequestsList.fromJson(Map<String, dynamic> json) =>
      AdminEditRequestsList(
        success: json["success"] ?? false,
        count: json["count"] ?? 0,
        data: (json["data"] as List<dynamic>? ?? [])
            .map((e) => AdminEditRequestData.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
