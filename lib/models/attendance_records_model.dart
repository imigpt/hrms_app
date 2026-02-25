// To parse this JSON data, do
//
//     final attendanceRecords = attendanceRecordsFromJson(jsonString);

import 'dart:convert';

AttendanceRecords attendanceRecordsFromJson(String str) => 
    AttendanceRecords.fromJson(json.decode(str));

String attendanceRecordsToJson(AttendanceRecords data) => 
    json.encode(data.toJson());

class AttendanceRecords {
  bool success;
  int count;
  List<AttendanceRecord> data;

  AttendanceRecords({
    required this.success,
    required this.count,
    required this.data,
  });

  factory AttendanceRecords.fromJson(Map<String, dynamic> json) => 
      AttendanceRecords(
        success: json["success"] ?? false,
        count: json["count"] ?? 0,
        data: json["data"] != null 
            ? List<AttendanceRecord>.from(json["data"].map((x) => AttendanceRecord.fromJson(x)))
            : [],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "count": count,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}

class AttendanceRecord {
  String id;
  User user;
  dynamic company;
  DateTime date;
  RecordCheckIn checkIn;
  RecordCheckOut? checkOut;
  String status;
  double workHours;
  bool isManualEntry;
  DateTime createdAt;
  DateTime updatedAt;
  int v;

  AttendanceRecord({
    required this.id,
    required this.user,
    required this.company,
    required this.date,
    required this.checkIn,
    this.checkOut,
    required this.status,
    required this.workHours,
    required this.isManualEntry,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => 
      AttendanceRecord(
        id: json["_id"] ?? "",
        user: json["user"] != null ? User.fromJson(json["user"]) : User.fromJson({}),
        company: json["company"],
        date: json["date"] != null ? DateTime.parse(json["date"]) : DateTime.now(),
        checkIn: json["checkIn"] != null ? RecordCheckIn.fromJson(json["checkIn"]) : RecordCheckIn.fromJson({}),
        checkOut: json["checkOut"] != null 
            ? RecordCheckOut.fromJson(json["checkOut"]) 
            : null,
        status: json["status"] ?? "unknown",
        workHours: ((json["workHours"] ?? 0) as num).toDouble(),
        isManualEntry: json["isManualEntry"] ?? false,
        createdAt: json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : DateTime.now(),
        updatedAt: json["updatedAt"] != null ? DateTime.parse(json["updatedAt"]) : DateTime.now(),
        v: json["__v"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "user": user.toJson(),
        "company": company,
        "date": date.toIso8601String(),
        "checkIn": checkIn.toJson(),
        "checkOut": checkOut?.toJson(),
        "status": status,
        "workHours": workHours,
        "isManualEntry": isManualEntry,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
        "__v": v,
      };
}

class RecordCheckIn {
  DateTime time;
  RecordLocation? location;
  RecordPhoto photo;

  RecordCheckIn({
    required this.time,
    this.location,
    required this.photo,
  });

  factory RecordCheckIn.fromJson(Map<String, dynamic> json) => 
      RecordCheckIn(
        time: json["time"] != null ? DateTime.parse(json["time"]).toLocal() : DateTime.now(),
        location: json["location"] != null 
            ? RecordLocation.fromJson(json["location"]) 
            : null,
        photo: json["photo"] != null ? RecordPhoto.fromJson(json["photo"]) : RecordPhoto.fromJson({}),
      );

  Map<String, dynamic> toJson() => {
        "time": time.toIso8601String(),
        "location": location?.toJson(),
        "photo": photo.toJson(),
      };
}

class RecordCheckOut {
  DateTime time;
  RecordLocation? location;

  RecordCheckOut({
    required this.time,
    this.location,
  });

  factory RecordCheckOut.fromJson(Map<String, dynamic> json) => 
      RecordCheckOut(
        time: json["time"] != null ? DateTime.parse(json["time"]).toLocal() : DateTime.now(),
        location: json["location"] != null 
            ? RecordLocation.fromJson(json["location"]) 
            : null,
      );

  Map<String, dynamic> toJson() => {
        "time": time.toIso8601String(),
        "location": location?.toJson(),
      };
}

class RecordLocation {
  double latitude;
  double longitude;

  RecordLocation({
    required this.latitude,
    required this.longitude,
  });

  factory RecordLocation.fromJson(Map<String, dynamic> json) => 
      RecordLocation(
        latitude: ((json["latitude"] ?? 0) as num).toDouble(),
        longitude: ((json["longitude"] ?? 0) as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "latitude": latitude,
        "longitude": longitude,
      };
}

class RecordPhoto {
  String url;
  String publicId;
  DateTime? capturedAt;

  RecordPhoto({
    required this.url,
    required this.publicId,
    this.capturedAt,
  });

  factory RecordPhoto.fromJson(Map<String, dynamic> json) => 
      RecordPhoto(
        url: json["url"] ?? "",
        publicId: json["publicId"] ?? "",
        capturedAt: json["capturedAt"] != null 
            ? DateTime.parse(json["capturedAt"]) 
            : null,
      );

  Map<String, dynamic> toJson() => {
        "url": url,
        "publicId": publicId,
        "capturedAt": capturedAt?.toIso8601String(),
      };
}

class User {
  String id;
  String employeeId;
  String name;
  String department;

  User({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.department,
  });

  factory User.fromJson(Map<String, dynamic> json) => 
      User(
        id: json["_id"] ?? "",
        employeeId: json["employeeId"] ?? "",
        name: json["name"] ?? "",
        department: json["department"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "employeeId": employeeId,
        "name": name,
        "department": department,
      };
}
