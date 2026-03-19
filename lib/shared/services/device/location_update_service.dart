// lib/services/location_update_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/shared/services/core/token_storage_service.dart';
import 'package:hrms_app/features/attendance/data/models/update_location_model.dart';

class LocationUpdateService {
  final AuthService _authService = AuthService();
  final TokenStorageService _tokenStorage = TokenStorageService();

  /// Update user's current location to the server
  /// Returns the UpdateLocation response or null if failed
  Future<UpdateLocation?> updateCurrentLocation() async {
    try {
      // Get stored token
      final token = await _tokenStorage.getToken();
      if (token == null) {
        print('No token found. User not logged in.');
        return null;
      }

      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print(
        'Got current position: ${position.latitude}, ${position.longitude}',
      );

      // Update location on server
      final response = await _authService.updateLocation(
        token: token,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      print('Location updated successfully');
      return response;
    } catch (e) {
      print('Error updating location: $e');
      return null;
    }
  }

  /// Update location with specific coordinates
  /// Useful for testing or manual location updates
  Future<UpdateLocation?> updateLocationWithCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        print('No token found. User not logged in.');
        return null;
      }

      final response = await _authService.updateLocation(
        token: token,
        latitude: latitude,
        longitude: longitude,
      );

      return response;
    } catch (e) {
      print('Error updating location: $e');
      return null;
    }
  }
}
