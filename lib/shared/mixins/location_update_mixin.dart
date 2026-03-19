// lib/utils/location_update_mixin.dart

import 'package:flutter/material.dart';
import 'package:hrms_app/shared/services/device/location_update_service.dart';

/// Mixin to add location update functionality to any widget
/// Usage: class MyScreen extends StatefulWidget with LocationUpdateMixin
mixin LocationUpdateMixin<T extends StatefulWidget> on State<T> {
  final LocationUpdateService _locationUpdateService = LocationUpdateService();
  bool _isUpdatingLocation = false;

  /// Update current location and show snackbar with result
  Future<void> updateLocationWithFeedback(BuildContext context) async {
    if (_isUpdatingLocation) return;

    setState(() {
      _isUpdatingLocation = true;
    });

    try {
      final result = await _locationUpdateService.updateCurrentLocation();

      if (!mounted) return;

      if (result != null && result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Location updated successfully',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  result.currentLocation.address,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update location'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      String errorMessage = e.toString();
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.replaceFirst('Exception:', '').trim();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingLocation = false;
        });
      }
    }
  }

  /// Update location silently without UI feedback
  /// Returns true if successful, false otherwise
  Future<bool> updateLocationSilently() async {
    try {
      final result = await _locationUpdateService.updateCurrentLocation();
      return result != null && result.success;
    } catch (e) {
      print('Silent location update failed: $e');
      return false;
    }
  }

  /// Get current location update status
  bool get isUpdatingLocation => _isUpdatingLocation;

  /// Build a location update button
  Widget buildLocationUpdateButton({
    String label = 'Update Location',
    IconData icon = Icons.my_location,
  }) {
    return ElevatedButton.icon(
      onPressed: _isUpdatingLocation
          ? null
          : () => updateLocationWithFeedback(context),
      icon: _isUpdatingLocation
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 18),
      label: Text(
        _isUpdatingLocation ? 'Updating...' : label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
