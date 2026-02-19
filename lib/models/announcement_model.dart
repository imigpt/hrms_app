import 'dart:convert';

AnnouncementResponse announcementResponseFromJson(String str) =>
    AnnouncementResponse.fromJson(json.decode(str));

String announcementResponseToJson(AnnouncementResponse data) =>
    json.encode(data.toJson());

class AnnouncementResponse {
  bool success;
  int count;
  List<Announcement> data;

  AnnouncementResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory AnnouncementResponse.fromJson(Map<String, dynamic> json) =>
      AnnouncementResponse(
        success: json["success"] ?? false,
        count: json["count"] ?? 0,
        data: json["data"] != null
            ? List<Announcement>.from(
                json["data"].map((x) => Announcement.fromJson(x)))
            : [],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "count": count,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}

class Announcement {
  String id;
  String title;
  String content;
  CreatedBy? createdBy;
  dynamic company;
  String priority;
  /// Optional: if set, announcement targets only this department
  String? targetDepartment;
  /// Optional: announcement expiry date
  DateTime? expiryDate;
  List<dynamic> readBy;
  bool isActive;
  List<dynamic> attachments;
  DateTime createdAt;
  DateTime updatedAt;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    this.createdBy,
    this.company,
    required this.priority,
    this.targetDepartment,
    this.expiryDate,
    required this.readBy,
    required this.isActive,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json["_id"] ?? "",
        title: json["title"] ?? "",
        content: json["content"] ?? "",
        createdBy: json["createdBy"] != null
            ? CreatedBy.fromJson(json["createdBy"])
            : null,
        company: json["company"],
        priority: json["priority"] ?? "low",
        targetDepartment: json["targetDepartment"],
        expiryDate: json["expiryDate"] != null
            ? DateTime.tryParse(json["expiryDate"])
            : null,
        readBy: json["readBy"] != null
            ? List<dynamic>.from(json["readBy"].map((x) => x))
            : [],
        isActive: json["isActive"] ?? true,
        attachments: json["attachments"] != null
            ? List<dynamic>.from(json["attachments"].map((x) => x))
            : [],
        createdAt: json["createdAt"] != null
            ? DateTime.parse(json["createdAt"])
            : DateTime.now(),
        updatedAt: json["updatedAt"] != null
            ? DateTime.parse(json["updatedAt"])
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "title": title,
        "content": content,
        "createdBy": createdBy?.toJson(),
        "company": company,
        "priority": priority,
        if (targetDepartment != null) "targetDepartment": targetDepartment,
        if (expiryDate != null) "expiryDate": expiryDate!.toIso8601String(),
        "readBy": List<dynamic>.from(readBy.map((x) => x)),
        "isActive": isActive,
        "attachments": List<dynamic>.from(attachments.map((x) => x)),
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
      };

  // Helper: whether this announcement has expired
  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  // Helper method to get display type based on priority
  String get displayType {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'Urgent';
      case 'medium':
        return 'Important';
      case 'low':
      default:
        return 'Info';
    }
  }
}

class CreatedBy {
  String id;
  String name;
  String email;
  String position;

  CreatedBy({
    required this.id,
    required this.name,
    required this.email,
    this.position = '',
  });

  factory CreatedBy.fromJson(Map<String, dynamic> json) => CreatedBy(
        id: json["_id"] ?? "",
        name: json["name"] ?? "",
        email: json["email"] ?? "",
        position: json["position"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "name": name,
        "email": email,
        "position": position,
      };
}
