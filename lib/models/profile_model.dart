import 'dart:convert';
import 'auth_login_model.dart';

ProfileResponse profileResponseFromJson(String str) =>
    ProfileResponse.fromJson(json.decode(str));
String profileResponseToJson(ProfileResponse data) =>
    json.encode(data.toJson());

class ProfileResponse {
  final bool success;
  final ProfileUser user;

  ProfileResponse({
    required this.success,
    required this.user,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) => ProfileResponse(
        success: json["success"] == true,
        user: ProfileUser.fromJson(json["user"] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "user": user.toJson(),
      };
}

class ProfileUser {
  final String id;
  final String employeeId;
  final String name;
  final String email;
  final String phone;
  final DateTime? dateOfBirth;
  final String address;
  final String role;
  final String department;
  final String position;
  final DateTime? joinDate;
  final String status;
  final dynamic profilePhoto;
  final LeaveBalance? leaveBalance;

  /// Extract the display URL from profilePhoto.
  /// Backend can return String, {url, publicId} Map, or null.
  String get profilePhotoUrl {
    if (profilePhoto is String) return profilePhoto as String;
    if (profilePhoto is Map<String, dynamic>) {
      return (profilePhoto as Map<String, dynamic>)['url'] as String? ?? '';
    }
    return '';
  }

  /// Static helper for use outside model instances.
  static String extractPhotoUrl(dynamic raw) {
    if (raw is String) return raw;
    if (raw is Map<String, dynamic>) return raw['url'] as String? ?? '';
    return '';
  }

  ProfileUser({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.address,
    required this.role,
    required this.department,
    required this.position,
    required this.joinDate,
    required this.status,
    required this.profilePhoto,
    required this.leaveBalance,
  });

  factory ProfileUser.fromJson(Map<String, dynamic> json) => ProfileUser(
        id: json["_id"] ?? json["id"] ?? "",
        employeeId: json["employeeId"] ?? "",
        name: json["name"] ?? "",
        email: json["email"] ?? "",
        phone: json["phone"] ?? "",
        dateOfBirth: _parseDate(json["dateOfBirth"]),
        address: json["address"] ?? "",
        role: json["role"] ?? "",
        department: json["department"] ?? "",
        position: json["position"] ?? "",
        joinDate: _parseDate(json["joinDate"]),
        status: json["status"] ?? "",
        profilePhoto: json["profilePhoto"],
        leaveBalance: json["leaveBalance"] == null
            ? null
            : LeaveBalance.fromJson(json["leaveBalance"]
                as Map<String, dynamic>),
      );

  factory ProfileUser.fromAuth(AuthUser user) => ProfileUser(
        id: user.id,
        employeeId: user.employeeId,
        name: user.name,
        email: user.email,
        phone: "",
        dateOfBirth: null,
        address: "",
        role: user.role,
        department: user.department ?? "",
        position: user.position ?? "",
        joinDate: null,
        status: "",
        profilePhoto: user.profilePhoto,
        leaveBalance: null,
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "employeeId": employeeId,
        "name": name,
        "email": email,
        "phone": phone,
        "dateOfBirth": dateOfBirth?.toIso8601String(),
        "address": address,
        "role": role,
        "department": department,
        "position": position,
        "joinDate": joinDate?.toIso8601String(),
        "status": status,
        "profilePhoto": profilePhoto,
        "leaveBalance": leaveBalance?.toJson(),
      };
}

class LeaveBalance {
  final int annual;
  final int sick;
  final int casual;
  final int maternity;
  final int paternity;
  final int unpaid;

  LeaveBalance({
    required this.annual,
    required this.sick,
    required this.casual,
    required this.maternity,
    required this.paternity,
    required this.unpaid,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) => LeaveBalance(
        annual: json["annual"] ?? 0,
        sick: json["sick"] ?? 0,
        casual: json["casual"] ?? 0,
        maternity: json["maternity"] ?? 0,
        paternity: json["paternity"] ?? 0,
        unpaid: json["unpaid"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "annual": annual,
        "sick": sick,
        "casual": casual,
        "maternity": maternity,
        "paternity": paternity,
        "unpaid": unpaid,
      };
}

DateTime? _parseDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
