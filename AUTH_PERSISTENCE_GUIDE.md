# Authentication Persistence Guide

## Overview
The HRMS app now includes **persistent login** functionality. Once an admin (or any user) logs in, they will remain logged in even after closing and reopening the app until they explicitly log out.

## How It Works

### 1. Login Flow
When a user logs in:
```
1. Enter email and password
2. Submit login request
3. Server returns token + user info
4. App SAVES token and user info to device storage (SharedPreferences)
5. App navigates to Dashboard
```

### 2. App Restart Flow
When the app is opened/reopened:
```
1. AuthCheckScreen loads (shows loading screen)
2. Checks if token exists in device storage
3. If token exists:
   a. Tries to validate token by fetching user profile
   b. If profile fetch succeeds → Navigate to Dashboard
   c. If profile fetch fails → Use cached data to navigate to Dashboard
4. If no token exists → Show Login Screen
```

### 3. Logout Flow
When a user clicks logout:
```
1. App calls logout API to invalidate token on server
2. App deletes all stored data (token, user info) from device
3. Shows Login Screen
```

## What's Stored

The app stores the following data on the device using SharedPreferences:
- `auth_token` - JWT token for API authentication
- `user_id` - User's unique ID
- `user_email` - User's email address
- `user_name` - User's full name
- `user_role` - User role (admin, employee, hr)
- `last_login_time` - Timestamp of last successful login

## Technical Changes

### 1. TokenStorageService Improvements
- Added debugging logs for troubleshooting
- Added error handling with try-catch blocks
- Added fallback mechanisms
- Validates data before saving

### 2. AuthCheckScreen Improvements
- Added timeout mechanism (10 seconds max for profile fetch)
- Added fallback navigation if profile fetch fails but token exists
- Added detailed debug logging
- Uses cached user data if API is slow/unavailable

### 3. LoginScreen Improvements
- Now **waits** for token to be saved before navigating
- Added better error handling
- Shows user-friendly error messages
- Debug logging for troubleshooting

## Troubleshooting

### Issue: User has to login every time app opens

**Common Causes:**
1. Token is not being saved properly
2. Storage permissions are not granted
3. Device storage is full

**Solution:**
1. Check device storage space
2. Grant storage permissions to the app
3. Check debug logs by running: `flutter logs`
4. Look for messages starting with ✓ or ✗

### Issue: Login succeeds but gets redirected to login screen

**Common Causes:**
1. Network connectivity issue
2. Server is returning invalid token
3. Token expiration

**Solution:**
1. Check internet connection
2. Check server logs for errors
3. Try logging out and logging back in

### Issue: After login, still see login screen

**Common Causes:**
1. Profile API endpoint is slow/unavailable
2. Token format is incorrect
3. API authentication issue

**Solution:**
- The app should now handle this with the new fallback mechanism
- Even if profile fetch fails, you should be taken to dashboard
- Check device logs for error messages

## Debug Logs

When developing/troubleshooting, watch for these log messages:

**Successful Login:**
```
✓ TokenStorageService: Login data saved successfully
✓ TokenStorageService: Token: <token_preview>...
✓ TokenStorageService: User: <email>
✓ Login Screen: Token and user data saved successfully
✓ AuthCheckScreen: Profile valid, navigating to dashboard
```

**Persistent Login:**
```
✓ TokenStorageService: isLoggedIn = true
✓ TokenStorageService: Token retrieved successfully
✓ AuthCheckScreen: Starting auth check...
✓ AuthCheckScreen: Fetching profile with token...
```

**Fallback Navigation:**
```
⚠ AuthCheckScreen: Profile fetch failed, using cached data
⚠ AuthCheckScreen: Using fallback navigation due to profile error
```

## For Admins

### Important Notes:
1. **First Login**: You will be asked for email and password. Be sure to enter correct credentials.
2. **Persistent Session**: After first login, your session persists until you logout.
3. **Logout Button**: Located in the sidebar menu - click to logout.
4. **If Forced to Re-login**: This indicates either:
   - Your token expired
   - Your account was locked
   - You were logged out by an admin
   - Storage issue on device

### Best Practices:
- Log out when using shared devices
- Clear app data from device storage if experiencing issues
- Keep app updated for security patches
- Don't share your login credentials

## For Developers

### Testing Persistent Login:
1. Login with test credentials
2. Close app completely (swipe out of recent apps)
3. Reopen app
4. Should go directly to Dashboard without login

### Testing Logout:
1. Click logout button in sidebar
2. Close and reopen app
3. Should show Login Screen

### Debugging:
```bash
# View real-time logs
flutter logs

# Look for auth-related logs
flutter logs | grep -i "auth\|token\|login"

# Run on physical device for accurate behavior
flutter run -d <device_id>
```

## Security Considerations

1. **Tokens stored locally** are vulnerable if device is compromised
2. **Enable device lock** (PIN/biometric) for additional security
3. **Tokens expire** after server-configured time period
4. **Clear app data** uninstalls the app and removes all stored tokens
5. **Logout** immediately when done, especially on shared devices

## Configuration

### Token Expiration
- Server-side: Configure in backend (.env file)
- Default: Typically 7-30 days
- After expiration: User will see login screen and must re-login

### Profile Fetch Timeout
- Current value: 10 seconds
- Location: `lib/screen/auth_check_screen.dart`
- To change: Modify the Duration in `_checkAuthStatus()` method

## Support

If users are still being asked to login repeatedly:
1. Check device storage
2. Check internet connectivity
3. Review server logs
4. Collect debug logs with `flutter logs`
5. Contact support with error messages
