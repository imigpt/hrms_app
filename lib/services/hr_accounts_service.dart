import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class HRAccountsService {
  static const String baseUrl = 'https://hrms-backend-zzzc.onrender.com/api';

  /// Fetch all HR accounts
  static Future<Map<String, dynamic>> getHRAccounts(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/hr-accounts'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

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
  static Future<Map<String, dynamic>> getHRAccountDetails(
    String token,
    String hrId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/hr/$hrId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

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
  static Future<Map<String, dynamic>> resetHRPassword(
    String token,
    String hrId,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/hr/$hrId/reset-password'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

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

  /// Create new HR account — POST /auth/register with role=hr
  static Future<Map<String, dynamic>> createHRAccount(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final body = <String, dynamic>{...data, 'role': 'hr'};
      // Remove empty/null values to avoid ObjectId cast errors
      body.removeWhere((k, v) => v == null || v.toString().isEmpty);
      body.remove('reportingTo'); // not supported for HR role

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['message'] ??
              'Failed to create HR account: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error creating HR account: $e');
    }
  }

  /// Update HR account — PUT /users/:id
  static Future<Map<String, dynamic>> updateHRAccount(
    String token,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      // Remove empty values
      final body = Map<String, dynamic>.from(data)
        ..removeWhere((k, v) => v == null || v.toString().isEmpty);

      final response = await http
          .put(
            Uri.parse('$baseUrl/users/$id'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['message'] ??
              'Failed to update HR account: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error updating HR account: $e');
    }
  }

  /// Delete HR account — DELETE /users/:id (endpoint may not exist yet)
  static Future<Map<String, dynamic>> deleteHRAccount(
    String token,
    String id,
  ) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/users/$id'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.body.isEmpty
            ? {'success': true}
            : jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['message'] ??
              'Failed to delete HR account: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error deleting HR account: $e');
    }
  }

  /// Fetch all companies — GET /admin/companies
  static Future<List<dynamic>> getCompanies(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/companies'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return (body['data'] ?? body['companies'] ?? []) as List<dynamic>;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Update HR status — PATCH /users/:id with status field
  static Future<void> updateHRStatus(
    String token,
    String id,
    String status,
  ) async {
    await updateHRAccount(token, id, {'status': status});
  }

  /// Create HR account with optional profile photo (multipart)
  static Future<Map<String, dynamic>> createHRAccountWithPhoto(
    String token,
    Map<String, dynamic> data,
    File? photo,
  ) async {
    if (photo == null) {
      return createHRAccount(token, data);
    }
    try {
      final body = <String, dynamic>{...data, 'role': 'hr'};
      body.removeWhere((k, v) => v == null || v.toString().isEmpty);
      body.remove('reportingTo');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/register'),
      )
        ..headers.addAll({
          'Authorization': 'Bearer $token',
        });
      body.forEach((k, v) => request.fields[k] = v.toString());
      request.files.add(
        await http.MultipartFile.fromPath('profilePhoto', photo.path),
      );

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['message'] ?? 'Failed to create HR account: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error creating HR account: $e');
    }
  }

  /// Update HR account with optional profile photo (multipart)
  static Future<Map<String, dynamic>> updateHRAccountWithPhoto(
    String token,
    String id,
    Map<String, dynamic> data,
    File? photo,
  ) async {
    if (photo == null) {
      return updateHRAccount(token, id, data);
    }
    try {
      final body = Map<String, dynamic>.from(data)
        ..removeWhere((k, v) => v == null || v.toString().isEmpty);

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/users/$id'),
      )
        ..headers.addAll({
          'Authorization': 'Bearer $token',
        });
      body.forEach((k, v) => request.fields[k] = v.toString());
      request.files.add(
        await http.MultipartFile.fromPath('profilePhoto', photo.path),
      );

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['message'] ?? 'Failed to update HR account: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error updating HR account: $e');
    }
  }
}
