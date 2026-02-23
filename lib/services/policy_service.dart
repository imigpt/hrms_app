import 'dart:convert';
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

      final uri = Uri.parse('$_baseUrl/policies').replace(queryParameters: queryParams);
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _extractError(http.Response response, String fallback) {
    try {
      final body = json.decode(response.body);
      return body['message'] ?? fallback;
    } catch (_) {
      return '$fallback (${response.statusCode})';
    }
  }
}
