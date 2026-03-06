// To parse this JSON data, do
//
//     final updateLocation = updateLocationFromJson(jsonString);

import 'dart:convert';

UpdateLocation updateLocationFromJson(String str) =>
    UpdateLocation.fromJson(json.decode(str));

String updateLocationToJson(UpdateLocation data) => json.encode(data.toJson());

class UpdateLocation {
  bool success;
  CurrentLocation currentLocation;

  UpdateLocation({required this.success, required this.currentLocation});

  factory UpdateLocation.fromJson(Map<String, dynamic> json) => UpdateLocation(
    success: json["success"],
    currentLocation: CurrentLocation.fromJson(json["currentLocation"]),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "currentLocation": currentLocation.toJson(),
  };
}

class CurrentLocation {
  double latitude;
  double longitude;
  String address;
  DateTime lastUpdated;

  CurrentLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.lastUpdated,
  });

  factory CurrentLocation.fromJson(Map<String, dynamic> json) =>
      CurrentLocation(
        latitude: (json["latitude"] as num).toDouble(),
        longitude: (json["longitude"] as num).toDouble(),
        address: json["address"] ?? '',
        lastUpdated: DateTime.parse(json["lastUpdated"]),
      );

  Map<String, dynamic> toJson() => {
    "latitude": latitude,
    "longitude": longitude,
    "address": address,
    "lastUpdated": lastUpdated.toIso8601String(),
  };
}
