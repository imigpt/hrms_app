// LOCATION UPDATE API INTEGRATION USAGE GUIDE
// ===========================================
//
// This file documents how to use the location update functionality
//
// 1. MODEL: update_location_model.dart
//    - Defines UpdateLocation and CurrentLocation classes
//    - Parses API response with latitude, longitude, address, and timestamp
//
// 2. SERVICE: auth_service.dart
//    - Added updateLocation() method to AuthService
//    - Endpoint: POST /api/auth/update-location
//    - Requires: token, latitude, longitude
//    - Returns: UpdateLocation with address from reverse geocoding
//
// 3. HELPER SERVICE: location_update_service.dart
//    - LocationUpdateService class with helper methods:
//      * updateCurrentLocation() - Gets device location and updates server
//      * updateLocationWithCoordinates() - Manual location update
//
// 4. MIXIN: location_update_mixin.dart
//    - Add to any StatefulWidget for easy location updates
//    - Provides:
//      * updateLocationWithFeedback() - Updates with snackbar feedback
//      * updateLocationSilently() - Updates without UI
//      * buildLocationUpdateButton() - Pre-built update button widget
//
// 5. EXAMPLE SCREEN: location_settings_screen.dart
//    - Complete example showing all features
//    - Demonstrates both mixin usage and direct service calls
//
// QUICK START EXAMPLES:
// =====================
//
// Example 1: Simple location update in any screen
// ------------------------------------------------
// import '../services/location_update_service.dart';
//
// final locationService = LocationUpdateService();
// final result = await locationService.updateCurrentLocation();
// if (result != null && result.success) {
//   print('Location: ${result.currentLocation.address}');
// }
//
//
// Example 2: Using the mixin in a StatefulWidget
// -----------------------------------------------
// class MyScreen extends StatefulWidget {
//   const MyScreen({super.key});
//   @override
//   State<MyScreen> createState() => _MyScreenState();
// }
//
// class _MyScreenState extends State<MyScreen> with LocationUpdateMixin {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           // Option 1: Use pre-built button
//           buildLocationUpdateButton(),
//
//           // Option 2: Custom button
//           ElevatedButton(
//             onPressed: () => updateLocationWithFeedback(context),
//             child: Text('Update Location'),
//           ),
//
//           // Option 3: Silent update (no UI feedback)
//           ElevatedButton(
//             onPressed: () async {
//               bool success = await updateLocationSilently();
//               print('Update success: $success');
//             },
//             child: Text('Silent Update'),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
//
// Example 3: Direct API call through AuthService
// -----------------------------------------------
// import '../services/auth_service.dart';
// import '../services/token_storage_service.dart';
//
// final authService = AuthService();
// final token = await TokenStorageService().getToken();
//
// final result = await authService.updateLocation(
//   token: token!,
//   latitude: 28.6139,
//   longitude: 77.209,
// );
//
// print('Address: ${result.currentLocation.address}');
//
//
// Example 4: Automatic location updates
// --------------------------------------
// // Add to initState or didChangeDependencies
// Timer.periodic(Duration(minutes: 30), (timer) async {
//   final service = LocationUpdateService();
//   await service.updateCurrentLocation();
// });
//
//
// API RESPONSE FORMAT:
// ====================
// {
//   "success": true,
//   "currentLocation": {
//     "latitude": 28.6139,
//     "longitude": 77.209,
//     "address": "Rajpath Area, New Delhi, India",
//     "lastUpdated": "2026-02-16T10:25:07.510Z"
//   }
// }
//
//
// PERMISSIONS REQUIRED:
// =====================
// Android (AndroidManifest.xml):
//   - ACCESS_FINE_LOCATION
//   - ACCESS_COARSE_LOCATION
//
// iOS (Info.plist):
//   - NSLocationWhenInUseUsageDescription
//   - NSLocationAlwaysUsageDescription (if background updates needed)
//
//
// ERROR HANDLING:
// ===============
// All methods handle errors gracefully:
//   - Location service disabled
//   - Permission denied
//   - Network errors
//   - API errors
//
// Check return value for null to detect failures:
//   final result = await service.updateCurrentLocation();
//   if (result == null) {
//     // Handle error
//   }
