// To parse this JSON data, do
//
//     final attendanceSummary = attendanceSummaryFromJson(jsonString);

import 'dart:convert';

AttendanceSummary attendanceSummaryFromJson(String str) =>
    AttendanceSummary.fromJson(json.decode(str));

String attendanceSummaryToJson(AttendanceSummary data) =>
    json.encode(data.toJson());

class AttendanceSummary {
  bool success;
  AttendanceSummaryData data;

  AttendanceSummary({required this.success, required this.data});

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) =>
      AttendanceSummary(
        success: json["success"],
        data: AttendanceSummaryData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {"success": success, "data": data.toJson()};
}

class AttendanceSummaryData {
  int totalDays;
  int present;
  int late;
  int halfDay;
  int absent;
  int wfh;
  double totalWorkHours;
  String averageWorkHours;

  AttendanceSummaryData({
    required this.totalDays,
    required this.present,
    required this.late,
    required this.halfDay,
    required this.absent,
    required this.wfh,
    required this.totalWorkHours,
    required this.averageWorkHours,
  });

  factory AttendanceSummaryData.fromJson(Map<String, dynamic> json) =>
      AttendanceSummaryData(
        totalDays: ((json["totalDays"] ?? 0) as num).toInt(),
        present: ((json["present"] ?? 0) as num).toInt(),
        late: ((json["late"] ?? 0) as num).toInt(),
        halfDay: ((json["halfDay"] ?? 0) as num).toInt(),
        absent: ((json["absent"] ?? 0) as num).toInt(),
        wfh: ((json["wfh"] ?? 0) as num).toInt(),
        totalWorkHours: ((json["totalWorkHours"] ?? 0) as num).toDouble(),
        averageWorkHours: _parseAverageWorkHours(json["averageWorkHours"]),
      );

  // Helper method to handle averageWorkHours which can be String, int, or double
  static String _parseAverageWorkHours(dynamic value) {
    if (value == null) return "0h 0m";

    // If it's already a string, return it
    if (value is String) return value;

    // If it's a number, convert to "Xh Ym" format
    if (value is num) {
      final hours = value.floor();
      final minutes = ((value - hours) * 60).round();
      return '${hours}h ${minutes}m';
    }

    return "0h 0m";
  }

  Map<String, dynamic> toJson() => {
    "totalDays": totalDays,
    "present": present,
    "late": late,
    "halfDay": halfDay,
    "absent": absent,
    "wfh": wfh,
    "totalWorkHours": totalWorkHours,
    "averageWorkHours": averageWorkHours,
  };
}
