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
}
