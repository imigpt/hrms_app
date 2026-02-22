import 'dart:math';
import 'package:geocoding/geocoding.dart';

/// Service for handling office location radius validation
/// Office Coordinates: Latitude: 26.816210, Longitude: 75.845435
/// Radius: 50 meters
class LocationUtilityService {
  // Office coordinates
  static const double OFFICE_LATITUDE = 26.816210;
  static const double OFFICE_LONGITUDE = 75.845435;
  
  // Radius in meters
  static const double OFFICE_RADIUS_METERS = 50.0;
  
  // Location names
  static const String MAIN_BUILDING = "Main Building";
  static const String OUTSIDE_OFFICE = "Outside Office Location";

  /// Calculate distance between two geographic points using Haversine formula
  /// Returns distance in meters
  static double calculateDistance({
    required double userLatitude,
    required double userLongitude,
    required double officeLatitude,
    required double officeLongitude,
  }) {
    const double earthRadiusMeters = 6371000; // Earth radius in meters

    final double dLat = _toRadians(officeLatitude - userLatitude);
    final double dLon = _toRadians(officeLongitude - userLongitude);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(userLatitude)) *
            cos(_toRadians(officeLatitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = earthRadiusMeters * c;

    return distance;
  }

  /// Check if user is within office radius
  static bool isWithinOfficeRadius({
    required double userLatitude,
    required double userLongitude,
  }) {
    final double distance = calculateDistance(
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      officeLatitude: OFFICE_LATITUDE,
      officeLongitude: OFFICE_LONGITUDE,
    );

    print('📍 📍 Distance from office: ${distance.toStringAsFixed(2)}m');
    return distance <= OFFICE_RADIUS_METERS;
  }

  /// Get location name based on proximity to office
  /// Returns "Main Building" if within 50m, otherwise returns actual address or "Outside Office Location"
  static Future<String> getLocationName({
    required double userLatitude,
    required double userLongitude,
  }) async {
    try {
      final bool isWithinRadius = isWithinOfficeRadius(
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );

      if (isWithinRadius) {
        print('✅ User is within office radius - returning "$MAIN_BUILDING"');
        return MAIN_BUILDING;
      }

      // User is outside office, try to get actual address
      print('🔄 User is outside office radius, attempting reverse geocoding...');
      String addressName = OUTSIDE_OFFICE;

      try {
        final List<Placemark> placemarks = await placemarkFromCoordinates(
          userLatitude,
          userLongitude,
        );

        if (placemarks.isNotEmpty) {
          final Placemark placemark = placemarks.first;

          // Build address string from placemark
          List<String> addressParts = [];
          if (placemark.name != null && placemark.name!.isNotEmpty) {
            addressParts.add(placemark.name!);
          }
          if (placemark.street != null && 
              placemark.street!.isNotEmpty && 
              placemark.street != placemark.name) {
            addressParts.add(placemark.street!);
          }
          if (placemark.subLocality != null && 
              placemark.subLocality!.isNotEmpty) {
            addressParts.add(placemark.subLocality!);
          }
          if (placemark.locality != null && 
              placemark.locality!.isNotEmpty) {
            addressParts.add(placemark.locality!);
          }

          // Take first 3 parts to keep it concise
          String resolvedAddress = addressParts.take(3).join(', ');
          
          if (resolvedAddress.isNotEmpty) {
            addressName = resolvedAddress;
            print('✅ Address resolved: $addressName');
          } else {
            print('⚠️ Address parts were empty, using default: $OUTSIDE_OFFICE');
          }
        } else {
          print('⚠️ No placemarks found for coordinates, using default: $OUTSIDE_OFFICE');
        }
      } catch (e) {
        print('❌ Error during reverse geocoding: $e');
        print('⚠️ Using default: $OUTSIDE_OFFICE');
      }

      return addressName;
    } catch (e) {
      print('❌ Error in getLocationName: $e');
      return OUTSIDE_OFFICE;
    }
  }

  /// Helper method to convert degrees to radians
  static double _toRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  /// Format distance for display
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)}m';
    }
    return '${(distanceInMeters / 1000).toStringAsFixed(2)}km';
  }
}
