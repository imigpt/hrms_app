# Office Location Validation - Usage Guide & Test Scenarios

## Quick Start

The office location radius validation feature is now automatically integrated into the Check-In and Check-Out flows. No additional configuration is required.

### Office Configuration
- **Latitude:** 26.816210
- **Longitude:** 75.845435
- **Radius:** 50 meters
- **Location Name:** "Main Building" (when within radius)

To modify these values, edit [LocationUtilityService](lib/services/location_utility_service.dart):

```dart
class LocationUtilityService {
  static const double OFFICE_LATITUDE = 26.816210;
  static const double OFFICE_LONGITUDE = 75.845435;
  static const double OFFICE_RADIUS_METERS = 50.0;
}
```

## Feature Workflow

### Check-In Flow with Location Validation
```
1. User opens Attendance Screen
2. Clicks Check-In button
3. Camera Screen opens
4. User takes photo
5. System gets GPS location
6. LocationUtilityService calculates distance from office
7. If within 50m → Location = "Main Building"
8. If > 50m → Location = Actual address or "Outside Office Location"
9. Check-in API called with photo and location
10. Attendance recorded with location name
```

### Check-Out Flow with Location Validation
```
1. User opens Attendance Screen
2. Clicks Check-Out button
3. System requests GPS location
4. LocationUtilityService calculates distance from office
5. If within 50m → Location = "Main Building"
6. If > 50m → Location = Actual address or "Outside Office Location"
7. Check-out API called with location
8. Attendance recorded with location name
```

## Distance Calculation Example

### Example 1: User Within Office (25m away)
```
User Location:  26.8165, 75.8456
Office Location: 26.8162, 75.8454
Distance: ~25 meters
Result: "Main Building"
```

### Example 2: User Outside Office (100m away)
```
User Location:  26.8170, 75.8460
Office Location: 26.8162, 75.8454
Distance: ~100 meters
Reverse Geocoding: Attempts to get address
Result: "C Block, Sector 5, Jaipur" (or "Outside Office Location" if geocoding fails)
```

### Example 3: User Far Away (2km away)
```
User Location:  26.8000, 75.8400
Office Location: 26.8162, 75.8454
Distance: ~2000 meters
Result: "Outside Office Location"
```

## Manual Testing Guide

### Test 1: Check-In Within Office Radius

**Setup:**
- Device location set to approx. 26.8162, 75.8454 (within 50m of office)
- Location services enabled
- Permission granted

**Steps:**
1. Navigate to Attendance Screen
2. Click "Check-In" button
3. Take a photo in camera
4. Verify location shows as "Main Building" in success notification

**Expected Result:**
- ✅ Check-in successful
- ✅ Location recorded as "Main Building"
- ✅ Console shows: "Within office radius: true"

---

### Test 2: Check-In Outside Office Radius

**Setup:**
- Device location set to approx. 26.8100, 75.8400 (>50m from office)
- Location services enabled
- Permission granted

**Steps:**
1. Navigate to Attendance Screen
2. Click "Check-In" button
3. Take a photo in camera
4. Verify location shows actual address in success notification

**Expected Result:**
- ✅ Check-in successful
- ✅ Location recorded as actual address
- ✅ Console shows: "Within office radius: false"
- ✅ Reverse geocoding called and address resolved

---

### Test 3: Check-Out Within Office Radius

**Setup:**
- User already checked in (within office radius)
- Device location set to within 50m of office
- Location services enabled
- Permission granted

**Steps:**
1. Navigate to Attendance Screen
2. Verify "Check-Out" button is available
3. Click "Check-Out" button
4. Wait for location to be fetched
5. Verify success notification shows location as "Main Building"

**Expected Result:**
- ✅ Check-out successful
- ✅ Location recorded as "Main Building"
- ✅ Console shows distance < 50m

---

### Test 4: Check-Out Outside Office Radius

**Setup:**
- User already checked in (within office radius)
- Device location set to > 50m from office
- Location services enabled
- Permission granted

**Steps:**
1. Navigate to Attendance Screen
2. Verify "Check-Out" button is available
3. Click "Check-Out" button
4. Wait for location to be fetched
5. Verify success notification shows actual address

**Expected Result:**
- ✅ Check-out successful
- ✅ Location recorded as actual address or "Outside Office Location"
- ✅ Console shows distance > 50m

---

### Test 5: Location Services Disabled

**Setup:**
- Device location services disabled

**Steps:**
1. Try to Check-In
2. Observe error message

**Expected Result:**
- ✅ Error: "Please enable location services in device settings to mark attendance"
- ✅ Check-in/check-out not attempted

---

### Test 6: Location Permission Denied

**Setup:**
- Location permission not granted to app
- Device location services enabled

**Steps:**
1. Try to Check-In
2. Location permission dialog appears
3. Deny permission
4. Attempt Check-In again

**Expected Result:**
- ✅ Permission dialog shown explaining why location needed
- ✅ Check-in not possible without permission
- ✅ User can grant permission via dialog

---

### Test 7: GPS Accuracy Edge Cases

**Setup:**
- Device with poor GPS signal
- Location: ~48.5m from office (within radius but near boundary)

**Steps:**
1. Check-In with this location
2. Observe location name

**Expected Result:**
- ✅ Distance calculation: ~48.5m (within 50m)
- ✅ Location: "Main Building"

---

### Test 8: Reverse Geocoding Failure

**Setup:**
- Geocoding service unavailable (offline or rate-limited)
- Check-out location: outside office radius

**Steps:**
1. Check-Out with location > 50m from office
2. Reverse geocoding fails (network error)
3. Observe location in success message

**Expected Result:**
- ✅ Check-out is still successful
- ✅ Location recorded as "Outside Office Location" (fallback)
- ✅ Console shows: "Error during reverse geocoding: [error]"

## Console Debug Output Examples

### Successful Check-In Within Office
```
📸 [CHECK-IN LOCATION] Getting current location...
✅ [CHECK-IN LOCATION] Location captured: 26.8162, 75.8454
📍 [CHECK-IN LOCATION] Validating office radius and getting location name...
📍 📍 Distance from office: 15.45m
✅ User is within office radius - returning "Main Building"
✅ [CHECK-IN LOCATION] Location name determined: Main Building
📸 [CHECK-IN] === Starting Check-In Process ===
🏢 [CHECK-IN] Within office radius: true
📝 [CHECK-IN] Location name: Main Building
```

### Successful Check-Out Outside Office
```
📸 [CHECK-OUT] Requesting GPS location (HIGH accuracy)...
✅ [CHECK-OUT] Location captured successfully!
📍 Distance from office: 125.30m
🔄 User is outside office radius, attempting reverse geocoding...
✅ Address resolved: Sector 5, Jaipur
✅ [CHECK-OUT LOCATION] Location name determined: Sector 5, Jaipur
🏢 [CHECK-OUT] Within office radius: false
📝 [CHECK-OUT] Location name: Sector 5, Jaipur
```

## Error Handling

### Common Error Scenarios

**Error 1: Location Services Disabled**
- Message: "Please enable location services to check out"
- Recovery: User enables location services in device settings

**Error 2: Permission Denied**
- Message: "Location permission denied. Please enable it in settings to mark attendance."
- Recovery: User grants permission via app settings

**Error 3: No GPS Signal**
- Message: "Could not get location. Please try again."
- Recovery: Move to location with GPS signal, retry

**Error 4: Reverse Geocoding Failed**
- Behavior: Falls back to "Outside Office Location"
- Recovery: System continues to function, address not resolved

## Performance Considerations

### Optimization Tips
1. **Caching:** Reverse geocoding results are cached by the geocoding package
2. **Timeout:** Camera screen uses 10-second timeout for location fetch
3. **Accuracy:** Check-out uses HIGH accuracy, camera check-in uses MEDIUM accuracy
4. **Battery:** GPS is disabled after location is obtained

### Expected Performance
- Initial location fetch: 2-5 seconds (depends on GPS signal)
- Reverse geocoding: 1-2 seconds (cached or offline)
- Total check-in time: 5-10 seconds
- Total check-out time: 3-7 seconds

## Troubleshooting

### Issue: Location always shows as "Outside Office Location"
**Solution:**
1. Check device GPS is enabled
2. Move closer to office if outside radius
3. Clear geocoding cache (app data)
4. Check if office coordinates are correct in LocationUtilityService

### Issue: "Main Building" not appearing
**Solution:**
1. Verify office coordinates match actual location
2. Check GPS accuracy (~25-30m typical)
3. Move to confirmed office location
4. Restart app and retry

### Issue: Check-in/Check-out hangs
**Solution:**
1. Check network connectivity (for geocoding)
2. Check GPS signal strength
3. Disable and re-enable location services
4. Restart app

### Issue: Permission dialog not appearing
**Solution:**
1. Check app permissions in device settings
2. Reset app permissions: Settings → Apps → HRMS → Permissions
3. Reinstall app if permissions corrupted

## Testing Checklist

- [ ] Check-In within office (< 50m)
- [ ] Check-In outside office (> 50m)
- [ ] Check-Out within office (< 50m)
- [ ] Check-Out outside office (> 50m)
- [ ] Location services disabled
- [ ] Permission denied
- [ ] Poor GPS signal
- [ ] Offline geocoding fallback
- [ ] Console logs appropriate validation messages
- [ ] Distance calculations are accurate (within ±5m)
- [ ] Address geocoding works for multiple locations
- [ ] Verify API receives correct location data

## API Payload Examples

### Check-In Request
```json
{
  "photo": "<binary_image_data>",
  "location": "{\"latitude\": 26.8162, \"longitude\": 75.8454}"
}
```

### Check-Out Request
```json
{
  "location": {
    "latitude": 26.8162,
    "longitude": 75.8454
  }
}
```

### Expected Response
```json
{
  "success": true,
  "message": "Checked in successfully",
  "data": {
    "checkIn": {
      "time": "2026-02-20T10:30:00Z",
      "location": {
        "latitude": 26.8162,
        "longitude": 75.8454
      }
    }
  }
}
```

## Support

For issues or questions:
1. Check console logs for error messages
2. Review debug output to understand distance calculation
3. Verify office coordinates in LocationUtilityService
4. Check device location settings
5. Ensure app has location permissions
