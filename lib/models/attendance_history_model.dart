// Attendance History Model for Calendar Display

import 'dart:convert';

AttendanceHistory attendanceHistoryFromJson(String str) => 
    AttendanceHistory.fromJson(json.decode(str));

String attendanceHistoryToJson(AttendanceHistory data) => 
    json.encode(data.toJson());

class AttendanceHistory {
  bool success;
  List<AttendanceRecord> data;

  AttendanceHistory({
    required this.success,
    required this.data,
  });

  factory AttendanceHistory.fromJson(Map<String, dynamic> json) => 
      AttendanceHistory(
        success: json["success"] ?? false,
        data: json["data"] != null
            ? List<AttendanceRecord>.from(
                json["data"].map((x) => AttendanceRecord.fromJson(x)))
            : [],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}

class AttendanceRecord {
  String? id;
  DateTime date;
  String status; // 'present', 'late', 'absent', 'halfDay', 'wfh'
  String? checkInTime;
  String? checkOutTime;
  double? workHours;

  AttendanceRecord({
    this.id,
    required this.date,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.workHours,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json["_id"],
      date: DateTime.parse(json["date"]),
      status: json["status"] ?? "absent",
      checkInTime: json["checkInTime"],
      checkOutTime: json["checkOutTime"],
      workHours: json["workHours"]?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        "_id": id,
        "date": date.toIso8601String(),
        "status": status,
        "checkInTime": checkInTime,
        "checkOutTime": checkOutTime,
        "workHours": workHours,
      };
}
