# Office Location Radius Validation - Implementation Summary

## Overview
This document describes the implementation of the office location radius validation feature for the HRMS app's Check-In and Check-Out functionality.

## Feature Requirements
- **Office Location:** Latitude: 26.816210, Longitude: 75.845435
- **Validation Radius:** 50 meters
- **Location Display:**
  - Within 50m radius: "Main Building"
  - Outside radius: Actual address or "Outside Office Location"
- **Applies to:** Both Check-In and Check-Out operations

## Implementation Details

### 1. New Service - LocationUtilityService
**File:** `lib/services/location_utility_service.dart`

**Key Features:**
- Haversine formula distance calculation for accurate GPS distance measurement
- Office coordinates and radius constants
- `isWithinOfficeRadius()` - Checks if user is within 50m of office
- `getLocationName()` - Returns location name based on proximity
  - Returns "Main Building" if within radius
  - Returns actual address (via reverse geocoding) if outside
  - Falls back to "Outside Office Location" if geocoding fails
- Distance formatting utility method

**Key Methods:**
```dart
// Calculate distance between two points (Haversine formula)
static double calculateDistance({
  required double userLatitude,
  required double userLongitude,
  required double officeLatitude,
  required double officeLongitude,
})

// Check if user is within office radius
static bool isWithinOfficeRadius({
  required double userLatitude,
  required double userLongitude,
})

// Get location name with radius validation
static Future<String> getLocationName({
  required double userLatitude,
  required double userLongitude,
})
```

### 2. Camera Screen (Check-In Flow)
**File:** `lib/screen/camera_screen.dart`

**Changes Made:**
1. Added import for `LocationUtilityService`
2. Updated `_fetchLocationAndAddress()` method:
   - Now calls `LocationUtilityService.getLocationName()` instead of manual reverse geocoding
   - Validates office radius automatically
   - Returns "Main Building" for users within 50m radius
   - Returns actual address or "Outside Office Location" for users outside

3. Enhanced `_confirmCheckIn()` method:
   - Added office radius validation logging
   - Shows location name being used
   - Added debug prints for radius and location information

**Validation Flow:**
```
User takes photo → Location captured (GPS) → LocationUtilityService validates radius
→ Location name determined → API called with location data → Check-In recorded
```

### 3. Attendance Screen (Check-Out Flow)
**File:** `lib/screen/attendance_screen.dart`

**Changes Made:**
1. Added import for `LocationUtilityService`
2. Updated `_handleCheckOut()` method:
   - Replaces manual reverse geocoding with `LocationUtilityService.getLocationName()`
   - Validates office radius
   - Sets location based on radius validation
   - Enhanced logging with office validation details

**Validation Flow:**
```
Check-Out button clicked → Location permission validated → GPS location captured
→ LocationUtilityService validates radius → Location name determined
→ API called with location data → Check-Out recorded
```

### 4. Attendance Service
**File:** `lib/services/attendance_service.dart`

**Changes Made:**
1. Enhanced logging in `checkIn()` method
2. Enhanced logging in `checkOut()` method
3. Added comments noting that LocationUtilityService validation is done on client-side

## Distance Calculation - Haversine Formula

The implementation uses the Haversine formula to accurately calculate the great-circle distance between two geographic points:

```
a = sin²(Δφ/2) + cos φ1 ⋅ cos φ2 ⋅ sin²(Δλ/2)
c = 2 ⋅ atan2( √a, √(1−a) )
d = R ⋅ c
```

Where:
- φ is latitude, λ is longitude (in radians)
- R is Earth's radius (6,371,000 meters)
- Δφ and Δλ are differences in latitude and longitude

**Accuracy:** Haversine formula provides accuracy to within 0.5% for Earth distances.

## Expected Behavior

### Check-In Scenario
1. User opens camera to check in
2. Photo is captured
3. GPS location is obtained
4. Distance from office is calculated
5. If distance ≤ 50m: Location name = "Main Building"
6. If distance > 50m: Location name = Actual address (e.g., "Sector 5, Jaipur, Rajasthan") or "Outside Office Location"
7. Location name is stored with check-in record

### Check-Out Scenario
1. User clicks check-out button
2. Location permission is validated
3. GPS location is obtained
4. Distance from office is calculated
5. If distance ≤ 50m: Location name = "Main Building"
6. If distance > 50m: Location name = Actual address or "Outside Office Location"
7. Location name is stored with check-out record

## Debug Logging

The implementation includes comprehensive debug logging:

**Check-In Logging:**
```
📸 [CHECK-IN LOCATION] Getting current location...
✅ [CHECK-IN LOCATION] Location captured: [lat], [long]
📍 [CHECK-IN LOCATION] Validating office radius and getting location name...
✅ [CHECK-IN LOCATION] Location name determined: [location name]
🏢 [CHECK-IN] Within office radius: [true/false]
📝 [CHECK-IN] Location name: [location name]
```

**Check-Out Logging:**
```
📡 [CHECK-OUT] Requesting GPS location (HIGH accuracy)...
✅ [CHECK-OUT] Location captured successfully!
📍 [CHECK-OUT] Latitude: [lat]
📍 [CHECK-OUT] Longitude: [long]
📍 [CHECK-OUT] Validating office radius and getting location name...
🏢 [CHECK-OUT] Within office radius: [true/false]
📝 [CHECK-OUT] Location name: [location name]
```

## Testing Recommendations

### Test Case 1: Check-In Within Office
- Location: Within 50m of office (26.816210, 75.845435)
- Expected: Shows "Main Building"

### Test Case 2: Check-In Outside Office
- Location: > 50m from office
- Expected: Shows actual address or "Outside Office Location"

### Test Case 3: Check-Out Within Office
- Already checked in
- Location: Within 50m of office
- Expected: Shows "Main Building"

### Test Case 4: Check-Out Outside Office
- Already checked in
- Location: > 50m from office
- Expected: Shows actual address or "Outside Office Location"

### Test Case 5: Location Services Disabled
- GPS disabled on device
- Expected: Shows error message, prevents check-in/check-out

### Test Case 6: Permission Denied
- Location permission not granted
- Expected: Shows permission dialog, prevents check-in/check-out

## API Integration

The implementation sends GPS coordinates to the backend API:
- **Check-In API:** `POST /attendance/check-in` with latitude and longitude
- **Check-Out API:** `POST /attendance/check-out` with latitude and longitude

The backend receives the raw coordinates and can optionally validate location on the server side as well.

## Location Privacy Notes

- GPS coordinates are collected and transmitted to the backend
- Location names are determined client-side using reverse geocoding
- Reverse geocoding cache usage is recommended for performance
- Consider implementing location data retention policies

## Future Enhancements

1. **Location History:** Track multiple office locations
2. **Dynamic Radius:** Configure radius per location
3. **Geofencing:** Use platform-specific geofencing for background monitoring
4. **Location Sharing:** Optional real-time location tracking for managers
5. **Offline Mode:** Cache location validation for offline scenarios
6. **Performance:** Optimize reverse geocoding with caching

## Files Modified

1. **New File:**
   - `lib/services/location_utility_service.dart` - Location validation service

2. **Modified Files:**
   - `lib/screen/camera_screen.dart` - Check-in location validation
   - `lib/screen/attendance_screen.dart` - Check-out location validation
   - `lib/services/attendance_service.dart` - Enhanced logging

## Dependencies Used

- `geolocator: ^10.1.0` - GPS location access
- `geocoding: ^3.0.0` - Reverse geocoding (address lookup)
- `permission_handler: ^11.0.0` - Location permission handling
- `dart:math` - Haversine formula calculations

All dependencies were already present in the project.
