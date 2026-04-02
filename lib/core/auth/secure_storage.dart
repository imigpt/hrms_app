// lib/core/auth/secure_storage.dart
// Facade for secure token and authentication data storage

import 'package:hrms_app/shared/services/core/token_storage_service.dart';

/// Secure storage for authentication tokens and user data.
/// This is a facade around TokenStorageService for backward compatibility.
class SecureStorage {
  final TokenStorageService _tokenStorageService = TokenStorageService();

  /// Get stored authentication token
  Future<String?> getToken() async {
    return await _tokenStorageService.getToken();
  }

  /// Save login data (token, user info, etc.)
  Future<void> saveLoginData({
    required String token,
    required String userId,
    required String email,
    String? name,
    String? role,
  }) async {
    return await _tokenStorageService.saveLoginData(
      token: token,
      userId: userId,
      email: email,
      name: name,
      role: role,
    );
  }

  /// Get stored user ID
  Future<String?> getUserId() async {
    return await _tokenStorageService.getUserId();
  }

  /// Get stored email
  Future<String?> getEmail() async {
    return await _tokenStorageService.getUserEmail();
  }

  /// Get stored user name
  Future<String?> getUserName() async {
    return await _tokenStorageService.getUserName();
  }

  /// Get stored user role
  Future<String?> getUserRole() async {
    return await _tokenStorageService.getUserRole();
  }

  /// Clear all stored data (logout)
  Future<void> clearAllData() async {
    return await _tokenStorageService.clearLoginData();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
