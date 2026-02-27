// lib/services/token_storage_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class TokenStorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _userRoleKey = 'user_role'; // employee, admin, hr

  // Save token and user info after login
  Future<void> saveLoginData({
    required String token,
    required String userId,
    required String email,
    String? name,
    String? role, // 'employee', 'admin', or 'hr'
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userEmailKey, email);
    if (name != null) {
      await prefs.setString(_userNameKey, name);
    }
    if (role != null) {
      await prefs.setString(_userRoleKey, role);
    }
  }

  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get stored user ID
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Get stored email
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // Get stored name
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  // Get stored role (employee, admin, or hr)
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userRoleKey);
  }

  // Get all login data as a map
  Future<Map<String, String?>> getLoginData() async {
    return {
      'token': await getToken(),
      'userId': await getUserId(),
      'email': await getUserEmail(),
      'name': await getUserName(),
      'role': await getUserRole(),
    };
  }
}
