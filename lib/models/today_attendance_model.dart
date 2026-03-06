// To parse this JSON data, do
//
//     final todayAttendance = todayAttendanceFromJson(jsonString);

import 'dart:convert';

TodayAttendance todayAttendanceFromJson(String str) =>
    TodayAttendance.fromJson(json.decode(str));

String todayAttendanceToJson(TodayAttendance data) =>
    json.encode(data.toJson());

// ─────────────────────────────────────────────────────────────────────────────
// Delegate Classes
// ─────────────────────────────────────────────────────────────────────────────

class AttendanceCheckPoint {
  String? time;
  Map<String, dynamic>? location;
  Map<String, dynamic>? photo;

  AttendanceCheckPoint({this.time, this.location, this.photo});

  factory AttendanceCheckPoint.fromJson(Map<String, dynamic> json) =>
      AttendanceCheckPoint(
        time: json["time"],
        location: json["location"],
        photo: json["photo"],
      );

  Map<String, dynamic> toJson() => {
    "time": time,
    "location": location,
    "photo": photo,
  };
}

class AttendanceData {
  AttendanceCheckPoint? checkIn;
  AttendanceCheckPoint? checkOut;
  String? status;
  double? workHours;
  bool hasCheckedIn;
  bool hasCheckedOut;

  AttendanceData({
    this.checkIn,
    this.checkOut,
    this.status,
    this.workHours,
    required this.hasCheckedIn,
    required this.hasCheckedOut,
  });

  factory AttendanceData.fromJson(Map<String, dynamic> json) => AttendanceData(
    checkIn: json["checkIn"] != null
        ? AttendanceCheckPoint.fromJson(json["checkIn"])
        : null,
    checkOut: json["checkOut"] != null
        ? AttendanceCheckPoint.fromJson(json["checkOut"])
        : null,
    status: json["status"],
    workHours: json["workHours"]?.toDouble(),
    hasCheckedIn: json["hasCheckedIn"] ?? false,
    hasCheckedOut: json["hasCheckedOut"] ?? false,
  );

  Map<String, dynamic> toJson() => {
    "checkIn": checkIn?.toJson(),
    "checkOut": checkOut?.toJson(),
    "status": status,
    "workHours": workHours,
    "hasCheckedIn": hasCheckedIn,
    "hasCheckedOut": hasCheckedOut,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Response
// ─────────────────────────────────────────────────────────────────────────────

class TodayAttendance {
  bool success;
  AttendanceData? data;

  TodayAttendance({required this.success, this.data});

  factory TodayAttendance.fromJson(Map<String, dynamic> json) {
    // hasCheckedIn / hasCheckedOut live at the RESPONSE root,
    // not inside the nested "data" object. Merge them so
    // AttendanceData.fromJson can pick them up.
    Map<String, dynamic>? dataJson;
    if (json["data"] != null) {
      dataJson = Map<String, dynamic>.from(json["data"]);
      dataJson["hasCheckedIn"] =
          json["hasCheckedIn"] ?? dataJson["hasCheckedIn"] ?? false;
      dataJson["hasCheckedOut"] =
          json["hasCheckedOut"] ?? dataJson["hasCheckedOut"] ?? false;
    }
    return TodayAttendance(
      success: json["success"] ?? false,
      data: dataJson != null ? AttendanceData.fromJson(dataJson) : null,
    );
  }

  Map<String, dynamic> toJson() => {"success": success, "data": data?.toJson()};
}
