import 'dart:convert';

AuthLoginResponse authLoginResponseFromJson(String str) =>
    AuthLoginResponse.fromJson(json.decode(str));
String authLoginResponseToJson(AuthLoginResponse data) =>
    json.encode(data.toJson());

class AuthLoginResponse {
  final bool success;
  final String token;
  final AuthUser user;
  final LoginLocation? loginLocation;

  AuthLoginResponse({
    required this.success,
    required this.token,
    required this.user,
    this.loginLocation,
  });

  factory AuthLoginResponse.fromJson(Map<String, dynamic> json) =>
      AuthLoginResponse(
        success: json["success"] == true,
        token: json["token"] ?? "",
        user: AuthUser.fromJson(json["user"] as Map<String, dynamic>),
        loginLocation: json["loginLocation"] != null
            ? LoginLocation.fromJson(
                json["loginLocation"] as Map<String, dynamic>,
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "token": token,
    "user": user.toJson(),
    "loginLocation": loginLocation?.toJson(),
  };
}

class LoginLocation {
  final String? ipAddress;
  final String? address;
  final String? city;
  final String? country;
  final double? latitude;
  final double? longitude;

  LoginLocation({
    this.ipAddress,
    this.address,
    this.city,
    this.country,
    this.latitude,
    this.longitude,
  });

  factory LoginLocation.fromJson(Map<String, dynamic> json) => LoginLocation(
    ipAddress: json["ipAddress"] as String?,
    address: json["address"] as String?,
    city: json["city"] as String?,
    country: json["country"] as String?,
    latitude: (json["latitude"] as num?)?.toDouble(),
    longitude: (json["longitude"] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "ipAddress": ipAddress,
    "address": address,
    "city": city,
    "country": country,
    "latitude": latitude,
    "longitude": longitude,
  };
}

class AuthUser {
  final String id;
  final String employeeId;
  final String name;
  final String email;
  final String role;
  final String? department;
  final String? position;
  final dynamic profilePhoto;
  final dynamic company;
  final AuthCurrentLocation? currentLocation;

  AuthUser({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.role,
    this.department,
    this.position,
    this.profilePhoto,
    this.company,
    this.currentLocation,
  });

  /// Extract display URL from profilePhoto (String, {url,publicId} Map, or null).
  String get profilePhotoUrl {
    if (profilePhoto is String) return profilePhoto as String;
    if (profilePhoto is Map<String, dynamic>) {
      return (profilePhoto as Map<String, dynamic>)['url'] as String? ?? '';
    }
    return '';
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json["id"] as String? ?? json["_id"] as String? ?? "",
    employeeId: json["employeeId"] as String? ?? "",
    name: json["name"] as String? ?? "",
    email: json["email"] as String? ?? "",
    role: json["role"] as String? ?? "",
    department: json["department"] as String?,
    position: json["position"] as String?,
    profilePhoto: json["profilePhoto"],
    company: json["company"],
    currentLocation: json["currentLocation"] != null
        ? AuthCurrentLocation.fromJson(
            json["currentLocation"] as Map<String, dynamic>,
          )
        : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "employeeId": employeeId,
    "name": name,
    "email": email,
    "role": role,
    "department": department,
    "position": position,
    "profilePhoto": profilePhoto,
    "company": company,
    "currentLocation": currentLocation?.toJson(),
  };
}

class AuthCurrentLocation {
  final double? latitude;
  final double? longitude;
  final String? address;
  final DateTime? lastUpdated;

  AuthCurrentLocation({
    this.latitude,
    this.longitude,
    this.address,
    this.lastUpdated,
  });

  factory AuthCurrentLocation.fromJson(Map<String, dynamic> json) =>
      AuthCurrentLocation(
        latitude: (json["latitude"] as num?)?.toDouble(),
        longitude: (json["longitude"] as num?)?.toDouble(),
        address: json["address"] as String?,
        lastUpdated: json["lastUpdated"] != null
            ? DateTime.parse(json["lastUpdated"] as String).toLocal()
            : null,
      );

  Map<String, dynamic> toJson() => {
    "latitude": latitude,
    "longitude": longitude,
    "address": address,
    "lastUpdated": lastUpdated?.toIso8601String(),
  };
}
