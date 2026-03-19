// lib/services/auth_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:hrms_app/core/config/api_config.dart';
import 'package:hrms_app/features/auth/data/models/auth_login_model.dart';
import 'package:hrms_app/features/attendance/data/models/update_location_model.dart';

class AuthService {
  static String get _baseUrl => ApiConfig.baseUrl;

  // Create a custom HTTP client with connection timeout
  static final _httpClient = _createHttpClient();

  static http.Client _createHttpClient() {
    final client = http.Client();
    // Configure socket timeout at OS level
    HttpOverrides.global = _CustomHttpOverrides();
    return client;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Map<String, String> _headers({String? token}) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  /// Extracts `message` from an error response body, falling back to [fallback].
  String _errorMessage(http.Response res, String fallback) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (body['message'] as String?) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  /// Login with [email] OR [employeeId] plus [password].
  /// Optionally pass device GPS [latitude]/[longitude] so the server can
  /// resolve a human-readable login location instead of falling back to IP.
  /// Throws [Exception] with the server error message on failure.
  Future<AuthLoginResponse> login(
    String email,
    String password, {
    String? employeeId,
    double? latitude,
    double? longitude,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/login');

    final body = <String, dynamic>{
      'password': password,
      if (email.isNotEmpty) 'email': email,
      if (employeeId != null && employeeId.isNotEmpty) 'employeeId': employeeId,
      if (latitude != null && longitude != null)
        'location': {'latitude': latitude, 'longitude': longitude},
    };

    try {
      final response = await _httpClient
          .post(url, headers: _headers(), body: jsonEncode(body))
          .timeout(
            const Duration(seconds: 65),
            onTimeout: () => throw Exception(
              'Could not reach the server. Please check your connection and try again.',
            ),
          );

      if (response.statusCode == 200) {
        return authLoginResponseFromJson(response.body);
      }

      throw Exception(_errorMessage(response, 'Login failed'));
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<bool> logout(String token) async {
    final url = Uri.parse('$_baseUrl/auth/logout');
    try {
      final response = await _httpClient.post(
        url,
        headers: _headers(token: token),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Get current user profile ───────────────────────────────────────────────
  /// Returns the full user document from `GET /api/auth/me`.
  Future<Map<String, dynamic>> getMe(String token) async {
    final url = Uri.parse('$_baseUrl/auth/me');
    try {
      final response = await _httpClient.get(
        url,
        headers: _headers(token: token),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception(_errorMessage(response, 'Failed to fetch profile'));
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // ── Update location (PUT) ──────────────────────────────────────────────────
  /// Backend route is `PUT /api/auth/update-location`.
  Future<UpdateLocation> updateLocation({
    required String token,
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/update-location');
    try {
      final response = await _httpClient.put(
        url,
        headers: _headers(token: token),
        body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
      );
      if (response.statusCode == 200) {
        return updateLocationFromJson(response.body);
      }
      throw Exception(_errorMessage(response, 'Failed to update location'));
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // ── Admin: Get dashboard stats ─────────────────────────────────────────────
  /// Calls `GET /api/admin/dashboard`. Returns full data including stats, systemHealth, alerts.
  Future<Map<String, dynamic>> getAdminDashboardStats(String token) async {
    final url = Uri.parse('$_baseUrl/admin/dashboard');
    try {
      final response = await _httpClient
          .get(url, headers: _headers(token: token))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>? ?? {};
        return data; // Returns full data with stats, systemHealth, alerts
      }
      throw Exception(_errorMessage(response, 'Failed to fetch admin stats'));
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // ── HR: Get HR dashboard statistics ───────────────────────────────────────
  /// Calls `GET /api/hr/dashboard`. Returns HR-specific stats (totalEmployees, presentToday, pendingLeaves, activeTasks).
  Future<Map<String, dynamic>> getHRDashboardStats(String token) async {
    final url = Uri.parse('$_baseUrl/hr/dashboard');
    try {
      final response = await _httpClient
          .get(url, headers: _headers(token: token))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'];

        print('🔍 [DEBUG] getHRDashboardStats response data type: ${data.runtimeType}');
        print('   Raw data: $data');

        // Handle response format
        if (data is Map<String, dynamic>) {
          print('✅ HR Dashboard Stats received as Map');
          return data; // Returns HR-specific stats with presentToday, pendingLeaves, etc.
        } else {
          print('⚠️ HR Dashboard Stats format unexpected, returning empty');
          return {};
        }
      }
      throw Exception(_errorMessage(response, 'Failed to load HR dashboard'));
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // ── HR: Get department statistics ────────────────────────────────────────
  /// Calls `GET /api/hr/departments/stats`. Returns department count and breakdown.
  Future<Map<String, dynamic>> getHRDepartmentStats(String token) async {
    final url = Uri.parse('$_baseUrl/hr/departments/stats');
    try {
      final response = await _httpClient
          .get(url, headers: _headers(token: token))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'];

        print('🔍 [DEBUG] getHRDepartmentStats response data type: ${data.runtimeType}');
        print('   Raw data: $data');

        // Handle two response formats:
        // Format 1: Object with totalDepartments field
        if (data is Map<String, dynamic>) {
          print('✅ Format 1: Map response - contains totalDepartments');
          return data;
        }
        // Format 2: Array of departments
        else if (data is List) {
          print('✅ Format 2: List response - deriving totalDepartments from length');
          return {
            'totalDepartments': data.length,
            'departments': data,
          };
        }
        // Format 3: Empty/null
        else {
          print('⚠️ Format 3: Unknown format - returning empty map');
          return {
            'totalDepartments': 0,
            'departments': [],
          };
        }
      }
      throw Exception(_errorMessage(response, 'Failed to load department stats'));
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // ── Admin: Get recent activity ─────────────────────────────────────────────
  /// Calls `GET /api/admin/activity`. Returns the list of activity items.
  Future<List<Map<String, dynamic>>> getAdminRecentActivity(
    String token, {
    int limit = 10,
  }) async {
    final url = Uri.parse('$_baseUrl/admin/activity?limit=$limit');
    try {
      final response = await _httpClient
          .get(url, headers: _headers(token: token))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'];
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
        return [];
      }
      throw Exception(_errorMessage(response, 'Failed to fetch activity'));
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // ── Forgot password ────────────────────────────────────────────────────────
  /// Sends a 6-digit reset code to [email].
  /// Returns the server message string.
  Future<String> forgotPassword(String email) async {
    final url = Uri.parse('$_baseUrl/auth/forgot-password');
    try {
      final response = await _httpClient.post(
        url,
        headers: _headers(),
        body: jsonEncode({'email': email}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = (body['message'] as String?) ?? 'Request sent';
      if (response.statusCode == 200) return message;
      throw Exception(message);
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // ── Reset password ─────────────────────────────────────────────────────────
  /// Resets [email]'s password using the [resetToken] (6-digit code from email)
  /// and sets [newPassword]. Returns the new JWT token.
  Future<String> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/reset-password');
    try {
      final response = await _httpClient.post(
        url,
        headers: _headers(),
        body: jsonEncode({
          'email': email,
          'resetToken': resetToken,
          'newPassword': newPassword,
        }),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return (body['token'] as String?) ?? '';
      }
      throw Exception(_errorMessage(response, 'Password reset failed'));
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
}

// Custom HttpOverrides to configure socket timeout at the OS level
class _CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..connectionTimeout = const Duration(seconds: 30)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
