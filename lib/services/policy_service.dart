import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/policy_model.dart';

/// Service for company policy API calls (employee read-only).
class PolicyService {
  static const String _baseUrl = 'https://hrms-backend-zzzc.onrender.com/api';

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ── List Policies ─────────────────────────────────────────────────────────

  /// GET /api/policies?search=...
  static Future<PolicyListResponse> getPolicies({
    required String token,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(
        '$_baseUrl/policies',
      ).replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return policyListResponseFromJson(response.body);
      }
      throw Exception(_extractError(response, 'Failed to fetch policies'));
    } catch (e) {
      print('PolicyService.getPolicies error: $e');
      rethrow;
    }
  }

  // ── Single Policy ─────────────────────────────────────────────────────────

  /// GET /api/policies/:id
  static Future<PolicyDetailResponse> getPolicyById({
    required String token,
    required String id,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/policies/$id');
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return policyDetailResponseFromJson(response.body);
      }
      throw Exception(_extractError(response, 'Failed to fetch policy'));
    } catch (e) {
      print('PolicyService.getPolicyById error: $e');
      rethrow;
    }
  }

  // ── Download URL ──────────────────────────────────────────────────────────

  /// Returns the download URL for a policy file: GET /api/policies/:id/download
  static String getDownloadUrl(String id) => '$_baseUrl/policies/$id/download';

  // ── Create Policy (admin only) ─────────────────────────────────────────

  /// POST /api/policies  (multipart/form-data)
  /// [file] is optional — PDF, DOCX, etc.
  static Future<void> createPolicy({
    required String token,
    required String title,
    String description = '',
    String location = 'Head Office',
    File? file,
    String? fileName,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/policies');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['title'] = title
        ..fields['description'] = description
        ..fields['location'] = location;

      if (file != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            filename: fileName ?? file.path.split('/').last.split('\\').last,
          ),
        );
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 201) return;
      throw Exception(_extractError(response, 'Failed to create policy'));
    } catch (e) {
      print('PolicyService.createPolicy error: $e');
      rethrow;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  // ── Delete Policy (admin only) ─────────────────────────────────────────

  /// DELETE /api/policies/:id
  static Future<void> deletePolicy({
    required String token,
    required String id,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/policies/$id');
      final response = await http
          .delete(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) return;
      throw Exception(_extractError(response, 'Failed to delete policy'));
    } catch (e) {
      print('PolicyService.deletePolicy error: $e');
      rethrow;
    }
  }

  static String _extractError(http.Response response, String fallback) {
    try {
      final body = json.decode(response.body);
      return body['message'] ?? fallback;
    } catch (_) {
      return '$fallback (${response.statusCode})';
    }
  }
}
