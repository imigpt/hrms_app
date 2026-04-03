import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hrms_app/core/config/api_config.dart';
import 'package:hrms_app/features/admin/data/models/company_model.dart';

class CompanyService {
  final String? token;

  CompanyService({this.token});

  static String get _baseUrl => ApiConfig.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  /// GET /api/companies - Get all companies with optional filters
  Future<List<Company>> getCompanies({String? status, String? search}) async {
    try {
      final params = <String, String>{};
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final uri = Uri.parse('$_baseUrl/companies')
          .replace(queryParameters: params.isNotEmpty ? params : null);

      print('🏢 [COMPANIES] Fetching: $uri');

      final response = await http
          .get(
            uri,
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      print('🏢 [COMPANIES] Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final companies = body['data'] ?? body['companies'] ?? [];
        if (companies is List) {
          final result = companies
              .map((json) => Company.fromJson(json as Map<String, dynamic>))
              .toList();
          print('🏢 [COMPANIES] Found ${result.length} companies');
          return result;
        }
      }
      return [];
    } catch (e) {
      print('❌ [COMPANIES] Error: $e');
      throw Exception('Error fetching companies: $e');
    }
  }

  /// GET /api/companies/:id - Get company details
  Future<Company> getCompanyDetail(String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/companies/$id');
      print('🏢 [COMPANY DETAIL] Fetching: $uri');

      final response = await http
          .get(
            uri,
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      print('🏢 [COMPANY DETAIL] Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final company = body['data'] ?? body;
        return Company.fromJson(company);
      }
      throw Exception('Failed to fetch company details');
    } catch (e) {
      print('❌ [COMPANY DETAIL] Error: $e');
      throw Exception('Error fetching company details: $e');
    }
  }

  /// POST /api/companies - Create company
  Future<Company> createCompany({
    required String name,
    String? email,
    String? phone,
    String? address,
    String? website,
    String? industry,
    String? size,
    int? companySize,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        if (website != null && website.isNotEmpty) 'website': website,
        if (industry != null && industry.isNotEmpty) 'industry': industry,
        if (size != null && size.isNotEmpty) 'size': size,
        if (companySize != null) 'companySize': companySize,
      };

      final uri = Uri.parse('$_baseUrl/companies');
      print('🏢 [CREATE] Posting to: $uri');
      print('🏢 [CREATE] Body: ${jsonEncode(body)}');

      final response = await http
          .post(
            uri,
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      print('🏢 [CREATE] Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respBody = jsonDecode(response.body) as Map<String, dynamic>;
        final company = respBody['data'] ?? respBody;
        return Company.fromJson(company);
      }
      throw Exception('Failed to create company: ${response.body}');
    } catch (e) {
      print('❌ [CREATE] Error: $e');
      throw Exception('Error creating company: $e');
    }
  }

  /// PUT /api/companies/:id - Update company
  Future<Company> updateCompany({
    required String id,
    required String name,
    String? email,
    String? phone,
    String? address,
    String? website,
    String? industry,
    String? size,
    int? companySize,
    String? status,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        if (website != null && website.isNotEmpty) 'website': website,
        if (industry != null && industry.isNotEmpty) 'industry': industry,
        if (size != null && size.isNotEmpty) 'size': size,
        if (companySize != null) 'companySize': companySize,
        if (status != null && status.isNotEmpty) 'status': status,
      };

      final uri = Uri.parse('$_baseUrl/companies/$id');
      print('🏢 [UPDATE] Putting to: $uri');

      final response = await http
          .put(
            uri,
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      print('🏢 [UPDATE] Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respBody = jsonDecode(response.body) as Map<String, dynamic>;
        final company = respBody['data'] ?? respBody;
        return Company.fromJson(company);
      }
      throw Exception('Failed to update company: ${response.body}');
    } catch (e) {
      print('❌ [UPDATE] Error: $e');
      throw Exception('Error updating company: $e');
    }
  }

  /// DELETE /api/companies/:id - Delete company
  Future<void> deleteCompany(String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/companies/$id');
      print('🏢 [DELETE] Deleting: $uri');

      final response = await http
          .delete(
            uri,
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      print('🏢 [DELETE] Status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to delete company: ${response.body}');
      }
    } catch (e) {
      print('❌ [DELETE] Error: $e');
      throw Exception('Error deleting company: $e');
    }
  }

  /// PUT /api/companies/:id/status - Update company status
  Future<Company> updateCompanyStatus(String id, String status) async {
    try {
      final uri = Uri.parse('$_baseUrl/companies/$id/status');
      final body = {'status': status};
      print('🏢 [STATUS] Updating to: $status');

      final response = await http
          .put(
            uri,
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      print('🏢 [STATUS] Status code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respBody = jsonDecode(response.body) as Map<String, dynamic>;
        final company = respBody['data'] ?? respBody;
        return Company.fromJson(company);
      }
      throw Exception('Failed to update company status');
    } catch (e) {
      print('❌ [STATUS] Error: $e');
      throw Exception('Error updating company status: $e');
    }
  }

  /// GET /api/companies/:id/stats - Get company statistics
  Future<Map<String, dynamic>> getCompanyStats(String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/companies/$id/stats');
      print('🏢 [STATS] Fetching: $uri');

      final response = await http
          .get(
            uri,
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      print('🏢 [STATS] Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respBody = jsonDecode(response.body) as Map<String, dynamic>;
        return respBody['data'] ?? respBody;
      }
      throw Exception('Failed to fetch company stats');
    } catch (e) {
      print('❌ [STATS] Error: $e');
      throw Exception('Error fetching company stats: $e');
    }
  }

  /// GET /api/companies/:id/overview - Get company overview details
  Future<Map<String, dynamic>> getCompanyOverview(String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/companies/$id/overview');
      print('🏢 [OVERVIEW] Fetching: $uri');

      final response = await http
          .get(
            uri,
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      print('🏢 [OVERVIEW] Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respBody = jsonDecode(response.body) as Map<String, dynamic>;
        return respBody['data'] ?? respBody;
      }
      throw Exception('Failed to fetch company overview');
    } catch (e) {
      print('❌ [OVERVIEW] Error: $e');
      throw Exception('Error fetching company overview: $e');
    }
  }

}
