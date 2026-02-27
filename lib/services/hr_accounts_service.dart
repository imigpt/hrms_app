import 'dart:convert';
import 'package:http/http.dart' as http;

class HRAccountsService {
  static const String baseUrl = 'https://hrms-backend-zzzc.onrender.com/api';

  /// Fetch all HR accounts
  static Future<Map<String, dynamic>> getHRAccounts(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/hr-accounts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else {
        throw Exception('Failed to fetch HR accounts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching HR accounts: ${e.toString()}');
    }
  }

  /// Fetch specific HR account details
  static Future<Map<String, dynamic>> getHRAccountDetails(String token, String hrId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/hr/$hrId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        throw Exception('HR account not found');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else {
        throw Exception('Failed to fetch HR details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching HR details: ${e.toString()}');
    }
  }

  /// Reset HR account password
  static Future<Map<String, dynamic>> resetHRPassword(String token, String hrId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/hr/$hrId/reset-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        throw Exception('HR account not found');
      } else if (response.statusCode == 400) {
        throw Exception('Invalid HR account');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else {
        throw Exception('Failed to reset password: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error resetting password: ${e.toString()}');
    }
  }

  /// Create new HR account (registration with admin/hr role)
  static Future<Map<String, dynamic>> createHRAccount(
    String token, {
    required String name,
    required String email,
    required String password,
    String? department,
    String? position,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/register'),
      );

      // Add auth headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['role'] = 'hr'; // Creating HR account

      if (department != null && department.isNotEmpty) {
        request.fields['department'] = department;
      }
      if (position != null && position.isNotEmpty) {
        request.fields['position'] = position;
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Invalid account data');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else {
        throw Exception('Failed to create HR account: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating HR account: ${e.toString()}');
    }
  }
}
