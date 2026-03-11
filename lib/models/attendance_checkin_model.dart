// To parse this JSON data, do
//
//     final checkInResponse = checkInResponseFromJson(jsonString);

import 'dart:convert';

CheckInResponse checkInResponseFromJson(String str) =>
    CheckInResponse.fromJson(json.decode(str));

String checkInResponseToJson(CheckInResponse data) =>
    json.encode(data.toJson());

class FaceVerification {
  final int similarityScore;
  final bool matched;

  FaceVerification({required this.similarityScore, required this.matched});

  factory FaceVerification.fromJson(Map<String, dynamic> json) =>
      FaceVerification(
        similarityScore: (json["similarityScore"] as num).toInt(),
        matched: json["matched"] as bool,
      );

  Map<String, dynamic> toJson() => {
    "similarityScore": similarityScore,
    "matched": matched,
  };
}

class CheckInResponse {
  bool success;
  String message;
  AttendanceData data;
  FaceVerification? faceVerification;

  CheckInResponse({
    required this.success,
    required this.message,
    required this.data,
    this.faceVerification,
  });

  factory CheckInResponse.fromJson(Map<String, dynamic> json) =>
      CheckInResponse(
        success: json["success"],
        message: json["message"],
        data: AttendanceData.fromJson(json["data"]),
        faceVerification: json["faceVerification"] != null
            ? FaceVerification.fromJson(
                json["faceVerification"] as Map<String, dynamic>,
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": data.toJson(),
    if (faceVerification != null)
      "faceVerification": faceVerification!.toJson(),
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
    checkOut: json["checkOut"] != null
        ? CheckOut.fromJson(json["checkOut"])
        : null,
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
  Photo? photo;
  int? similarityScore;

  CheckIn({
    required this.time,
    this.location,
    this.photo,
    this.similarityScore,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) => CheckIn(
    time: DateTime.parse(json["time"]).toLocal(),
    location: json["location"] != null
        ? Location.fromJson(json["location"] as Map<String, dynamic>)
        : null,
    photo: json["photo"] != null
        ? Photo.fromJson(json["photo"] as Map<String, dynamic>)
        : null,
    similarityScore: json["similarityScore"] != null
        ? (json["similarityScore"] as num).toInt()
        : null,
  );

  Map<String, dynamic> toJson() => {
    "time": time.toIso8601String(),
    "location": location?.toJson(),
    "photo": photo?.toJson(),
    if (similarityScore != null) "similarityScore": similarityScore,
  };
}

class CheckOut {
  DateTime time;
  Location? location;

  CheckOut({required this.time, this.location});

  factory CheckOut.fromJson(Map<String, dynamic> json) => CheckOut(
    time: DateTime.parse(json["time"]).toLocal(),
    location: json["location"] != null
        ? Location.fromJson(json["location"])
        : null,
  );

  Map<String, dynamic> toJson() => {
    "time": time.toIso8601String(),
    "location": location?.toJson(),
  };
}

class Location {
  double latitude;
  double longitude;

  Location({required this.latitude, required this.longitude});

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    latitude: (json["latitude"] as num? ?? 0).toDouble(),
    longitude: (json["longitude"] as num? ?? 0).toDouble(),
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

  Photo({required this.url, required this.publicId, required this.capturedAt});

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
    url: json["url"] as String? ?? '',
    publicId: json["publicId"] as String? ?? '',
    capturedAt: json["capturedAt"] != null
        ? DateTime.parse(json["capturedAt"] as String)
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    "url": url,
    "publicId": publicId,
    "capturedAt": capturedAt.toIso8601String(),
  };
}
