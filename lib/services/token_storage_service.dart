// lib/services/token_storage_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class TokenStorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _userRoleKey = 'user_role'; // employee, admin, hr
  static const String _lastLoginTimeKey = 'last_login_time';
  static const String _loginAttemptKey = 'login_attempt_count';

  // Save token and user info after login
  Future<void> saveLoginData({
    required String token,
    required String userId,
    required String email,
    String? name,
    String? role, // 'employee', 'admin', or 'hr'
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Verify inputs are not empty
      if (token.isEmpty || userId.isEmpty || email.isEmpty) {
        debugPrint('TokenStorageService: Cannot save empty data');
        return;
      }

      // Save all login data
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_userEmailKey, email);
      await prefs.setString(
        _lastLoginTimeKey,
        DateTime.now().toIso8601String(),
      );

      if (name != null && name.isNotEmpty) {
        await prefs.setString(_userNameKey, name);
      }
      if (role != null && role.isNotEmpty) {
        await prefs.setString(_userRoleKey, role);
      }

      // Reset login attempt counter on successful save
      await prefs.remove(_loginAttemptKey);

      debugPrint('✓ TokenStorageService: Login data saved successfully');
      debugPrint('✓ Token: ${token.substring(0, 20)}...');
      debugPrint('✓ User: $email');
    } catch (e) {
      debugPrint('✗ TokenStorageService: Error saving login data: $e');
    }
  }

  // Get stored token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token != null && token.isNotEmpty) {
        debugPrint('✓ TokenStorageService: Token retrieved successfully');
        return token;
      }
      debugPrint('⚠ TokenStorageService: No token found in storage');
      return null;
    } catch (e) {
      debugPrint('✗ TokenStorageService: Error retrieving token: $e');
      return null;
    }
  }

  // Get stored user ID
  Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);
      if (userId != null && userId.isNotEmpty) {
        debugPrint('✓ TokenStorageService: User ID retrieved: $userId');
        return userId;
      }
      return null;
    } catch (e) {
      debugPrint('✗ TokenStorageService: Error retrieving user ID: $e');
      return null;
    }
  }

  // Get stored email
  Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_userEmailKey);
      if (email != null && email.isNotEmpty) {
        debugPrint('✓ TokenStorageService: Email retrieved: $email');
        return email;
      }
      return null;
    } catch (e) {
      debugPrint('✗ TokenStorageService: Error retrieving email: $e');
      return null;
    }
  }

  // Get stored name
  Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_userNameKey);
      return name;
    } catch (e) {
      debugPrint('✗ TokenStorageService: Error retrieving name: $e');
      return null;
    }
  }

  // Get stored role (employee, admin, or hr)
  Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString(_userRoleKey);
      if (role != null && role.isNotEmpty) {
        debugPrint('✓ TokenStorageService: Role retrieved: $role');
        return role;
      }
      return null;
    } catch (e) {
      debugPrint('✗ TokenStorageService: Error retrieving role: $e');
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      final isLoggedIn = token != null && token.isNotEmpty;
      debugPrint('✓ TokenStorageService: isLoggedIn = $isLoggedIn');
      return isLoggedIn;
    } catch (e) {
      debugPrint('✗ TokenStorageService: Error checking login status: $e');
      return false;
    }
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == 'admin';
  }

  // Check if user is employee
  Future<bool> isEmployee() async {
    final role = await getUserRole();
    return role == 'employee';
  }

  // Check if user is HR
  Future<bool> isHR() async {
    final role = await getUserRole();
    return role == 'hr';
  }

  // Clear all stored data on logout
  Future<void> clearLoginData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userNameKey);
      await prefs.remove(_userRoleKey);
      await prefs.remove(_lastLoginTimeKey);
      await prefs.remove(_loginAttemptKey);
      debugPrint('✓ TokenStorageService: Login data cleared successfully');
    } catch (e) {
      debugPrint('✗ TokenStorageService: Error clearing login data: $e');
    }
  }

  // Get all login data as a map
  Future<Map<String, String?>> getLoginData() async {
    try {
      return {
        'token': await getToken(),
        'userId': await getUserId(),
        'email': await getUserEmail(),
        'name': await getUserName(),
        'role': await getUserRole(),
      };
    } catch (e) {
      debugPrint('✗ TokenStorageService: Error getting login data: $e');
      return {
        'token': null,
        'userId': null,
        'email': null,
        'name': null,
        'role': null,
      };
    }
  }

  // Get last login time
  Future<DateTime?> getLastLoginTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeStr = prefs.getString(_lastLoginTimeKey);
      if (timeStr != null) {
        return DateTime.parse(timeStr);
      }
      return null;
    } catch (e) {
      debugPrint('✗ TokenStorageService: Error getting last login time: $e');
      return null;
    }
  }
}
