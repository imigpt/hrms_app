// To parse this JSON data, do
//
//     final checkOutResponse = checkOutResponseFromJson(jsonString);

import 'dart:convert';

CheckOutResponse checkOutResponseFromJson(String str) => CheckOutResponse.fromJson(json.decode(str));

String checkOutResponseToJson(CheckOutResponse data) => json.encode(data.toJson());

class CheckOutResponse {
    bool success;
    String message;
    CheckOutData data;

    CheckOutResponse({
        required this.success,
        required this.message,
        required this.data,
    });

    factory CheckOutResponse.fromJson(Map<String, dynamic> json) => CheckOutResponse(
        success: json["success"],
        message: json["message"],
        data: CheckOutData.fromJson(json["data"]),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data.toJson(),
    };
}

class CheckOutData {
    CheckInInfo checkIn;
    CheckOutInfo checkOut;
    String id;
    String user;
    dynamic company;
    DateTime date;
    String status;
    double workHours;
    bool isManualEntry;
    DateTime createdAt;
    DateTime updatedAt;
    int v;

    CheckOutData({
        required this.checkIn,
        required this.checkOut,
        required this.id,
        required this.user,
        required this.company,
        required this.date,
        required this.status,
        required this.workHours,
        required this.isManualEntry,
        required this.createdAt,
        required this.updatedAt,
        required this.v,
    });

    factory CheckOutData.fromJson(Map<String, dynamic> json) => CheckOutData(
        checkIn: CheckInInfo.fromJson(json["checkIn"]),
        checkOut: CheckOutInfo.fromJson(json["checkOut"]),
        id: json["_id"],
        user: json["user"],
        company: json["company"],
        date: DateTime.parse(json["date"]),
        status: json["status"],
        workHours: json["workHours"]?.toDouble() ?? 0.0,
        isManualEntry: json["isManualEntry"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
        v: json["__v"],
    );

    Map<String, dynamic> toJson() => {
        "checkIn": checkIn.toJson(),
        "checkOut": checkOut.toJson(),
        "_id": id,
        "user": user,
        "company": company,
        "date": date.toIso8601String(),
        "status": status,
        "workHours": workHours,
        "isManualEntry": isManualEntry,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
        "__v": v,
    };
}

class CheckInInfo {
    PhotoInfo photo;
    DateTime time;

    CheckInInfo({
        required this.photo,
        required this.time,
    });

    factory CheckInInfo.fromJson(Map<String, dynamic> json) => CheckInInfo(
        photo: PhotoInfo.fromJson(json["photo"]),
        time: DateTime.parse(json["time"]),
    );

    Map<String, dynamic> toJson() => {
        "photo": photo.toJson(),
        "time": time.toIso8601String(),
    };
}

class PhotoInfo {
    String url;
    String publicId;
    DateTime capturedAt;

    PhotoInfo({
        required this.url,
        required this.publicId,
        required this.capturedAt,
    });

    factory PhotoInfo.fromJson(Map<String, dynamic> json) => PhotoInfo(
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

class CheckOutInfo {
    DateTime time;

    CheckOutInfo({
        required this.time,
    });

    factory CheckOutInfo.fromJson(Map<String, dynamic> json) => CheckOutInfo(
        time: DateTime.parse(json["time"]),
    );

    Map<String, dynamic> toJson() => {
        "time": time.toIso8601String(),
    };
}
