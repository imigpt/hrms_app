import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AdminClientsService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// GET /api/clients
  /// Optional filter: status (active|inactive)
  static Future<Map<String, dynamic>> getAllClients(
    String token, {
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final uri = Uri.parse(
        '$_baseUrl/clients',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else {
        final body = jsonDecode(response.body);
        throw Exception(
          body['message'] ?? 'Failed to fetch clients (${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error fetching clients: $e');
    }
  }

  /// POST /api/clients
  /// Create a new client
  static Future<Map<String, dynamic>> addClient({
    required String token,
    required String name,
    required String email,
    String? phone,
    String? companyName,
    String? password,
    String? assignedCompanyId,
    String? clientNotes,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (companyName != null && companyName.isNotEmpty)
          'companyName': companyName,
        if (password != null && password.isNotEmpty) 'password': password,
        if (assignedCompanyId != null && assignedCompanyId.isNotEmpty)
          'assignedCompanyId': assignedCompanyId,
        if (clientNotes != null && clientNotes.isNotEmpty)
          'clientNotes': clientNotes,
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/clients'),
            headers: _headers(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Invalid client data');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else {
        final body = jsonDecode(response.body);
        throw Exception(
          body['message'] ?? 'Failed to add client (${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error adding client: $e');
    }
  }

  /// PUT /api/clients/:id
  /// Update a client
  static Future<Map<String, dynamic>> updateClient({
    required String token,
    required String clientId,
    String? name,
    String? email,
    String? phone,
    String? companyName,
    String? password,
    String? assignedCompanyId,
    String? clientNotes,
  }) async {
    try {
      final body = <String, dynamic>{
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (companyName != null && companyName.isNotEmpty)
          'companyName': companyName,
        if (password != null && password.isNotEmpty) 'password': password,
        if (assignedCompanyId != null && assignedCompanyId.isNotEmpty)
          'assignedCompanyId': assignedCompanyId,
        if (clientNotes != null && clientNotes.isNotEmpty)
          'clientNotes': clientNotes,
      };

      final response = await http
          .put(
            Uri.parse('$_baseUrl/clients/$clientId'),
            headers: _headers(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        throw Exception('Client not found');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else {
        final body = jsonDecode(response.body);
        throw Exception(
          body['message'] ?? 'Failed to update client (${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error updating client: $e');
    }
  }

  /// DELETE /api/clients/:id
  /// Delete a client
  static Future<Map<String, dynamic>> deleteClient({
    required String token,
    required String clientId,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/clients/$clientId'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Client deleted successfully'};
      } else if (response.statusCode == 404) {
        throw Exception('Client not found');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else {
        final body = jsonDecode(response.body);
        throw Exception(
          body['message'] ?? 'Failed to delete client (${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error deleting client: $e');
    }
  }

  /// GET /api/admin/companies
  /// Fetch all HRMS companies (admin only)
  static Future<List<Map<String, dynamic>>> getCompanies(String token) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/admin/companies'), headers: _headers(token))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'];
        if (data is List) {
          return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        return []; // non-fatal
      }
    } catch (_) {
      return [];
    }
  }
}
