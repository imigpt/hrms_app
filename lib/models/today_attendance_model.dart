// To parse this JSON data, do
//
//     final todayAttendance = todayAttendanceFromJson(jsonString);

import 'dart:convert';

TodayAttendance todayAttendanceFromJson(String str) => 
    TodayAttendance.fromJson(json.decode(str));

String todayAttendanceToJson(TodayAttendance data) => 
    json.encode(data.toJson());

class TodayAttendance {
  bool success;
  dynamic data;
  bool hasCheckedIn;
  bool hasCheckedOut;

  TodayAttendance({
    required this.success,
    required this.data,
    required this.hasCheckedIn,
    required this.hasCheckedOut,
  });

  factory TodayAttendance.fromJson(Map<String, dynamic> json) => 
      TodayAttendance(
        success: json["success"] ?? false,
        data: json["data"],
        hasCheckedIn: json["hasCheckedIn"] ?? false,
        hasCheckedOut: json["hasCheckedOut"] ?? false,
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "data": data,
        "hasCheckedIn": hasCheckedIn,
        "hasCheckedOut": hasCheckedOut,
      };
}
