// lib/models/auth_model.dart

import 'dart:convert';

Welcome welcomeFromJson(String str) => Welcome.fromJson(json.decode(str));
String welcomeToJson(Welcome data) => json.encode(data.toJson());

class Welcome {
    bool success;
    String token;
    User user;
    LoginLocation loginLocation;

    Welcome({
        required this.success,
        required this.token,
        required this.user,
        required this.loginLocation,
    });

    factory Welcome.fromJson(Map<String, dynamic> json) => Welcome(
        success: json["success"],
        token: json["token"],
        user: User.fromJson(json["user"]),
        loginLocation: LoginLocation.fromJson(json["loginLocation"]),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "token": token,
        "user": user.toJson(),
        "loginLocation": loginLocation.toJson(),
    };
}

class LoginLocation {
    String ipAddress;
    String address;

    LoginLocation({
        required this.ipAddress,
        required this.address,
    });

    factory LoginLocation.fromJson(Map<String, dynamic> json) => LoginLocation(
        ipAddress: json["ipAddress"],
        address: json["address"],
    );

    Map<String, dynamic> toJson() => {
        "ipAddress": ipAddress,
        "address": address,
    };
}

class User {
    String id;
    String employeeId;
    String name;
    String email;
    String role;
    String department;
    String position;
    dynamic profilePhoto;
    CurrentLocation currentLocation;

    User({
        required this.id,
        required this.employeeId,
        required this.name,
        required this.email,
        required this.role,
        required this.department,
        required this.position,
        required this.profilePhoto,
        required this.currentLocation,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        employeeId: json["employeeId"],
        name: json["name"],
        email: json["email"],
        role: json["role"],
        department: json["department"],
        position: json["position"],
        profilePhoto: json["profilePhoto"],
        currentLocation: CurrentLocation.fromJson(json["currentLocation"]),
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
        "currentLocation": currentLocation.toJson(),
    };
}

class CurrentLocation {
    CurrentLocation();
    factory CurrentLocation.fromJson(Map<String, dynamic> json) => CurrentLocation();
    Map<String, dynamic> toJson() => {};
}