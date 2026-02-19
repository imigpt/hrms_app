// To parse this JSON data, do
//
//     final checkInResponse = checkInResponseFromJson(jsonString);

import 'dart:convert';

CheckInResponse checkInResponseFromJson(String str) => CheckInResponse.fromJson(json.decode(str));

String checkInResponseToJson(CheckInResponse data) => json.encode(data.toJson());

class CheckInResponse {
    bool success;
    String message;
    AttendanceData data;

    CheckInResponse({
        required this.success,
        required this.message,
        required this.data,
    });

    factory CheckInResponse.fromJson(Map<String, dynamic> json) => CheckInResponse(
        success: json["success"],
        message: json["message"],
        data: AttendanceData.fromJson(json["data"]),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data.toJson(),
    };
}

class AttendanceData {
    String user;
    dynamic company;
    DateTime date;
    CheckIn checkIn;
    CheckOut? checkOut;
    String status;
    double workHours;
    bool isManualEntry;
    String id;
    DateTime createdAt;
    DateTime updatedAt;
    int v;

    AttendanceData({
        required this.user,
        required this.company,
        required this.date,
        required this.checkIn,
        this.checkOut,
        required this.status,
        required this.workHours,
        required this.isManualEntry,
        required this.id,
        required this.createdAt,
        required this.updatedAt,
        required this.v,
    });

    factory AttendanceData.fromJson(Map<String, dynamic> json) => AttendanceData(
        user: json["user"],
        company: json["company"],
        date: DateTime.parse(json["date"]),
        checkIn: CheckIn.fromJson(json["checkIn"]),
        checkOut: json["checkOut"] != null ? CheckOut.fromJson(json["checkOut"]) : null,
        status: json["status"],
        workHours: ((json["workHours"] ?? 0) as num).toDouble(),
        isManualEntry: json["isManualEntry"],
        id: json["_id"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
        v: json["__v"],
    );

    Map<String, dynamic> toJson() => {
        "user": user,
        "company": company,
        "date": date.toIso8601String(),
        "checkIn": checkIn.toJson(),
        "checkOut": checkOut?.toJson(),
        "status": status,
        "workHours": workHours,
        "isManualEntry": isManualEntry,
        "_id": id,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
        "__v": v,
    };
}

class CheckIn {
    DateTime time;
    Location? location;
    Photo photo;

    CheckIn({
        required this.time,
        this.location,
        required this.photo,
    });

    factory CheckIn.fromJson(Map<String, dynamic> json) => CheckIn(
        time: DateTime.parse(json["time"]).toLocal(),
        location: json["location"] != null ? Location.fromJson(json["location"]) : null,
        photo: Photo.fromJson(json["photo"]),
    );

    Map<String, dynamic> toJson() => {
        "time": time.toIso8601String(),
        "location": location?.toJson(),
        "photo": photo.toJson(),
    };
}

class CheckOut {
    DateTime time;
    Location? location;

    CheckOut({
        required this.time,
        this.location,
    });

    factory CheckOut.fromJson(Map<String, dynamic> json) => CheckOut(
        time: DateTime.parse(json["time"]).toLocal(),
        location: json["location"] != null ? Location.fromJson(json["location"]) : null,
    );

    Map<String, dynamic> toJson() => {
        "time": time.toIso8601String(),
        "location": location?.toJson(),
    };
}

class Location {
    double latitude;
    double longitude;

    Location({
        required this.latitude,
        required this.longitude,
    });

    factory Location.fromJson(Map<String, dynamic> json) => Location(
        latitude: ((json["latitude"] ?? 0) as num).toDouble(),
        longitude: ((json["longitude"] ?? 0) as num).toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "latitude": latitude,
        "longitude": longitude,
    };
}

class Photo {
    String url;
    String publicId;
    DateTime capturedAt;

    Photo({
        required this.url,
        required this.publicId,
        required this.capturedAt,
    });

    factory Photo.fromJson(Map<String, dynamic> json) => Photo(
        url: json["url"],
        publicId: json["publicId"],
        capturedAt: DateTime.parse(json["capturedAt"]),
    );

    Map<String, dynamic> toJson() => {
        "url": url,
        "publicId": publicId,
        "capturedAt": capturedAt.toIso8601String(),
    };
}
